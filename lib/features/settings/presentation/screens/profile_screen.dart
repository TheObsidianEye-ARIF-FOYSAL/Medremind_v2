import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme_constants.dart';
import 'settings_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late final TextEditingController _nameCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: ref.read(userNameProvider));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final name = ref.watch(userNameProvider);
    final hasName = name.isNotEmpty;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── App bar ───────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingMd, vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isDark
                        ? DarkColors.outlineVariant
                        : LightColors.outlineVariant,
                  ),
                ),
              ),
              child: Row(children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('My Profile',
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ),
              ]),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSizes.paddingLg),
                children: [
                  // ── Avatar ──────────────────────────────────────────────────
                  Center(
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: primary.withValues(alpha: 0.4),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: hasName
                          ? Center(
                              child: Text(
                                name[0].toUpperCase(),
                                style: theme.textTheme.displaySmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            )
                          : const Icon(Icons.person_rounded,
                              color: Colors.white, size: 44),
                    ),
                  ),

                  const SizedBox(height: AppSizes.paddingLg),

                  // ── Name field ──────────────────────────────────────────────
                  _SectionLabel('Display Name'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      hintText: 'Enter your name',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.check_circle_rounded,
                            color: TagColors.taken),
                        onPressed: _saveName,
                        tooltip: 'Save',
                      ),
                    ),
                    onSubmitted: (_) => _saveName(),
                  ),

                  const SizedBox(height: AppSizes.paddingXl),

                  // ── Account info ────────────────────────────────────────────
                  _SectionLabel('Account'),
                  const SizedBox(height: 8),
                  _InfoTile(
                    icon: Icons.phone_rounded,
                    label: 'Phone Number',
                    value: 'Available after login',
                    isDark: isDark,
                    muted: true,
                  ),
                  const SizedBox(height: AppSizes.paddingSm),
                  _InfoTile(
                    icon: Icons.email_rounded,
                    label: 'Email',
                    value: 'Available after login',
                    isDark: isDark,
                    muted: true,
                  ),

                  const SizedBox(height: AppSizes.paddingXl),

                  // ── Login notice ────────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(AppSizes.paddingMd),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.07),
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusLg),
                      border:
                          Border.all(color: primary.withValues(alpha: 0.18)),
                    ),
                    child: Row(children: [
                      Icon(Icons.lock_outline_rounded,
                          size: 18, color: primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Login feature coming soon. Your phone/email will be linked automatically when you sign in.',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: primary),
                        ),
                      ),
                    ]),
                  ),

                  const SizedBox(height: AppSizes.paddingXl),

                  // ── Danger zone ─────────────────────────────────────────────
                  _SectionLabel('Account Actions'),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _confirmUnsubscribe,
                    icon: const Icon(Icons.notifications_off_outlined,
                        color: Colors.orange),
                    label: const Text('Unsubscribe from Notifications',
                        style: TextStyle(color: Colors.orange)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.orange),
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusMd)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _confirmDeleteAccount,
                    icon: const Icon(Icons.delete_forever_rounded,
                        color: Colors.redAccent),
                    label: const Text('Delete Account & Data',
                        style: TextStyle(color: Colors.redAccent)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.redAccent),
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusMd)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveName() async {
    final name = _nameCtrl.text.trim();
    await ref.read(userNameProvider.notifier).set(name);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name saved!')),
      );
    }
  }

  Future<void> _confirmUnsubscribe() async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unsubscribe'),
        content: const Text(
            'This will disable all medicine reminders and notifications.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Coming soon',
                  style: TextStyle(color: Colors.grey))),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteAccount() async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
            'Account deletion will be available once login is enabled.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK')),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 2),
        child: Text(
          text.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                letterSpacing: 1.1,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      );
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;
  final bool muted;
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMd),
      decoration: BoxDecoration(
        color: isDark ? DarkColors.surface : LightColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
      child: Row(children: [
        Icon(icon,
            size: 20,
            color: muted
                ? theme.colorScheme.onSurfaceVariant
                : theme.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
              Text(value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: muted
                        ? theme.colorScheme.onSurfaceVariant
                        : null,
                    fontStyle: muted ? FontStyle.italic : null,
                  )),
            ],
          ),
        ),
      ]),
    );
  }
}
