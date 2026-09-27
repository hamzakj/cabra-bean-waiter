import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppDisabledScreen extends StatelessWidget {
  const AppDisabledScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF140F0D),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo
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
                        color: AppTheme.primaryAmber.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(Icons.coffee, color: AppTheme.primaryAmber, size: 48),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

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
                  'كابرا بين',
                  style: TextStyle(
                    color: AppTheme.primaryAmber,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 36),

                // Completely static card - Zero buttons
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.block_rounded,
                          color: Colors.redAccent,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'التطبيق متوقف حالياً',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'تم إيقاف تشغيل هذا التطبيق من قِبل الإدارة.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 13,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
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
