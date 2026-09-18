import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/order.dart';
import '../providers/orders_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/locale_provider.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import '../services/whatsapp_service.dart';
import '../services/wifi_printer_service.dart';

class OrderTrackerScreen extends StatelessWidget {
  final bool isEmbedded;
  const OrderTrackerScreen({super.key, this.isEmbedded = false});

  Color _getStatusColor(String status) {
    switch (status) {
      case 'new':
        return AppTheme.statusOrange;
      case 'preparing':
        return AppTheme.statusBlue;
      case 'served':
        return AppTheme.statusGreen;
      case 'completed':
        return Colors.grey.shade600;
      case 'cancelled':
        return AppTheme.statusRed;
      default:
        return AppTheme.primaryCoffee;
    }
  }

  String _getStatusLabel(String status, String lang) {
    switch (status) {
      case 'new':
        return AppStrings.get('status_new', lang);
      case 'preparing':
        return AppStrings.get('status_preparing', lang);
      case 'served':
        return AppStrings.get('status_served', lang);
      case 'completed':
        return AppStrings.get('status_completed', lang);
      case 'cancelled':
        return AppStrings.get('status_cancelled', lang);
      default:
        return status;
    }
  }

  void _showFinalBillDialog(BuildContext context, Order order, String cashierPhone, String lang) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.receipt_long, color: AppTheme.primaryAmber, size: 28),
            SizedBox(width: 8),
            Text('الفاتورة النهائية للمحاسبة'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.cardLatte,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${order.tableName} (#${order.tableNumber})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryCoffee),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'المجموع النهائي المطلوب: ${order.totalAmount.toStringAsFixed(2)} د.أ',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.statusGreen),
                  ),
                  const SizedBox(height: 4),
                  Text('إجمالي عدد المواد: ${order.items.fold(0, (sum, i) => sum + i.quantity)} صنف'),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'تم إرسال الفاتورة النهائية للكاشير عبر الواتساب. هل ترغب أيضاً بإغلاق الطاولة واعتبارها مدفوعة؟',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  WhatsAppService.sendFinalBillToCashier(
                    cashierPhone: cashierPhone,
                    order: order,
                    lang: lang,
                  );
                },
                icon: const Icon(Icons.open_in_new, color: Colors.white, size: 18),
                label: const Text('فتح الواتساب مجدداً 💬', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366), foregroundColor: Colors.white),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إبقاء الطاولة مفتوحة'),
          ),
          ElevatedButton(
            onPressed: () {
              Provider.of<OrdersProvider>(context, listen: false).updateStatus(order.id!, 'completed');
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم إغلاق الطاولة ومحاسبتها بنجاح!'),
                  backgroundColor: AppTheme.statusGreen,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryCoffee),
            child: const Text('إغلاق ومحاسبة الطاولة'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LocaleProvider>(context).langCode;
    final isAr = lang == 'ar';
    final ordersProvider = Provider.of<OrdersProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);
    final currency = AppStrings.get('currency', lang);

    final statuses = ['all', 'new', 'preparing', 'served', 'completed'];

    return Scaffold(
      appBar: isEmbedded
          ? null
          : AppBar(
              title: Text(AppStrings.get('order_tracker', lang)),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => ordersProvider.loadOrders(),
                ),
              ],
            ),
      body: Column(
        children: [
          // Filter Chips Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppTheme.cardLatte,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: statuses.map((status) {
                  final isSelected = ordersProvider.statusFilter == status;
                  int count = 0;
                  if (status == 'new') count = ordersProvider.newCount;
                  if (status == 'preparing') count = ordersProvider.preparingCount;
                  if (status == 'served') count = ordersProvider.servedCount;
                  if (status == 'completed') count = ordersProvider.completedCount;
                  if (status == 'all') count = ordersProvider.orders.length;

                  String label = AppStrings.get('status_$status', lang);
                  if (count > 0 && status != 'all') {
                    label = '$label ($count)';
                  }

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(label),
                      selected: isSelected,
                      onSelected: (_) => ordersProvider.setStatusFilter(status),
                      selectedColor: AppTheme.primaryCoffee,
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.textDark,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        fontSize: 13,
                      ),
                      side: BorderSide(
                        color: isSelected ? AppTheme.primaryCoffee : AppTheme.borderSubtle,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Orders List
          Expanded(
            child: ordersProvider.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryAmber))
                : ordersProvider.filteredOrders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.fact_check_outlined,
                              size: 64,
                              color: AppTheme.textMuted.withValues(alpha: 0.4),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              AppStrings.get('no_orders', lang),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textDark,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: ordersProvider.filteredOrders.length,
                        itemBuilder: (context, index) {
                          final order = ordersProvider.filteredOrders[index];
                          final statusColor = _getStatusColor(order.status);
                          final timeStr = DateFormat('hh:mm a').format(order.createdAt);
                          final isActive = order.status != 'completed' && order.status != 'cancelled';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 14),
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Top Row: Table & Status
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                            decoration: BoxDecoration(
                                              color: AppTheme.primaryCoffee,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              '${order.tableName} (#${order.tableNumber})',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            order.orderNumber,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.textMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: statusColor.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: statusColor, width: 1.2),
                                        ),
                                        child: Text(
                                          _getStatusLabel(order.status, lang),
                                          style: TextStyle(
                                            color: statusColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 10),

                                  // Time and Waiter
                                  Row(
                                    children: [
                                      const Icon(Icons.access_time, size: 14, color: AppTheme.textMuted),
                                      const SizedBox(width: 4),
                                      Text(timeStr, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                                      if (order.waiterName.isNotEmpty) ...[
                                        const SizedBox(width: 14),
                                        const Icon(Icons.person_outline, size: 14, color: AppTheme.textMuted),
                                        const SizedBox(width: 4),
                                        Text(order.waiterName, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                                      ],
                                    ],
                                  ),

                                  const Divider(height: 20),

                                  // Items Breakdown
                                  ...order.items.map((item) {
                                    final sizeStr = item.size != 'Standard' ? ' (${item.size})' : '';
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 3),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                '${item.quantity}x ${item.getName(lang)}$sizeStr',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13.5,
                                                  color: AppTheme.textDark,
                                                ),
                                              ),
                                              Text(
                                                '${item.totalPrice.toStringAsFixed(2)} $currency',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13.5,
                                                  color: AppTheme.primaryCoffee,
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (item.notes.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 2, right: 12, left: 12),
                                              child: Text(
                                                '↳ ${item.notes}',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontStyle: FontStyle.italic,
                                                  color: AppTheme.statusOrange,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    );
                                  }),

                                  if (order.generalNotes.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppTheme.cardLatte,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '📝 ${order.generalNotes}',
                                        style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                      ),
                                    ),
                                  ],

                                  const Divider(height: 20),

                                  // Bottom Row: Total & Action Buttons
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            AppStrings.get('total', lang),
                                            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                          ),
                                          Text(
                                            '${order.totalAmount.toStringAsFixed(2)} $currency',
                                            style: const TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.primaryCoffee,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Wrap(
                                      spacing: 8,
                                      runSpacing: 6,
                                      alignment: WrapAlignment.end,
                                      children: [
                                        // Wi-Fi Print Bill Button
                                        OutlinedButton.icon(
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
                                              waiterName: order.waiterName.isNotEmpty ? order.waiterName : settings.waiterName,
                                              generalNotes: order.generalNotes,
                                            );
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(printRes.message),
                                                  backgroundColor: printRes.success ? AppTheme.statusGreen : AppTheme.statusRed,
                                                  duration: const Duration(seconds: 4),
                                                ),
                                              );
                                            }
                                          },
                                          icon: const Icon(Icons.print_rounded, color: AppTheme.primaryCoffee, size: 16),
                                          label: Text(
                                            isAr ? 'طباعة 🖨️' : 'Print 🖨️',
                                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppTheme.primaryCoffee),
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            side: const BorderSide(color: AppTheme.primaryCoffee, width: 1.2),
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                          ),
                                        ),

                                        // Dedicated "إرسال الفاتورة النهائية" Button
                                        if (isActive)
                                            ElevatedButton.icon(
                                              onPressed: () async {
                                                await WhatsAppService.sendFinalBillToCashier(
                                                  cashierPhone: settings.cashierPhone,
                                                  order: order,
                                                  lang: lang,
                                                );
                                                if (context.mounted) {
                                                  _showFinalBillDialog(context, order, settings.cashierPhone, lang);
                                                }
                                              },
                                              icon: const Icon(Icons.receipt, color: Colors.white, size: 16),
                                              label: Text(
                                                AppStrings.get('send_final_bill', lang),
                                                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF25D366),
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                elevation: 2,
                                              ),
                                            ),

                                          // Status Progression Button
                                          if (order.status == 'new')
                                            ElevatedButton(
                                              onPressed: () {
                                                ordersProvider.updateStatus(order.id!, 'preparing');
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: AppTheme.statusBlue,
                                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                              ),
                                              child: Text(
                                                isAr ? 'بدء التحضير' : 'Start Prep',
                                                style: const TextStyle(fontSize: 13),
                                              ),
                                            ),

                                          if (order.status == 'preparing')
                                            ElevatedButton.icon(
                                              onPressed: () {
                                                ordersProvider.updateStatus(order.id!, 'served');
                                              },
                                              icon: const Icon(Icons.delivery_dining, size: 18),
                                              label: Text(
                                                AppStrings.get('action_mark_served', lang),
                                                style: const TextStyle(fontSize: 13),
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: AppTheme.statusGreen,
                                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                              ),
                                            ),

                                          if (order.status == 'served')
                                            ElevatedButton.icon(
                                              onPressed: () {
                                                ordersProvider.updateStatus(order.id!, 'completed');
                                              },
                                              icon: const Icon(Icons.done_all, size: 18),
                                              label: Text(
                                                AppStrings.get('action_mark_completed', lang),
                                                style: const TextStyle(fontSize: 13),
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: AppTheme.primaryCoffee,
                                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
