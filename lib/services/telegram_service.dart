import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../models/order.dart';

class TelegramResult {
  final bool success;
  final String message;

  TelegramResult({required this.success, required this.message});
}

class TelegramService {
  static String escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;');
  }

  /// Sends a raw text message via Telegram Bot API
  static Future<TelegramResult> sendMessage({
    required String botToken,
    required String chatId,
    required String text,
  }) async {
    final cleanToken = botToken.trim();
    final cleanChatId = chatId.trim();

    if (cleanToken.isEmpty || cleanChatId.isEmpty) {
      return TelegramResult(
        success: false,
        message: 'يرجى إدخال Bot Token و Chat ID في الإعدادات أولاً',
      );
    }

    final url = Uri.parse('https://api.telegram.org/bot$cleanToken/sendMessage');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'chat_id': cleanChatId,
          'text': text,
          'parse_mode': 'HTML',
          'disable_web_page_preview': true,
        }),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['ok'] == true) {
        return TelegramResult(
          success: true,
          message: 'تم الإرسال عبر تليجرام بنجاح',
        );
      } else {
        final errorDesc = data['description'] ?? 'فشل الإرسال عبر تليجرام';
        return TelegramResult(
          success: false,
          message: 'خطأ من تليجرام: $errorDesc',
        );
      }
    } catch (e) {
      return TelegramResult(
        success: false,
        message: 'تعذر الاتصال بخوادم تليجرام: $e',
      );
    }
  }

  /// Sends test verification message from settings
  static Future<TelegramResult> sendTestMessage({
    required String botToken,
    required String chatId,
    String cafeName = 'Cabra Bean - كابرا بين',
  }) async {
    final timeStr = DateFormat('hh:mm a').format(DateTime.now());
    final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final message = '''
🤖 <b>رسالة تجريبية ناجحة من البوت</b>
☕ <b>${escapeHtml(cafeName)}</b>
⏰ <b>الوقت:</b> $timeStr | $dateStr
━━━━━━━━━━━━━━━━━━━━
✅ تم ربط تطبيق النادل بنجاح مع بوت تليجرام!
🚀 النظام جاهز لاستقبال طلبات التحضير والفواتير النهائية للمحاسبة.
''';

    return await sendMessage(
      botToken: botToken,
      chatId: chatId,
      text: message,
    );
  }

  /// Formats & sends Table Preparation Order (طلب تحضير للمطبخ والبار)
  static Future<TelegramResult> sendPreparationOrder({
    required String botToken,
    required String chatId,
    required Order order,
    String lang = 'ar',
    bool isAddition = false,
    List<OrderItem>? addedItemsOnly,
    double? previousTotal,
  }) async {
    final buffer = StringBuffer();
    final timeStr = DateFormat('hh:mm a').format(DateTime.now());
    final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final itemsToDisplay = addedItemsOnly ?? order.items;

    if (lang == 'ar') {
      buffer.writeln('🍳 ☕ <b>طلب تحضير (المطبخ / البار)</b>');
      buffer.writeln('☕ <b>كابرا بين | CABRA BEAN</b>');
      if (isAddition) {
        buffer.writeln('➕ <b>طلب إضافي (ملحق)</b>');
      } else {
        buffer.writeln('🆕 <b>طلب جديد</b>');
      }
      buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
      buffer.writeln('📍 <b>طاولة:</b> ${escapeHtml(order.tableName)} (#${order.tableNumber})');
      if (order.waiterName.isNotEmpty) {
        buffer.writeln('👤 <b>الويتر:</b> ${escapeHtml(order.waiterName)}');
      }
      buffer.writeln('⏰ <b>الوقت:</b> $timeStr | $dateStr');
      buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
      buffer.writeln(isAddition ? '📋 <b>الأصناف المضافة حديثاً للتحضير:</b>' : '📋 <b>الأصناف المطلوبة للتحضير:</b>');

      for (var item in itemsToDisplay) {
        final sizeStr = item.size != 'Standard' ? ' (${escapeHtml(item.size)})' : '';
        buffer.writeln('• <b>${item.quantity}x</b> ${escapeHtml(item.nameAr)}$sizeStr');
        if (item.notes.isNotEmpty) {
          buffer.writeln('   ↳ <i>ملاحظة: ${escapeHtml(item.notes)}</i>');
        }
      }

      buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
      if (order.generalNotes.isNotEmpty) {
        buffer.writeln('📝 <b>ملاحظات عامة:</b> ${escapeHtml(order.generalNotes)}');
        buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
      }
      buffer.writeln('⏳ <i>حالة الطلب: قيد التحضير</i>');
      buffer.writeln('🚗 <i>أول درايف-ثرو كافيه في جرش</i>');
    } else {
      buffer.writeln('🍳 ☕ <b>KITCHEN &amp; BAR PREPARATION ORDER</b>');
      buffer.writeln('☕ <b>CABRA BEAN</b>');
      if (isAddition) {
        buffer.writeln('➕ <b>ADDITIONAL ORDER</b>');
      } else {
        buffer.writeln('🆕 <b>NEW ORDER</b>');
      }
      buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
      buffer.writeln('📍 <b>Table:</b> ${escapeHtml(order.tableName)} (#${order.tableNumber})');
      if (order.waiterName.isNotEmpty) {
        buffer.writeln('👤 <b>Waiter:</b> ${escapeHtml(order.waiterName)}');
      }
      buffer.writeln('⏰ <b>Time:</b> $timeStr | $dateStr');
      buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
      buffer.writeln(isAddition ? '📋 <b>Newly Added Items to Prepare:</b>' : '📋 <b>Items to Prepare:</b>');

      for (var item in itemsToDisplay) {
        final sizeStr = item.size != 'Standard' ? ' (${escapeHtml(item.size)})' : '';
        buffer.writeln('• <b>${item.quantity}x</b> ${escapeHtml(item.nameEn)}$sizeStr');
        if (item.notes.isNotEmpty) {
          buffer.writeln('   ↳ <i>Note: ${escapeHtml(item.notes)}</i>');
        }
      }

      buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
      if (order.generalNotes.isNotEmpty) {
        buffer.writeln('📝 <b>Notes:</b> ${escapeHtml(order.generalNotes)}');
        buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
      }
      buffer.writeln('⏳ <i>Status: In Preparation</i>');
      buffer.writeln('🚗 <i>First Drive-Thru Coffee in Jerash</i>');
    }

    return await sendMessage(
      botToken: botToken,
      chatId: chatId,
      text: buffer.toString(),
    );
  }

  /// Formats & sends Final Bill for Checkout (فاتورة نهائية للمحاسبة وإغلاق الحساب)
  static Future<TelegramResult> sendFinalBill({
    required String botToken,
    required String chatId,
    required Order order,
    String lang = 'ar',
  }) async {
    final buffer = StringBuffer();
    final timeStr = DateFormat('hh:mm a').format(DateTime.now());
    final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    if (lang == 'ar') {
      buffer.writeln('🧾 💳 <b>فاتورة نهائية للمحاسبة</b>');
      buffer.writeln('☕ <b>كابرا بين | CABRA BEAN</b>');
      buffer.writeln('💰 <b>طلب الحساب والمحاسبة (إغلاق الطاولة والدفع)</b>');
      buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
      buffer.writeln('📍 <b>طاولة:</b> ${escapeHtml(order.tableName)} (#${order.tableNumber})');
      if (order.waiterName.isNotEmpty) {
        buffer.writeln('👤 <b>الويتر:</b> ${escapeHtml(order.waiterName)}');
      }
      buffer.writeln('⏰ <b>وقت المحاسبة:</b> $timeStr | $dateStr');
      buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
      buffer.writeln('📋 <b>كافة طلبات الطاولة:</b>');

      for (var item in order.items) {
        final sizeStr = item.size != 'Standard' ? ' (${escapeHtml(item.size)})' : '';
        buffer.writeln('• <b>${item.quantity}x</b> ${escapeHtml(item.nameAr)}$sizeStr - ${item.totalPrice.toStringAsFixed(2)} د.أ');
        if (item.notes.isNotEmpty) {
          buffer.writeln('   ↳ <i>${escapeHtml(item.notes)}</i>');
        }
      }

      buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
      buffer.writeln('💵 <b>المجموع النهائي المطلوب للدفع:</b> <b>${order.totalAmount.toStringAsFixed(2)} د.أ</b>');
      buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
      buffer.writeln('✅ <i>تم طلب الفاتورة لإغلاق الحساب ومحاسبة الطاولة</i>');
      buffer.writeln('☕ <i>شكراً لزيارتكم كابرا بين - نتمنى لكم يوماً سعيداً</i>');
    } else {
      buffer.writeln('🧾 💳 <b>FINAL CHECKOUT BILL</b>');
      buffer.writeln('☕ <b>CABRA BEAN</b>');
      buffer.writeln('💰 <b>Billing &amp; Payment (Close Table)</b>');
      buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
      buffer.writeln('📍 <b>Table:</b> ${escapeHtml(order.tableName)} (#${order.tableNumber})');
      if (order.waiterName.isNotEmpty) {
        buffer.writeln('👤 <b>Waiter:</b> ${escapeHtml(order.waiterName)}');
      }
      buffer.writeln('⏰ <b>Checkout Time:</b> $timeStr | $dateStr');
      buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
      buffer.writeln('📋 <b>All Table Items:</b>');

      for (var item in order.items) {
        final sizeStr = item.size != 'Standard' ? ' (${escapeHtml(item.size)})' : '';
        buffer.writeln('• <b>${item.quantity}x</b> ${escapeHtml(item.nameEn)}$sizeStr - ${item.totalPrice.toStringAsFixed(2)} JOD');
        if (item.notes.isNotEmpty) {
          buffer.writeln('   ↳ <i>${escapeHtml(item.notes)}</i>');
        }
      }

      buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
      buffer.writeln('💵 <b>Grand Total to Pay:</b> <b>${order.totalAmount.toStringAsFixed(2)} JOD</b>');
      buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
      buffer.writeln('✅ <i>Bill Requested &amp; Paid (Close Table)</i>');
      buffer.writeln('☕ <i>Thank you for visiting Cabra Bean!</i>');
    }

    return await sendMessage(
      botToken: botToken,
      chatId: chatId,
      text: buffer.toString(),
    );
  }
}
