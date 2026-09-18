import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/table_info.dart';
import '../providers/cart_provider.dart';
import '../providers/orders_provider.dart';
import '../providers/tables_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/locale_provider.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import '../services/whatsapp_service.dart';
import '../services/wifi_printer_service.dart';

class CartPanel extends StatefulWidget {
  final bool isBottomSheet;

  const CartPanel({super.key, this.isBottomSheet = false});

  @override
  State<CartPanel> createState() => _CartPanelState();
}

class _CartPanelState extends State<CartPanel> {
  final TextEditingController _notesController = TextEditingController();
  bool _isSubmitting = false;
  bool _isPrinting = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handlePrintCartBill(BuildContext context) async {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final settings = Provider.of<SettingsProvider>(context, listen: false);

    if (cart.selectedTable == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء اختيار طاولة أولاً قبل الطباعة'),
          backgroundColor: AppTheme.statusOrange,
        ),
      );
      return;
    }

    if (cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('السلة فارغة. يرجى إضافة أصناف للطباعة'),
          backgroundColor: AppTheme.statusOrange,
        ),
      );
      return;
    }

    setState(() => _isPrinting = true);
    final result = await WifiPrinterService.printTableBill(
      ip: settings.printerIp,
      port: settings.printerPort,
      cafeName: settings.cafeName,
      tableName: cart.selectedTable!.nameAr,
      tableNumber: cart.selectedTable!.number,
      items: cart.items,
      totalAmount: cart.totalAmount,
      waiterName: settings.waiterName,
      generalNotes: _notesController.text.trim(),
    );
    setState(() => _isPrinting = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: result.success ? AppTheme.statusGreen : AppTheme.statusRed,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _handleSendOrder(BuildContext context) async {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final ordersProvider = Provider.of<OrdersProvider>(context, listen: false);
    final tablesProvider = Provider.of<TablesProvider>(context, listen: false);
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final locale = Provider.of<LocaleProvider>(context, listen: false);
    final lang = locale.langCode;

    // Auto-select first table if none selected
    if (cart.selectedTable == null && tablesProvider.tables.isNotEmpty) {
      cart.selectTable(tablesProvider.tables.first);
    }

    if (cart.selectedTable == null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('⚠️ اختر الطاولة'),
          content: const Text('الرجاء اختيار رقم الطاولة أولاً من القائمة بالأعلى.'),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('حسناً'),
            ),
          ],
        ),
      );
      return;
    }

    if (cart.isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('⚠️ سلة الطلب فارغة'),
          content: const Text('الرجاء إضافة صنف واحد على الأقل من المنيو (بالضغط على + عند أي مشروب أو حلى) لتتمكن من إرسال الطلب للكاشير.'),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('حسناً'),
            ),
          ],
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final generalNotes = _notesController.text.trim();

      // Check and execute create OR merge
      final result = await ordersProvider.createOrMergeOrder(
        table: cart.selectedTable!,
        items: List.from(cart.items),
        generalNotes: generalNotes,
        waiterName: settings.waiterName,
      );

      final order = result.order;
      final isMerged = result.isMerged;

      // Refresh tables to reflect occupancy
      await tablesProvider.loadTables();

      // Launch WhatsApp with merge/addition flags
      await WhatsAppService.sendOrderToCashier(
        cashierPhone: settings.cashierPhone,
        order: order,
        lang: lang,
        isAddition: isMerged,
        addedItemsOnly: isMerged ? result.addedItems : null,
        previousTotal: isMerged ? result.previousTotal : null,
      );

      // Auto-print bill via Wi-Fi if enabled in settings
      if (settings.autoPrintBill) {
        WifiPrinterService.printTableBill(
          ip: settings.printerIp,
          port: settings.printerPort,
          cafeName: settings.cafeName,
          tableName: order.tableName,
          tableNumber: order.tableNumber,
          items: order.items,
          totalAmount: order.totalAmount,
          orderId: order.id,
          waiterName: settings.waiterName,
          generalNotes: generalNotes,
          isAddition: isMerged,
        );
      }

      // Clear cart
      cart.clearCart();
      _notesController.clear();

      if (mounted) {
        if (widget.isBottomSheet) {
          Navigator.pop(context);
        }

        // Show Success & Instant Direct WhatsApp Launcher Dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Icon(
                  isMerged ? Icons.add_circle : Icons.check_circle,
                  color: isMerged ? AppTheme.primaryAmber : const Color(0xFF25D366),
                  size: 28,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isMerged ? 'تم دمج الطلب مع الفاتورة الحالية!' : 'تم تسجيل الطلب بنجاح!',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.cardLatte,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${order.tableName} (#${order.tableNumber})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.primaryCoffee),
                  ),
                ),
                const SizedBox(height: 10),
                if (isMerged) ...[
                  Text(
                    'المجموع التراكمي الجديد للطاولة: ${order.totalAmount.toStringAsFixed(2)} د.أ',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: AppTheme.primaryCoffee),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'تم دمج الأصناف الجديدة مع الطلب الأصلي تلقائياً وإشعار الكاشير.',
                    style: TextStyle(fontSize: 12.5, color: AppTheme.textMuted),
                  ),
                ] else ...[
                  Text(
                    'المجموع: ${order.totalAmount.toStringAsFixed(2)} د.أ',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.primaryCoffee),
                  ),
                ],
                const SizedBox(height: 14),
                const Text(
                  'إذا لم يفتح الواتساب تلقائياً، اضغط الزر الأخضر بالأسفل مباشرة:',
                  style: TextStyle(fontSize: 12.5, color: AppTheme.textDark),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      WhatsAppService.sendOrderToCashier(
                        cashierPhone: settings.cashierPhone,
                        order: order,
                        lang: lang,
                        isAddition: isMerged,
                        addedItemsOnly: isMerged ? result.addedItems : null,
                        previousTotal: isMerged ? result.previousTotal : null,
                      );
                    },
                    icon: const Icon(Icons.open_in_new, color: Colors.white, size: 20),
                    label: Text(
                      isMerged ? 'إرسال الإضافة للواتساب 💬' : 'فتح الواتساب الآن 💬',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                      elevation: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final printRes = await WifiPrinterService.printTableBill(
                        ip: settings.printerIp,
                        port: settings.printerPort,
                        cafeName: settings.cafeName,
                        tableName: order.tableName,
                        tableNumber: order.tableNumber,
                        items: order.items,
                        totalAmount: order.totalAmount,
                        orderId: order.id,
                        waiterName: settings.waiterName,
                        generalNotes: generalNotes,
                        isAddition: isMerged,
                      );
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(
                            content: Text(printRes.message),
                            backgroundColor: printRes.success ? AppTheme.statusGreen : AppTheme.statusRed,
                            duration: const Duration(seconds: 4),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.print_rounded, color: AppTheme.primaryCoffee, size: 20),
                    label: const Text(
                      'طباعة الفاتورة (Wi-Fi) 🖨️',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryCoffee),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.primaryCoffee, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إغلاق / تم'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء إرسال الطلب: $e'),
            backgroundColor: AppTheme.statusRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LocaleProvider>(context).langCode;
    final isAr = lang == 'ar';
    final cart = Provider.of<CartProvider>(context);
    final tablesProvider = Provider.of<TablesProvider>(context);
    final currency = AppStrings.get('currency', lang);

    if (cart.selectedTable == null && tablesProvider.tables.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (cart.selectedTable == null && tablesProvider.tables.isNotEmpty) {
          cart.selectTable(tablesProvider.tables.first);
        }
      });
    }

    final isTableOccupied = cart.selectedTable?.isOccupied ?? false;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceWarm,
        border: widget.isBottomSheet
            ? null
            : Border(
                left: isAr ? const BorderSide(color: AppTheme.borderSubtle, width: 1) : BorderSide.none,
                right: !isAr ? const BorderSide(color: AppTheme.borderSubtle, width: 1) : BorderSide.none,
              ),
      ),
      child: Column(
        children: [
          // Header & Table Selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.cardLatte,
              border: const Border(bottom: BorderSide(color: AppTheme.borderSubtle)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.receipt_long_rounded, color: AppTheme.primaryCoffee, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          AppStrings.get('cart', lang),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                        if (cart.totalItemCount > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryAmber,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${cart.totalItemCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (!cart.isEmpty)
                      TextButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text(AppStrings.get('clear_cart', lang)),
                              content: Text(AppStrings.get('clear_cart_confirm', lang)),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: Text(AppStrings.get('cancel', lang)),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    cart.clearCart();
                                    Navigator.pop(ctx);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.statusRed,
                                  ),
                                  child: Text(AppStrings.get('delete', lang)),
                                ),
                              ],
                            ),
                          );
                        },
                        icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.statusRed),
                        label: Text(
                          AppStrings.get('clear_cart', lang),
                          style: const TextStyle(color: AppTheme.statusRed, fontSize: 12),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                // Table Dropdown / Selector
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isTableOccupied ? AppTheme.statusOrange : AppTheme.borderSubtle,
                      width: isTableOccupied ? 1.5 : 1,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<TableInfo>(
                      value: cart.selectedTable,
                      hint: Row(
                        children: [
                          const Icon(Icons.table_restaurant_outlined, color: AppTheme.primaryAmber, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            AppStrings.get('select_table', lang),
                            style: const TextStyle(fontSize: 14, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down, color: AppTheme.primaryCoffee),
                      items: tablesProvider.tables.map((table) {
                        return DropdownMenuItem<TableInfo>(
                          value: table,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${table.getName(lang)} (#${table.number})',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textDark,
                                  fontSize: 14,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: table.isOccupied
                                      ? AppTheme.statusOrange.withValues(alpha: 0.15)
                                      : AppTheme.statusGreen.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  table.isOccupied
                                      ? AppStrings.get('occupied', lang)
                                      : AppStrings.get('available', lang),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: table.isOccupied ? AppTheme.statusOrange : AppTheme.statusGreen,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (newTable) {
                        cart.selectTable(newTable);
                      },
                    ),
                  ),
                ),

                // Occupied Notice Banner
                if (isTableOccupied) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.statusOrange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.statusOrange.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.merge_type_rounded, size: 16, color: AppTheme.statusOrange),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            AppStrings.get('table_has_active_order', lang),
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.statusOrange,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Items List
          Expanded(
            child: cart.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_basket_outlined,
                          size: 64,
                          color: AppTheme.textMuted.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          AppStrings.get('empty_cart', lang),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            AppStrings.get('empty_cart_desc', lang),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12.5, color: AppTheme.textMuted),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: cart.items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.borderSubtle),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Item details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.getName(lang),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14.5,
                                          color: AppTheme.textDark,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          if (item.size != 'Standard') ...[
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                              decoration: BoxDecoration(
                                                color: AppTheme.primaryAmber.withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                item.size,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppTheme.primaryAmber,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                          ],
                                          Text(
                                            '${item.unitPrice.toStringAsFixed(2)} $currency',
                                            style: const TextStyle(
                                              fontSize: 12.5,
                                              color: AppTheme.textMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                // Total price
                                Text(
                                  '${item.totalPrice.toStringAsFixed(2)} $currency',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14.5,
                                    color: AppTheme.primaryCoffee,
                                  ),
                                ),
                              ],
                            ),

                            // Notes display
                            if (item.notes.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppTheme.cardLatte,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.notes, size: 12, color: AppTheme.primaryAmber),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        item.notes,
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          fontStyle: FontStyle.italic,
                                          color: AppTheme.textMuted,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(height: 8),

                            // Quantity controls & Remove
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    InkWell(
                                      onTap: () => cart.decrementQuantity(index),
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: AppTheme.cardLatte,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: AppTheme.borderSubtle),
                                        ),
                                        child: const Icon(Icons.remove, size: 16, color: AppTheme.primaryCoffee),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 10),
                                      child: Text(
                                        '${item.quantity}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textDark,
                                        ),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () => cart.incrementQuantity(index),
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: AppTheme.cardLatte,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: AppTheme.borderSubtle),
                                        ),
                                        child: const Icon(Icons.add, size: 16, color: AppTheme.primaryCoffee),
                                      ),
                                    ),
                                  ],
                                ),
                                InkWell(
                                  onTap: () => cart.removeItem(index),
                                  borderRadius: BorderRadius.circular(8),
                                  child: const Padding(
                                    padding: EdgeInsets.all(6),
                                    child: Icon(Icons.delete_outline, size: 18, color: AppTheme.statusRed),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // Footer: General Notes + Total + WhatsApp Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Column(
              children: [
                // General Notes Field
                TextField(
                  controller: _notesController,
                  decoration: InputDecoration(
                    hintText: AppStrings.get('general_notes_hint', lang),
                    prefixIcon: const Icon(Icons.message_outlined, color: AppTheme.primaryAmber, size: 18),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 12),

                // Total Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppStrings.get('total', lang),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    Text(
                      '${cart.totalAmount.toStringAsFixed(2)} $currency',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryCoffee,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Send / Merge Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : () => _handleSendOrder(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isTableOccupied ? AppTheme.primaryCoffee : const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isTableOccupied ? Icons.merge_type_rounded : Icons.send_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isTableOccupied
                                    ? (isAr ? 'دمج وإرسال للكاشير (واتساب)' : 'Merge & Send (WhatsApp)')
                                    : AppStrings.get('send_to_cashier', lang),
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 10),

                // Wi-Fi Print Bill Button
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: OutlinedButton.icon(
                    onPressed: _isPrinting ? null : () => _handlePrintCartBill(context),
                    icon: _isPrinting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryCoffee),
                          )
                        : const Icon(Icons.print_outlined, color: AppTheme.primaryCoffee, size: 20),
                    label: Text(
                      _isPrinting ? 'جاري إرسال الفاتورة...' : 'طباعة الفاتورة (Wi-Fi) 🖨️',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryCoffee),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.primaryCoffee, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
