import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import '../models/order.dart';

class PrinterResult {
  final bool success;
  final String message;

  PrinterResult({required this.success, required this.message});
}

class WifiPrinterService {
  /// Send raw bytes to network thermal printer
  static Future<PrinterResult> sendBytes({
    required String ip,
    int port = 9100,
    required List<int> bytes,
    Duration timeout = const Duration(seconds: 6),
  }) async {
    final cleanIp = ip.trim();
    if (cleanIp.isEmpty) {
      return PrinterResult(
        success: false,
        message: 'عنوان IP الخاص بالطابعة فارغ. يرجى تحديده في الإعدادات.',
      );
    }

    Socket? socket;
    try {
      socket = await Socket.connect(cleanIp, port, timeout: timeout);
      socket.add(bytes);
      await socket.flush();
      await Future.delayed(const Duration(milliseconds: 250));
      await socket.close();
      return PrinterResult(
        success: true,
        message: 'تم إرسال الفاتورة للطابعة بنجاح ($cleanIp:$port)',
      );
    } on SocketException catch (e) {
      return PrinterResult(
        success: false,
        message: 'تعذر الاتصال بالطابعة ($cleanIp:$port): ${e.message}',
      );
    } catch (e) {
      return PrinterResult(
        success: false,
        message: 'خطأ أثناء الطباعة: $e',
      );
    } finally {
      socket?.destroy();
    }
  }

  /// Print a test receipt in TSPL (Xprinter XP-365B native)
  static Future<PrinterResult> printTest({
    required String ip,
    int port = 9100,
    String cafeName = 'CABRA BEAN CAFE',
  }) async {
    final now = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
    final tspl = StringBuffer();

    tspl.writeln('SIZE 75 mm, 55 mm');
    tspl.writeln('GAP 0,0');
    tspl.writeln('DIRECTION 1');
    tspl.writeln('CLS');
    tspl.writeln('TEXT 30,25,"3",0,1,1,"$cafeName"');
    tspl.writeln('TEXT 30,65,"2",0,1,1,"--------------------------------"');
    tspl.writeln('TEXT 30,95,"2",0,1,1,"TEST PRINT / فحص اتصال الطابعة"');
    tspl.writeln('TEXT 30,130,"2",0,1,1,"Wi-Fi Printer: $ip:$port"');
    tspl.writeln('TEXT 30,165,"2",0,1,1,"Time: $now"');
    tspl.writeln('TEXT 30,200,"2",0,1,1,"--------------------------------"');
    tspl.writeln('TEXT 30,230,"2",0,1,1,"Status: CONNECTED & WORKING OK"');
    tspl.writeln('TEXT 30,265,"2",0,1,1,"Cabra Bean - Jerash, Jordan"');
    tspl.writeln('PRINT 1,1');

    return await sendBytes(ip: ip, port: port, bytes: utf8.encode(tspl.toString()));
  }

  /// Format and print a Table Bill in TSPL (Xprinter XP-365B native)
  static Future<PrinterResult> printTableBill({
    required String ip,
    int port = 9100,
    required String cafeName,
    required String tableName,
    required int tableNumber,
    required List<OrderItem> items,
    required double totalAmount,
    int? orderId,
    String? waiterName,
    String? generalNotes,
    bool isAddition = false,
  }) async {
    final now = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());

    int lineCount = 10 + (items.length * 2);
    if (generalNotes != null && generalNotes.isNotEmpty) lineCount += 2;
    final heightMm = (lineCount * 4.5).clamp(60.0, 250.0).toInt();

    final tspl = StringBuffer();
    tspl.writeln('SIZE 75 mm, $heightMm mm');
    tspl.writeln('GAP 0,0');
    tspl.writeln('DIRECTION 1');
    tspl.writeln('CLS');

    int y = 25;
    const spacing = 32;

    // Header
    tspl.writeln('TEXT 30,$y,"3",0,1,1,"CABRA BEAN CAFE"');
    y += spacing;
    tspl.writeln('TEXT 30,$y,"2",0,1,1,"Coffee & Drive-Thru - Jerash"');
    y += spacing;
    tspl.writeln('TEXT 30,$y,"2",0,1,1,"================================"');
    y += spacing;

    // Bill Title
    final title = isAddition ? "TABLE BILL (ADDITION)" : "TABLE BILL / فاتورة طاولة";
    tspl.writeln('TEXT 30,$y,"3",0,1,1,"$title"');
    y += spacing;
    tspl.writeln('TEXT 30,$y,"2",0,1,1,"--------------------------------"');
    y += spacing;

    // Table & Meta info
    tspl.writeln('TEXT 30,$y,"3",0,1,1,"TABLE: $tableName (#$tableNumber)"');
    y += spacing;
    if (orderId != null) {
      tspl.writeln('TEXT 30,$y,"2",0,1,1,"Order ID: #$orderId"');
      y += spacing;
    }
    if (waiterName != null && waiterName.isNotEmpty) {
      tspl.writeln('TEXT 30,$y,"2",0,1,1,"Waiter: $waiterName"');
      y += spacing;
    }
    tspl.writeln('TEXT 30,$y,"2",0,1,1,"Date: $now"');
    y += spacing;
    tspl.writeln('TEXT 30,$y,"2",0,1,1,"--------------------------------"');
    y += spacing;

    // Column Headers
    tspl.writeln('TEXT 30,$y,"2",0,1,1,"Item                  Qty  Price"');
    y += spacing;
    tspl.writeln('TEXT 30,$y,"2",0,1,1,"--------------------------------"');
    y += spacing;

    // Items
    for (final item in items) {
      final name = item.nameEn.isNotEmpty ? item.nameEn : item.nameAr;
      final size = (item.size != 'Standard' && item.size.isNotEmpty) ? '(${item.size})' : '';
      final full = '$name $size'.trim();
      final shortName = full.length > 18 ? full.substring(0, 18) : full;
      final qty = 'x${item.quantity}'.padLeft(3);
      final price = '${item.totalPrice.toStringAsFixed(2)} JD'.padLeft(8);

      final line = '$shortName'.padRight(19) + '$qty ' + '$price';
      tspl.writeln('TEXT 30,$y,"2",0,1,1,"$line"');
      y += spacing;

      if (item.notes.isNotEmpty) {
        tspl.writeln('TEXT 45,$y,"1",0,1,1,"* ${item.notes}"');
        y += 24;
      }
    }

    tspl.writeln('TEXT 30,$y,"2",0,1,1,"================================"');
    y += spacing;

    // General Notes
    if (generalNotes != null && generalNotes.trim().isNotEmpty) {
      tspl.writeln('TEXT 30,$y,"2",0,1,1,"Notes: ${generalNotes.trim()}"');
      y += spacing;
      tspl.writeln('TEXT 30,$y,"2",0,1,1,"--------------------------------"');
      y += spacing;
    }

    // Grand Total
    tspl.writeln('TEXT 30,$y,"3",0,1,1,"TOTAL: ${totalAmount.toStringAsFixed(2)} JOD"');
    y += spacing;
    tspl.writeln('TEXT 30,$y,"2",0,1,1,"================================"');
    y += spacing;

    // Footer
    tspl.writeln('TEXT 30,$y,"2",0,1,1,"Thank you for visiting Cabra!"');
    y += spacing;

    // Command to print
    tspl.writeln('PRINT 1,1');

    return await sendBytes(ip: ip, port: port, bytes: utf8.encode(tspl.toString()));
  }
}
