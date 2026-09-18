import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/table_info.dart';
import '../models/order.dart';
import '../providers/tables_provider.dart';
import '../providers/orders_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/locale_provider.dart';
import '../services/wifi_printer_service.dart';
import '../services/whatsapp_service.dart';
import '../theme/app_theme.dart';
import '../l10n/app_strings.dart';

class TablesStatusTab extends StatefulWidget {
  final Function(int)? onSwitchToMenu;

  const TablesStatusTab({super.key, this.onSwitchToMenu});

  @override
  State<TablesStatusTab> createState() => _TablesStatusTabState();
}

class _TablesStatusTabState extends State<TablesStatusTab> {
  String _selectedSection = 'all';

  Order? _findActiveOrderForTable(List<Order> orders, int tableNumber) {
    try {
      return orders.firstWhere(
        (o) => o.tableNumber == tableNumber && ['new', 'preparing', 'served'].contains(o.status),
      );
    } catch (_) {
      return null;
    }
  }

  void _showTableOrderDetailsDialog(
    BuildContext context, {
    required TableInfo table,
    required Order activeOrder,
  }) {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final lang = Provider.of<LocaleProvider>(context, listen: false).langCode;
    final isAr = lang == 'ar';
    final currency = AppStrings.get('currency', lang);

    showDialog(
      context: context,
      builder: (ctx) {
        bool isPrinting = false;

        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
              contentPadding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryAmber.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.table_restaurant_rounded, color: AppTheme.primaryCoffee, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${table.getName(lang)} (#${table.number})',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryAmber,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isAr ? 'طاولة مشغولة (طلب نشط)' : 'Occupied Table',
                                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${activeOrder.orderNumber}',
                              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppTheme.textMuted),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Order meta info box
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.cardLatte,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${isAr ? 'الويتر' : 'Waiter'}: ${activeOrder.waiterName.isNotEmpty ? activeOrder.waiterName : settings.waiterName}',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryCoffee),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${isAr ? 'وقت البدء' : 'Started'}: ${DateFormat('HH:mm  dd/MM').format(activeOrder.createdAt)}',
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${activeOrder.items.length} ${isAr ? 'أصناف مختلفة' : 'items'}',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                                ),
                                Text(
                                  '${activeOrder.items.fold(0, (s, i) => s + i.quantity)} ${isAr ? 'حبة بالإجمالي' : 'total pcs'}',
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      Text(
                        isAr ? 'قائمة الأصناف المدمجة للطاولة:' : 'Merged Table Items:',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textDark),
                      ),
                      const SizedBox(height: 8),

                      // Items List
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.borderSubtle),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: activeOrder.items.length,
                          separatorBuilder: (_, __) => const Divider(height: 1, color: AppTheme.borderSubtle),
                          itemBuilder: (context, idx) {
                            final item = activeOrder.items[idx];
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryCoffee.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${item.quantity}x',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryCoffee),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${item.getName(lang)} ${item.size != 'Standard' && item.size.isNotEmpty ? '(${item.size})' : ''}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                                        ),
                                        if (item.notes.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 2),
                                            child: Text(
                                              item.notes,
                                              style: const TextStyle(fontSize: 12, color: AppTheme.primaryAmber, fontWeight: FontWeight.w600),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '${item.totalPrice.toStringAsFixed(2)} $currency',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryCoffee),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),

                      if (activeOrder.generalNotes.isNotEmpty) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber.shade200),
                          ),
                          child: Text(
                            '${isAr ? 'ملاحظة عامة' : 'Note'}: ${activeOrder.generalNotes}',
                            style: TextStyle(fontSize: 12.5, color: Colors.brown.shade900),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Grand Cumulative Total
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryCoffee,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isAr ? 'المجموع التراكمي النهائي:' : 'Cumulative Grand Total:',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            Text(
                              '${activeOrder.totalAmount.toStringAsFixed(2)} $currency',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.accentCaramel),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Action Button 1: Print Merged Bill via Wi-Fi
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: isPrinting
                              ? null
                              : () async {
                                  setDialogState(() => isPrinting = true);
                                  final result = await WifiPrinterService.printTableBill(
                                    ip: settings.printerIp,
                                    port: settings.printerPort,
                                    cafeName: settings.cafeName,
                                    tableName: table.nameAr,
                                    tableNumber: table.number,
                                    items: activeOrder.items,
                                    totalAmount: activeOrder.totalAmount,
                                    orderId: activeOrder.id,
                                    waiterName: activeOrder.waiterName.isNotEmpty ? activeOrder.waiterName : settings.waiterName,
                                    generalNotes: activeOrder.generalNotes,
                                    isAddition: false,
                                  );
                                  setDialogState(() => isPrinting = false);

                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(result.message),
                                        backgroundColor: result.success ? AppTheme.statusGreen : AppTheme.statusRed,
                                        duration: const Duration(seconds: 4),
                                      ),
                                    );
                                  }
                                },
                          icon: isPrinting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                )
                              : const Icon(Icons.print_rounded, color: Colors.white, size: 22),
                          label: Text(
                            isPrinting
                                ? (isAr ? 'جاري إرسال الفاتورة للطابعة...' : 'Printing...')
                                : (isAr ? 'طباعة الفاتورة المدمجة (Wi-Fi) 🖨️' : 'Print Merged Bill (Wi-Fi) 🖨️'),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryAmber,
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Action Button 2: WhatsApp to Cashier
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            WhatsAppService.sendFinalBillToCashier(
                              cashierPhone: settings.cashierPhone,
                              order: activeOrder,
                              lang: lang,
                            );
                          },
                          icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFF25D366), size: 20),
                          label: Text(
                            isAr ? 'إرسال الفاتورة للكاشير (واتساب) 💬' : 'Send Bill to Cashier (WhatsApp) 💬',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF25D366)),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF25D366), width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Secondary Row: Add items to table OR Check out
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                final cart = Provider.of<CartProvider>(context, listen: false);
                                cart.selectTable(table);
                                Navigator.pop(ctx);
                                if (widget.onSwitchToMenu != null) {
                                  widget.onSwitchToMenu!(0);
                                }
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(isAr ? 'تم تحديد ${table.nameAr} - يمكنك إضافة أصناف الآن' : 'Table selected for adding items'),
                                    backgroundColor: AppTheme.primaryCoffee,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.add_shopping_cart, size: 18, color: AppTheme.primaryCoffee),
                              label: Text(
                                isAr ? '+ إضافة طلب جديد' : '+ Add items',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryCoffee),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppTheme.primaryCoffee),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final ordersProvider = Provider.of<OrdersProvider>(context, listen: false);
                                final tablesProvider = Provider.of<TablesProvider>(context, listen: false);
                                await ordersProvider.updateStatus(activeOrder.id!, 'completed');
                                await tablesProvider.loadTables();
                                if (ctx.mounted) Navigator.pop(ctx);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(isAr ? 'تم إغلاق ومحاسبة ${table.nameAr} وإخلاء الطاولة بنجاح ✓' : 'Table closed & completed'),
                                      backgroundColor: AppTheme.statusGreen,
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.check_circle_outline, size: 18, color: Colors.white),
                              label: Text(
                                isAr ? 'محاسبة وإخلاء' : 'Close Table',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryCoffee,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tablesProvider = Provider.of<TablesProvider>(context);
    final ordersProvider = Provider.of<OrdersProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context);
    final lang = Provider.of<LocaleProvider>(context).langCode;
    final isAr = lang == 'ar';
    final currency = AppStrings.get('currency', lang);

    final tables = tablesProvider.tables;
    final activeOrders = ordersProvider.orders.where((o) => ['new', 'preparing', 'served'].contains(o.status)).toList();

    final busyCount = tables.where((t) => _findActiveOrderForTable(activeOrders, t.number) != null).length;
    final availableCount = tables.length - busyCount;

    final filteredTables = tables.where((t) {
      if (_selectedSection == 'all') return true;
      return t.section == _selectedSection;
    }).toList();

    return Column(
      children: [
        // Summary & Metrics Header
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          color: Colors.white,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.cardLatte,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.borderSubtle),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.table_restaurant, color: AppTheme.primaryCoffee, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            '${tables.length} ${isAr ? 'طاولات' : 'Tables'}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryCoffee),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            '$availableCount ${isAr ? 'فاضية' : 'Free'}',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.green.shade800),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.people_alt, color: Colors.amber.shade800, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            '$busyCount ${isAr ? 'مشغولة' : 'Busy'}',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.amber.shade900),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Section Filter Chips
              SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _sectionChip('all', isAr ? 'الكل' : 'All', Icons.apps),
                    _sectionChip('indoor', AppStrings.get('section_indoor', lang), Icons.roofing),
                    _sectionChip('terrace', AppStrings.get('section_terrace', lang), Icons.deck),
                    _sectionChip('bar', AppStrings.get('section_bar', lang), Icons.local_bar),
                    _sectionChip('vip', AppStrings.get('section_vip', lang), Icons.star),
                  ],
                ),
              ),
            ],
          ),
        ),

        const Divider(height: 1, color: AppTheme.borderSubtle),

        // Tables Grid
        Expanded(
          child: tablesProvider.isLoading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryAmber))
              : filteredTables.isEmpty
                  ? Center(
                      child: Text(
                        isAr ? 'لا توجد طاولات في هذا القسم' : 'No tables in this section',
                        style: const TextStyle(fontSize: 16, color: AppTheme.textMuted),
                      ),
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final isTablet = constraints.maxWidth >= 600;
                        return GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: isTablet ? 240 : 200,
                            mainAxisSpacing: 14,
                            crossAxisSpacing: 14,
                            childAspectRatio: 0.92,
                          ),
                          itemCount: filteredTables.length,
                          itemBuilder: (context, index) {
                            final table = filteredTables[index];
                            final activeOrder = _findActiveOrderForTable(activeOrders, table.number);
                            final isOccupied = activeOrder != null;
                            final isSelectedInCart = cartProvider.selectedTable?.number == table.number;

                            return Card(
                              elevation: isOccupied ? 3 : 1.5,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: isOccupied
                                      ? AppTheme.primaryAmber
                                      : (isSelectedInCart ? AppTheme.primaryCoffee : AppTheme.borderSubtle),
                                  width: (isOccupied || isSelectedInCart) ? 2 : 1,
                                ),
                              ),
                              child: InkWell(
                                onTap: () {
                                  if (isOccupied) {
                                    // Clicking a busy table opens order details & print merged bill dialog!
                                    _showTableOrderDetailsDialog(
                                      context,
                                      table: table,
                                      activeOrder: activeOrder,
                                    );
                                  } else {
                                    // Clicking an empty table selects it for taking orders
                                    cartProvider.selectTable(table);
                                    if (widget.onSwitchToMenu != null) {
                                      widget.onSwitchToMenu!(0);
                                    }
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          isAr
                                              ? 'تم اختيار ${table.nameAr} - يمكنك الآن إضافة الأصناف المطلوبة'
                                              : 'Selected ${table.nameEn} for ordering',
                                        ),
                                        backgroundColor: AppTheme.primaryCoffee,
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Top Row: Table Number + Status Badge
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            width: 36,
                                            height: 36,
                                            decoration: BoxDecoration(
                                              color: isOccupied
                                                  ? AppTheme.primaryAmber.withOpacity(0.18)
                                                  : Colors.green.shade50,
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Icon(
                                              Icons.table_restaurant,
                                              color: isOccupied ? AppTheme.primaryCoffee : Colors.green.shade700,
                                              size: 20,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: isOccupied ? AppTheme.primaryAmber : Colors.green.shade600,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              isOccupied ? (isAr ? 'مشغولة' : 'Busy') : (isAr ? 'فاضية' : 'Free'),
                                              style: const TextStyle(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),

                                      // Center: Table Name & Section
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            table.getName(lang),
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.textDark,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            AppStrings.get('section_${table.section}', lang),
                                            style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                          ),
                                        ],
                                      ),

                                      // Bottom: Active Order details (or Free state)
                                      if (isOccupied) ...[
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: AppTheme.cardLatte,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: AppTheme.primaryAmber.withOpacity(0.4)),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  const Icon(Icons.receipt, size: 14, color: AppTheme.primaryCoffee),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '${activeOrder.items.length} ${isAr ? 'أصناف' : 'items'}',
                                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryCoffee),
                                                  ),
                                                ],
                                              ),
                                              Text(
                                                '${activeOrder.totalAmount.toStringAsFixed(2)} $currency',
                                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryCoffee),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              isAr ? 'اضغط لعرض الفاتورة والطباعة 🖨️' : 'Tap to view bill & print',
                                              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppTheme.primaryAmber),
                                            ),
                                          ],
                                        ),
                                      ] else ...[
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              isAr ? 'متاحة للطلب' : 'Available',
                                              style: TextStyle(fontSize: 12, color: Colors.green.shade700, fontWeight: FontWeight.w600),
                                            ),
                                            const Icon(Icons.arrow_forward_rounded, size: 16, color: AppTheme.primaryCoffee),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _sectionChip(String section, String label, IconData icon) {
    final isSelected = _selectedSection == section;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        avatar: Icon(icon, size: 16, color: isSelected ? Colors.white : AppTheme.primaryCoffee),
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => setState(() => _selectedSection = section),
        selectedColor: AppTheme.primaryCoffee,
        backgroundColor: AppTheme.cardLatte,
        labelStyle: TextStyle(
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          color: isSelected ? Colors.white : AppTheme.textDark,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        side: BorderSide(color: isSelected ? AppTheme.primaryCoffee : AppTheme.borderSubtle),
      ),
    );
  }
}
