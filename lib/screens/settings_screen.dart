import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/menu_provider.dart';
import '../providers/tables_provider.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import '../services/backup_service.dart';
import '../services/wifi_printer_service.dart';
import '../services/telegram_service.dart';
import 'categories_management_screen.dart';
import 'addons_management_screen.dart';
import 'menu_management_screen.dart';

class SettingsScreen extends StatefulWidget {
  final bool isEmbedded;
  const SettingsScreen({super.key, this.isEmbedded = false});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _waiterController = TextEditingController();
  final TextEditingController _printerIpController = TextEditingController();
  final TextEditingController _printerPortController = TextEditingController();
  final TextEditingController _telegramTokenController = TextEditingController();
  final TextEditingController _telegramChatIdController = TextEditingController();
  bool _isExporting = false;
  bool _isImporting = false;
  bool _isTestingPrinter = false;
  bool _isTestingTelegram = false;

  @override
  void initState() {
    super.initState();
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    _phoneController.text = settings.cashierPhone;
    _waiterController.text = settings.waiterName;
    _printerIpController.text = settings.printerIp;
    _printerPortController.text = settings.printerPort.toString();
    _telegramTokenController.text = settings.telegramBotToken;
    _telegramChatIdController.text = settings.telegramChatId;
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _waiterController.dispose();
    _printerIpController.dispose();
    _printerPortController.dispose();
    _telegramTokenController.dispose();
    _telegramChatIdController.dispose();
    super.dispose();
  }

