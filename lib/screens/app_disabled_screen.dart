import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_status_provider.dart';
import '../theme/app_theme.dart';

class AppDisabledScreen extends StatelessWidget {
  const AppDisabledScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appStatus = Provider.of<AppStatusProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1310),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo or Brand Icon
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset(
                    'assets/logo.jpg',
                    width: 90,
                    height: 90,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryAmber.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(Icons.coffee, color: AppTheme.primaryAmber, size: 48),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Brand Name
                const Text(
                  'CABRA BEAN',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'كابرا بين - أول درايف-ثرو كافيه في جرش',
                  style: TextStyle(
                    color: AppTheme.primaryAmber,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 36),

                // Disabled Warning Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.redAccent.withOpacity(0.3), width: 1.5),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.lock_person_rounded,
                          color: Colors.redAccent,
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'التطبيق متوقف حالياً',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'تم إيقاف تشغيل تطبيق النادل مؤقتاً من قِبل الإدارة.\nيرجى التواصل مع إدارة كابرا بين أو الدعم الفني لإعادة تفعيل الخدمة.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                          height: 1.6,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),

                      // Retry verification button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: appStatus.isChecking
                              ? null
                              : () async {
                                  final enabled = await appStatus.checkStatus();
                                  if (!enabled && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('لا يزال التطبيق متوقفاً من الإدارة.'),
                                        backgroundColor: AppTheme.statusRed,
                                        duration: Duration(seconds: 3),
                                      ),
                                    );
                                  }
                                },
                          icon: appStatus.isChecking
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.refresh_rounded, color: Colors.white, size: 22),
                          label: Text(
                            appStatus.isChecking ? 'جاري التحقق...' : 'التحقق وإعادة المحاولة 🔄',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryAmber,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  'Jerash, Jordan 📍',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 12,
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
