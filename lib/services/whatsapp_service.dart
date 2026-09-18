import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../models/order.dart';

class WhatsAppService {
  static String cleanPhoneNumber(String phone) {
    var cleaned = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.startsWith('07')) {
      cleaned = '962${cleaned.substring(1)}';
    } else if (cleaned.startsWith('7') && cleaned.length == 9) {
      cleaned = '962$cleaned';
    }
    return cleaned;
  }

  static String formatOrderMessage(
    Order order, {
    String lang = 'ar',
    bool isAddition = false,
    List<OrderItem>? addedItemsOnly,
    double? previousTotal,
  }) {
    final buffer = StringBuffer();
    final timeStr = DateFormat('hh:mm a').format(DateTime.now());
    final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final itemsToDisplay = addedItemsOnly ?? order.items;

    if (lang == 'ar') {
      if (isAddition) {
        buffer.writeln('➕ *طلب إضافي (ملحق) - كابرا بين | CABRA BEAN*');
      } else {
        buffer.writeln('🧾 *طلب جديد - كابرا بين | CABRA BEAN*');
      }
      buffer.writeln('📍 *طاولة:* ${order.tableName} (#${order.tableNumber})');
      if (order.waiterName.isNotEmpty) {
        buffer.writeln('👤 *الويتر:* ${order.waiterName}');
      }
      buffer.writeln('⏰ *الوقت:* $timeStr | $dateStr');
      buffer.writeln('----------------------------------------');
      if (isAddition) {
        buffer.writeln('📋 *الأصناف المضافة حديثاً:*');
      }

      for (var item in itemsToDisplay) {
        final sizeStr = item.size != 'Standard' ? ' (${item.size})' : '';
        buffer.writeln('• *${item.quantity}x* ${item.nameAr}$sizeStr - ${item.totalPrice.toStringAsFixed(2)} د.أ');
        if (item.notes.isNotEmpty) {
          buffer.writeln('   ↳ _ملاحظة: ${item.notes}_');
        }
      }

      buffer.writeln('----------------------------------------');
      if (isAddition) {
        final addedTotal = itemsToDisplay.fold(0.0, (sum, i) => sum + i.totalPrice);
        buffer.writeln('💵 *مجموع الإضافة:* ${addedTotal.toStringAsFixed(2)} د.أ');
        buffer.writeln('💰 *المجموع التراكمي للطاولة:* ${order.totalAmount.toStringAsFixed(2)} د.أ');
      } else {
        buffer.writeln('💵 *المجموع الإجمالي:* ${order.totalAmount.toStringAsFixed(2)} د.أ');
      }

      if (order.generalNotes.isNotEmpty) {
        buffer.writeln('📝 *ملاحظات:* ${order.generalNotes}');
      }
      buffer.writeln('----------------------------------------');
      buffer.writeln('🚗 _أول درايف-ثرو كافيه في جرش_');
    } else {
      if (isAddition) {
        buffer.writeln('➕ *ADDITIONAL ORDER - CABRA BEAN*');
      } else {
        buffer.writeln('🧾 *NEW ORDER - CABRA BEAN*');
      }
      buffer.writeln('📍 *Table:* ${order.tableName} (#${order.tableNumber})');
      if (order.waiterName.isNotEmpty) {
        buffer.writeln('👤 *Waiter:* ${order.waiterName}');
      }
      buffer.writeln('⏰ *Time:* $timeStr | $dateStr');
      buffer.writeln('----------------------------------------');
      if (isAddition) {
        buffer.writeln('📋 *Newly Added Items:*');
      }

      for (var item in itemsToDisplay) {
        final sizeStr = item.size != 'Standard' ? ' (${item.size})' : '';
        buffer.writeln('• *${item.quantity}x* ${item.nameEn}$sizeStr - ${item.totalPrice.toStringAsFixed(2)} JOD');
        if (item.notes.isNotEmpty) {
          buffer.writeln('   ↳ _Note: ${item.notes}_');
        }
      }

      buffer.writeln('----------------------------------------');
      if (isAddition) {
        final addedTotal = itemsToDisplay.fold(0.0, (sum, i) => sum + i.totalPrice);
        buffer.writeln('💵 *Added Items Total:* ${addedTotal.toStringAsFixed(2)} JOD');
        buffer.writeln('💰 *New Table Total:* ${order.totalAmount.toStringAsFixed(2)} JOD');
      } else {
        buffer.writeln('💵 *Total Amount:* ${order.totalAmount.toStringAsFixed(2)} JOD');
      }

      if (order.generalNotes.isNotEmpty) {
        buffer.writeln('📝 *Notes:* ${order.generalNotes}');
      }
      buffer.writeln('----------------------------------------');
      buffer.writeln('🚗 _First Drive-Thru Coffee in Jerash_');
    }

    return buffer.toString();
  }

  // Format the Final Bill for checkout
  static String formatFinalBillMessage(Order order, {String lang = 'ar'}) {
    final buffer = StringBuffer();
    final timeStr = DateFormat('hh:mm a').format(DateTime.now());
    final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    if (lang == 'ar') {
      buffer.writeln('🧾 *الفاتورة النهائية للمحاسبة - كابرا بين | CABRA BEAN*');
      buffer.writeln('📍 *طاولة:* ${order.tableName} (#${order.tableNumber})');
      if (order.waiterName.isNotEmpty) {
        buffer.writeln('👤 *الويتر:* ${order.waiterName}');
      }
      buffer.writeln('⏰ *وقت المحاسبة:* $timeStr | $dateStr');
      buffer.writeln('----------------------------------------');
      buffer.writeln('📋 *كافة طلبات الطاولة:*');

      for (var item in order.items) {
        final sizeStr = item.size != 'Standard' ? ' (${item.size})' : '';
        buffer.writeln('• *${item.quantity}x* ${item.nameAr}$sizeStr - ${item.totalPrice.toStringAsFixed(2)} د.أ');
        if (item.notes.isNotEmpty) {
          buffer.writeln('   ↳ _${item.notes}_');
        }
      }

      buffer.writeln('----------------------------------------');
      buffer.writeln('💵 *المجموع النهائي المطلوب للدفع:* ${order.totalAmount.toStringAsFixed(2)} د.أ');
      buffer.writeln('✅ *طلب الحساب والدفع (إغلاق ومحاسبة الطاولة)*');
      buffer.writeln('----------------------------------------');
      buffer.writeln('☕ _شكراً لزيارتكم كابرا بين - نتمنى لكم يوماً سعيداً_');
    } else {
      buffer.writeln('🧾 *FINAL CHECKOUT BILL - CABRA BEAN*');
      buffer.writeln('📍 *Table:* ${order.tableName} (#${order.tableNumber})');
      if (order.waiterName.isNotEmpty) {
        buffer.writeln('👤 *Waiter:* ${order.waiterName}');
      }
      buffer.writeln('⏰ *Checkout Time:* $timeStr | $dateStr');
      buffer.writeln('----------------------------------------');
      buffer.writeln('📋 *All Table Items:*');

      for (var item in order.items) {
        final sizeStr = item.size != 'Standard' ? ' (${item.size})' : '';
        buffer.writeln('• *${item.quantity}x* ${item.nameEn}$sizeStr - ${item.totalPrice.toStringAsFixed(2)} JOD');
        if (item.notes.isNotEmpty) {
          buffer.writeln('   ↳ _${item.notes}_');
        }
      }

      buffer.writeln('----------------------------------------');
      buffer.writeln('💵 *Grand Total to Pay:* ${order.totalAmount.toStringAsFixed(2)} JOD');
      buffer.writeln('✅ *Bill Requested & Paid (Close Table)*');
      buffer.writeln('----------------------------------------');
      buffer.writeln('☕ _Thank you for visiting Cabra Bean!_');
    }

    return buffer.toString();
  }

  static Future<bool> _launchWhatsApp(String phone, String text) async {
    final cleanPhone = cleanPhoneNumber(phone.isNotEmpty ? phone : '962791046258');
    final encoded = Uri.encodeComponent(text);

    if (kIsWeb) {
      final webUri = Uri.parse('https://api.whatsapp.com/send?phone=$cleanPhone&text=$encoded');
      try {
        return await launchUrl(
          webUri,
          mode: LaunchMode.platformDefault,
          webOnlyWindowName: '_blank',
        );
      } catch (_) {
        final fallback = Uri.parse('https://wa.me/$cleanPhone?text=$encoded');
        return await launchUrl(
          fallback,
          mode: LaunchMode.platformDefault,
          webOnlyWindowName: '_blank',
        );
      }
    } else {
      final nativeUri = Uri.parse('whatsapp://send?phone=$cleanPhone&text=$encoded');
      try {
        if (await canLaunchUrl(nativeUri)) {
          return await launchUrl(nativeUri, mode: LaunchMode.externalApplication);
        }
      } catch (_) {}

      final webUri = Uri.parse('https://api.whatsapp.com/send?phone=$cleanPhone&text=$encoded');
      return await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  }

  static Future<bool> sendOrderToCashier({
    required String cashierPhone,
    required Order order,
    String lang = 'ar',
    bool isAddition = false,
    List<OrderItem>? addedItemsOnly,
    double? previousTotal,
  }) async {
    final message = formatOrderMessage(
      order,
      lang: lang,
      isAddition: isAddition,
      addedItemsOnly: addedItemsOnly,
      previousTotal: previousTotal,
    );
    return await _launchWhatsApp(cashierPhone, message);
  }

  static Future<bool> sendFinalBillToCashier({
    required String cashierPhone,
    required Order order,
    String lang = 'ar',
  }) async {
    final message = formatFinalBillMessage(order, lang: lang);
    return await _launchWhatsApp(cashierPhone, message);
  }
}
