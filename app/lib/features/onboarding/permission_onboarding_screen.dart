import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/theme_constants.dart';

const _kOnboardingDone = 'onboarding_done_v2';

/// Returns true if permission onboarding has already been completed.
Future<bool> isOnboardingDone() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_kOnboardingDone) ?? false;
}

Future<void> markOnboardingDone() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_kOnboardingDone, true);
}

class PermissionOnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const PermissionOnboardingScreen({super.key, required this.onComplete});

  @override
  State<PermissionOnboardingScreen> createState() =>
      _PermissionOnboardingScreenState();
}

class _PermissionOnboardingScreenState
    extends State<PermissionOnboardingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  bool _requesting = false;

  static const _permissions = [
    _PermItem(
      icon: Icons.notifications_active_rounded,
      title: 'Dose Notifications',
      subtitle: 'Get reminded when it\'s time to take your medicine',
      permission: Permission.notification,
      color: Color(0xFF6C5CE7),
    ),
    _PermItem(
      icon: Icons.alarm_rounded,
      title: 'Exact Alarms',
      subtitle: 'Ring precisely on schedule even when your phone is idle',
      permission: Permission.scheduleExactAlarm,
      color: Color(0xFF00B4D8),
    ),
    _PermItem(
      icon: Icons.battery_saver_rounded,
      title: 'Battery Optimization',
      subtitle:
          'Keep alarms working in the background without being killed',
      permission: Permission.ignoreBatteryOptimizations,
      color: Color(0xFF00C896),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  Future<void> _grantAll() async {
    setState(() => _requesting = true);

    // 1. Notification — runtime dialog (Android 13+)
    await Permission.notification.request();

    // 2. Exact alarm — runtime dialog on API 31-32; auto-granted on API 33+
    final alarmStatus = await Permission.scheduleExactAlarm.status;
    if (!alarmStatus.isGranted) {
      await Permission.scheduleExactAlarm.request();
    }

    // 3. Battery optimization — system intent dialog
    final batteryStatus = await Permission.ignoreBatteryOptimizations.status;
    if (!batteryStatus.isGranted) {
      await Permission.ignoreBatteryOptimizations.request();
    }

    await markOnboardingDone();
    if (mounted) widget.onComplete();
  }

  Future<void> _skip() async {
    await markOnboardingDone();
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingLg),
          child: Column(
            children: [
              const SizedBox(height: AppSizes.paddingXl),

              // ── Hero ───────────────────────────────────────────────
              FadeTransition(
                opacity: _anim,
                child: Column(children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(colors: [
                        primary.withValues(alpha: 0.3),
                        primary.withValues(alpha: 0.06),
                      ]),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primary.withValues(alpha: 0.3),
                          blurRadius: 32,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(Icons.medication_rounded,
                        size: 44, color: primary),
                  ),
                  const SizedBox(height: AppSizes.paddingLg),
                  Text(
                    'Set up MedRemind',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Allow these permissions so your\nreminders always work reliably.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ]),
              ),

              const SizedBox(height: AppSizes.paddingXl),

              // ── Permission items ───────────────────────────────────
              ..._permissions.map((p) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSizes.paddingMd),
                    child: Container(
                      padding: const EdgeInsets.all(AppSizes.paddingMd),
                      decoration: BoxDecoration(
                        color: isDark ? DarkColors.surface : LightColors.surface,
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusLg),
                        border: Border.all(
                          color: p.color.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                p.color.withValues(alpha: 0.2),
                                p.color.withValues(alpha: 0.06),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusMd),
                          ),
                          child: Icon(p.icon, color: p.color, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.title,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w700)),
                              Text(p.subtitle,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color:
                                        theme.colorScheme.onSurfaceVariant,
                                  )),
                            ],
                          ),
                        ),
                      ]),
                    ),
                  )),

              const Spacer(),

              // ── Buttons ────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: [primary, primary.withValues(alpha: 0.75)]),
                    borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                    boxShadow: [
                      BoxShadow(
                          color: primary.withValues(alpha: 0.45),
                          blurRadius: 20,
                          offset: const Offset(0, 6)),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _requesting ? null : _grantAll,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusPill),
                      ),
                    ),
                    child: _requesting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5),
                          )
                        : const Text('Allow All & Continue',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 16)),
                  ),
                ),
              ),

              const SizedBox(height: 12),
              TextButton(
                onPressed: _skip,
                child: Text(
                  'Skip for now',
                  style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
              const SizedBox(height: AppSizes.paddingMd),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Permission permission;
  final Color color;

  const _PermItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.permission,
    required this.color,
  });
}
