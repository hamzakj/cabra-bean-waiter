import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/table_info.dart';
import '../providers/tables_provider.dart';
import '../providers/locale_provider.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';

class TablesManagementScreen extends StatelessWidget {
  const TablesManagementScreen({super.key});

  void _showTableDialog(BuildContext context, {TableInfo? table}) {
    final lang = Provider.of<LocaleProvider>(context, listen: false).langCode;
    final tablesProvider = Provider.of<TablesProvider>(context, listen: false);

    final numController = TextEditingController(
      text: table != null ? table.number.toString() : '',
    );
    final nameArController = TextEditingController(text: table?.nameAr ?? '');
    final nameEnController = TextEditingController(text: table?.nameEn ?? '');
    String section = table?.section ?? 'indoor';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(
              table == null ? AppStrings.get('add_table', lang) : 'تعديل الطاولة',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            content: SizedBox(
              width: 400,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: numController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: AppStrings.get('table_number', lang),
                        prefixIcon: const Icon(Icons.tag),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameArController,
                      decoration: InputDecoration(
                        labelText: AppStrings.get('table_name_ar', lang),
                        prefixIcon: const Icon(Icons.translate),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameEnController,
                      decoration: InputDecoration(
                        labelText: AppStrings.get('table_name_en', lang),
                        prefixIcon: const Icon(Icons.language),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: section,
                      decoration: InputDecoration(
                        labelText: AppStrings.get('section', lang),
                        prefixIcon: const Icon(Icons.place_outlined),
                      ),
                      items: ['indoor', 'terrace', 'bar', 'vip'].map((sec) {
                        return DropdownMenuItem(
                          value: sec,
                          child: Text(AppStrings.get('section_$sec', lang)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => section = val);
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(AppStrings.get('cancel', lang)),
              ),
              ElevatedButton(
                onPressed: () async {
                  final num = int.tryParse(numController.text.trim());
                  if (num == null) return;

                  final nameAr = nameArController.text.trim();
                  final nameEn = nameEnController.text.trim();

                  final newTable = TableInfo(
                    id: table?.id,
                    number: num,
                    nameAr: nameAr.isNotEmpty ? nameAr : 'طاولة $num',
                    nameEn: nameEn.isNotEmpty ? nameEn : 'Table $num',
                    section: section,
                    isOccupied: table?.isOccupied ?? false,
                  );

                  if (table == null) {
                    await tablesProvider.addTable(newTable);
                  } else {
                    await tablesProvider.updateTable(newTable);
                  }
                  if (context.mounted) Navigator.pop(ctx);
                },
                child: Text(AppStrings.get('save', lang)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LocaleProvider>(context).langCode;
    final tablesProvider = Provider.of<TablesProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.get('tables_management', lang)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTableDialog(context),
        backgroundColor: AppTheme.primaryAmber,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(AppStrings.get('add_table', lang)),
      ),
      body: tablesProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 220,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 1.1,
              ),
              itemCount: tablesProvider.tables.length,
              itemBuilder: (context, index) {
                final table = tablesProvider.tables[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: table.isOccupied
                                    ? AppTheme.statusOrange.withOpacity(0.15)
                                    : AppTheme.statusGreen.withOpacity(0.15),
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
                            Row(
                              children: [
                                InkWell(
                                  onTap: () => _showTableDialog(context, table: table),
                                  child: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.primaryCoffee),
                                ),
                                const SizedBox(width: 6),
                                InkWell(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('حذف الطاولة'),
                                        content: Text('هل أنت متأكد من حذف ${table.getName(lang)}؟'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx),
                                            child: Text(AppStrings.get('cancel', lang)),
                                          ),
                                          ElevatedButton(
                                            onPressed: () {
                                              if (table.id != null) {
                                                tablesProvider.deleteTable(table.id!);
                                              }
                                              Navigator.pop(ctx);
                                            },
                                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.statusRed),
                                            child: Text(AppStrings.get('delete', lang)),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  child: const Icon(Icons.delete_outline, size: 18, color: AppTheme.statusRed),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            const Icon(Icons.table_restaurant_rounded, size: 36, color: AppTheme.primaryCoffee),
                            const SizedBox(height: 4),
                            Text(
                              table.getName(lang),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            Text(
                              '#${table.number} • ${AppStrings.get('section_${table.section}', lang)}',
                              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