  Future<void> _handleExport(BuildContext context) async {
    setState(() => _isExporting = true);
    final path = await BackupService.exportToJson();
    setState(() => _isExporting = false);

    if (mounted) {
      if (path != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تصدير النسخة الاحتياطية بنجاح ومشاركتها!'),
            backgroundColor: AppTheme.statusGreen,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('حدث خطأ أثناء تصدير النسخة الاحتياطية.'),
            backgroundColor: AppTheme.statusRed,
          ),
        );
      }
    }
  }

  Future<void> _handleImport(BuildContext context) async {
    setState(() => _isImporting = true);
    final success = await BackupService.importFromJson();
    setState(() => _isImporting = false);

    if (mounted) {
      if (success) {
        // Refresh providers
        await Provider.of<MenuProvider>(context, listen: false).loadMenuItems();
        await Provider.of<TablesProvider>(context, listen: false).loadTables();
        await Provider.of<SettingsProvider>(context, listen: false).loadSettings();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم استرجاع البيانات والمنيو بنجاح!'),
            backgroundColor: AppTheme.statusGreen,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('فشل استيراد الملف أو تم الإلغاء.'),
            backgroundColor: AppTheme.statusOrange,
          ),
        );
      }
    }
  }

  Future<void> _handleTestPrinter(BuildContext context, SettingsProvider settings) async {
    final ip = _printerIpController.text.trim();
    final port = int.tryParse(_printerPortController.text.trim()) ?? 9100;
    await settings.setPrinterIp(ip);
    await settings.setPrinterPort(port);

    setState(() => _isTestingPrinter = true);
    final result = await WifiPrinterService.printTest(
      ip: ip,
      port: port,
      cafeName: settings.cafeName,
    );
    setState(() => _isTestingPrinter = false);

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

  Future<void> _handleTestTelegram(BuildContext context, SettingsProvider settings) async {
    final token = _telegramTokenController.text.trim();
    final chatId = _telegramChatIdController.text.trim();
    await settings.setTelegramBotToken(token);
    await settings.setTelegramChatId(chatId);

    if (token.isEmpty || chatId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى كتابة Bot Token و Chat ID أولاً'),
          backgroundColor: AppTheme.statusOrange,
        ),
      );
      return;
    }

    setState(() => _isTestingTelegram = true);
    final result = await TelegramService.sendTestMessage(
      botToken: token,
      chatId: chatId,
      cafeName: settings.cafeName,
    );
    setState(() => _isTestingTelegram = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: result.success ? AppTheme.statusGreen : AppTheme.statusRed,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final lang = localeProvider.langCode;
    final isAr = lang == 'ar';
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      appBar: widget.isEmbedded
          ? null
          : AppBar(
              title: Text(AppStrings.get('settings_title', lang)),
            ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Branding Header Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            'assets/logo.jpg',
                            width: 65,
                            height: 65,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 65,
                              height: 65,
                              color: AppTheme.primaryAmber.withOpacity(0.2),
                              child: const Icon(Icons.coffee, color: AppTheme.primaryCoffee, size: 36),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'CABRA BEAN - كابرا بين',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryCoffee,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                AppStrings.get('tagline', lang),
                                style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'جرش - شارع وصفي التل 📍',
                                style: TextStyle(fontSize: 12, color: AppTheme.primaryAmber, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // Cashier & Waiter Section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'إعدادات الاتصال والويتر',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textDark),
                        ),
                        const SizedBox(height: 16),

                        // Cashier WhatsApp Phone
                        TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: AppStrings.get('cashier_phone', lang),
                            hintText: '962791046258',
                            prefixIcon: const Icon(Icons.phone_android, color: AppTheme.primaryAmber),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.check_circle, color: AppTheme.statusGreen),
                              onPressed: () {
                                settings.setCashierPhone(_phoneController.text);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('تم حفظ رقم الكاشير بنجاح')),
                                );
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Waiter Name
                        TextField(
                          controller: _waiterController,
                          decoration: InputDecoration(
                            labelText: AppStrings.get('waiter_name', lang),
                            hintText: 'أحمد خدرج',
                            prefixIcon: const Icon(Icons.person_outline, color: AppTheme.primaryAmber),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.check_circle, color: AppTheme.statusGreen),
                              onPressed: () {
                                settings.setWaiterName(_waiterController.text);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('تم حفظ اسم الويتر بنجاح')),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // Telegram Bot Settings Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.send_rounded, color: Color(0xFF0088CC), size: 24),
                            SizedBox(width: 8),
                            Text(
                              'بوت تليجرام (Telegram Bot)',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textDark),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'إرسال طلبات تحضير المطبخ والبار، والفواتير النهائية للمحاسبة مباشرة عبر بوت تليجرام.',
                          style: TextStyle(fontSize: 12.5, color: AppTheme.textMuted),
                        ),
                        const SizedBox(height: 16),

                        // Bot Token
                        TextField(
                          controller: _telegramTokenController,
                          decoration: InputDecoration(
                            labelText: 'رمز البوت (Bot Token)',
                            hintText: '123456789:ABCdefGhIJKlmNoPQRsTUVwxyZ',
                            prefixIcon: const Icon(Icons.key, color: Color(0xFF0088CC)),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.check_circle, color: AppTheme.statusGreen),
                              tooltip: 'حفظ Token',
                              onPressed: () {
                                settings.setTelegramBotToken(_telegramTokenController.text);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('تم حفظ Bot Token بنجاح')),
                                );
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Chat ID
                        TextField(
                          controller: _telegramChatIdController,
                          decoration: InputDecoration(
                            labelText: 'معرف المحادثة أو القناة (Chat ID)',
                            hintText: '-100xxxxxxxxxx أو 12345678',
                            prefixIcon: const Icon(Icons.chat_bubble_outline, color: Color(0xFF0088CC)),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.check_circle, color: AppTheme.statusGreen),
                              tooltip: 'حفظ Chat ID',
                              onPressed: () {
                                settings.setTelegramChatId(_telegramChatIdController.text);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('تم حفظ Chat ID بنجاح')),
                                );
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Test Telegram Button
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: ElevatedButton.icon(
                            onPressed: _isTestingTelegram ? null : () => _handleTestTelegram(context, settings),
                            icon: _isTestingTelegram
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.send, color: Colors.white, size: 18),
                            label: Text(
                              _isTestingTelegram ? 'جاري إرسال الرسالة التجريبية...' : 'إرسال رسالة تجريبية للبوت 🚀',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0088CC),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // Wi-Fi Thermal Printer Settings Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.print_rounded, color: AppTheme.primaryCoffee, size: 24),
                            const SizedBox(width: 8),
                            const Text(
                              'طابعة الفواتير (Wi-Fi Thermal Printer)',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textDark),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'قم بربط طابعة الإيصالات الحرارية (80mm/58mm) عبر شبكة الواي فاي لطباعة فواتير الطاولات مباشرة.',
                          style: TextStyle(fontSize: 12.5, color: AppTheme.textMuted),
                        ),
                        const SizedBox(height: 16),

                        // Printer IP
                        TextField(
                          controller: _printerIpController,
                          keyboardType: TextInputType.datetime,
                          decoration: InputDecoration(
                            labelText: 'عنوان IP الطابعة (Printer IP)',
                            hintText: '192.168.1.100',
                            prefixIcon: const Icon(Icons.wifi, color: AppTheme.primaryAmber),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.save_outlined, color: AppTheme.primaryCoffee),
                              tooltip: 'حفظ IP',
                              onPressed: () {
                                settings.setPrinterIp(_printerIpController.text);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('تم حفظ عنوان IP الطابعة')),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Printer Port
                        TextField(
                          controller: _printerPortController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'منفذ الطابعة (Port)',
                            hintText: '9100',
                            prefixIcon: const Icon(Icons.numbers, color: AppTheme.primaryAmber),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.save_outlined, color: AppTheme.primaryCoffee),
                              tooltip: 'حفظ المنفذ',
                              onPressed: () {
                                final port = int.tryParse(_printerPortController.text.trim()) ?? 9100;
                                settings.setPrinterPort(port);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('تم حفظ منفذ الطابعة')),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Auto-print toggle
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'طباعة الفاتورة تلقائياً عند إرسال الطلب',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textDark),
                          ),
                          subtitle: Text(
                            'يتم إرسال أمر الطباعة تلقائياً إلى طابعة الواي فاي بمجرد تسجيل طلب الطاولة',
                            style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                          ),
                          value: settings.autoPrintBill,
                          activeThumbColor: AppTheme.primaryAmber,
                          onChanged: (val) => settings.setAutoPrintBill(val),
                        ),
                        const SizedBox(height: 12),

                        // Test Print Button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: _isTestingPrinter ? null : () => _handleTestPrinter(context, settings),
                            icon: _isTestingPrinter
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.receipt_long, color: AppTheme.primaryCoffee),
                            label: Text(
                              _isTestingPrinter ? 'جاري الفحص والإرسال...' : 'طباعة فاتورة تجريبية (فحص الاتصال) 🖨️',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
                ),

                const SizedBox(height: 18),

                // Menu & Categories & Add-ons Management Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.restaurant_menu_rounded, color: AppTheme.primaryCoffee, size: 24),
                            const SizedBox(width: 8),
                            Text(
                              isAr ? 'إدارة المنيو والتصنيفات والخيارات' : 'Menu & Catalog Management',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textDark),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isAr
                              ? 'إدارة أصناف المنيو، وتعديل التصنيفات وتحديد أسعار الإضافات والصوصات الخاصة بالمشروبات والحلويات.'
                              : 'Manage menu items, organize categories, and configure add-on pricing.',
                          style: TextStyle(fontSize: 12.5, color: AppTheme.textMuted),
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.cardLatte,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.category_outlined, color: AppTheme.primaryCoffee),
                          ),
                          title: Text(isAr ? 'إدارة التصنيفات' : 'Categories Management', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(isAr ? 'إضافة وتعديل أقسام المشروبات والحلويات' : 'Organize coffee & drinks categories'),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const CategoriesManagementScreen()),
                            );
                          },
                        ),
                        const Divider(height: 12),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.cardLatte,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.tune, color: AppTheme.primaryCoffee),
                          ),
                          title: Text(isAr ? 'إدارة الإضافات والأسعار' : 'Add-ons & Modifiers', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(isAr ? 'تحديد أسعار الشوتات، الصوصات، الحليب، والسكر' : 'Configure pricing for extra shots, syrups, and milks'),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AddonsManagementScreen()),
                            );
                          },
                        ),
                        const Divider(height: 12),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.cardLatte,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.menu_book_outlined, color: AppTheme.primaryCoffee),
                          ),
                          title: Text(isAr ? 'إدارة الأصناف والأسعار' : 'Menu Items & Pricing', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(isAr ? 'إضافة وتعديل أسعار الأحجام (S / M / L)' : 'Manage item prices for S, M, L'),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const MenuManagementScreen()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // Language Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.get('language', lang),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textDark),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => localeProvider.setLocale('ar'),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: isAr ? AppTheme.primaryCoffee : Colors.transparent,
                                  foregroundColor: isAr ? Colors.white : AppTheme.primaryCoffee,
                                  side: const BorderSide(color: AppTheme.primaryCoffee),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                child: const Text('العربية (Arabic)', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => localeProvider.setLocale('en'),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: !isAr ? AppTheme.primaryCoffee : Colors.transparent,
                                  foregroundColor: !isAr ? Colors.white : AppTheme.primaryCoffee,
                                  side: const BorderSide(color: AppTheme.primaryCoffee),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                child: const Text('English (الإنجليزية)', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // Backup & Restore Card (JSON Export / Import)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.get('backup_restore', lang),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textDark),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'يمكنك تصدير قاعدة البيانات كملف JSON لحفظ نسخة احتياطية على جهاز آخر أو استيرادها عند الحاجة.',
                          style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            // Export Button
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _isExporting ? null : () => _handleExport(context),
                                icon: _isExporting
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                      )
                                    : const Icon(Icons.file_upload_outlined),
                                label: Text(AppStrings.get('export_json', lang)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryCoffee,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Import Button
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _isImporting ? null : () => _handleImport(context),
                                icon: _isImporting
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.file_download_outlined),
                                label: Text(AppStrings.get('import_json', lang)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.primaryCoffee,
                                  side: const BorderSide(color: AppTheme.primaryCoffee, width: 1.5),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
