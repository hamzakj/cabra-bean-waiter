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

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _waiterController = TextEditingController();
  final TextEditingController _printerIpController = TextEditingController();
  final TextEditingController _printerPortController = TextEditingController();
  bool _isExporting = false;
  bool _isImporting = false;
  bool _isTestingPrinter = false;

  @override
  void initState() {
    super.initState();
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    _phoneController.text = settings.cashierPhone;
    _waiterController.text = settings.waiterName;
    _printerIpController.text = settings.printerIp;
    _printerPortController.text = settings.printerPort.toString();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _waiterController.dispose();
    _printerIpController.dispose();
    _printerPortController.dispose();
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

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final lang = localeProvider.langCode;
    final isAr = lang == 'ar';
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      appBar: AppBar(
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
