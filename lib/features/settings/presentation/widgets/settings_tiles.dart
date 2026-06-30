import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/providers/theme_provider.dart';
import '../../../../core/theme/theme_constants.dart';

// ── Settings section header ────────────────────────────────────────────────────

class SettingsSectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  const SettingsSectionHeader(this.title, {super.key, this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return Row(
      children: [
        if (icon != null) ...[
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
            child: Icon(icon, size: 14, color: primary),
          ),
          const SizedBox(width: 8),
        ],
        Text(
          title.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            letterSpacing: 1.4,
            color: primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ── Settings card ──────────────────────────────────────────────────────────────

class SettingsCard extends StatelessWidget {
  final Widget child;
  final bool isDark;
  const SettingsCard({super.key, required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? DarkColors.surface : LightColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

// ── Radio tile ─────────────────────────────────────────────────────────────────

class SettingsRadioTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool selected;
  final Color activeColor;
  final VoidCallback onTap;

  const SettingsRadioTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.paddingMd, vertical: 10),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? activeColor : theme.colorScheme.outlineVariant,
                  width: selected ? 6 : 2,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.bodyMedium),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
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
}

// ── Palette tile ───────────────────────────────────────────────────────────────

class SettingsPaletteTile extends StatelessWidget {
  final AppColorPalette palette;
  final bool isSelected;
  final VoidCallback onTap;

  const SettingsPaletteTile({
    super.key,
    required this.palette,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: palette.primary,
                shape: BoxShape.circle,
                border: isSelected
                    ? Border.all(
                        color: Theme.of(context).colorScheme.onSurface,
                        width: 3)
                    : null,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: palette.primary.withValues(alpha: 0.5),
                          blurRadius: 10,
                          spreadRadius: 2,
                        )
                      ]
                    : null,
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 24)
                  : null,
            ),
            const SizedBox(height: 6),
            Text(
              palette.label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isSelected
                        ? palette.primary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Permission tile ────────────────────────────────────────────────────────────

class SettingsPermissionTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Permission permission;
  final Color primaryColor;
  final bool isDark;

  const SettingsPermissionTile({
    super.key,
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.permission,
    required this.primaryColor,
    required this.isDark,
  });

  @override
  State<SettingsPermissionTile> createState() => _SettingsPermissionTileState();
}

class _SettingsPermissionTileState extends State<SettingsPermissionTile> {
  PermissionStatus _status = PermissionStatus.denied;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final s = await widget.permission.status;
    if (mounted) setState(() => _status = s);
  }

  Future<void> _request() async {
    final needsSettings = widget.permission == Permission.scheduleExactAlarm ||
        widget.permission == Permission.ignoreBatteryOptimizations ||
        _status.isPermanentlyDenied ||
        _status.isRestricted;

    if (needsSettings) {
      await openAppSettings();
      await Future.delayed(const Duration(milliseconds: 800));
    } else {
      final s = await widget.permission.request();
      if (mounted) setState(() => _status = s);
    }
    await _check();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final granted = _status.isGranted;
    final statusColor = granted ? TagColors.taken : TagColors.missed;
    final statusLabel = granted
        ? 'Granted'
        : _status.isPermanentlyDenied
            ? 'Denied'
            : 'Not granted';

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingMd, vertical: AppSizes.paddingMd),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: widget.primaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
            child: Icon(widget.icon, size: 18, color: widget.primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.label, style: theme.textTheme.bodyMedium),
                Text(
                  widget.subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: granted ? null : _request,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSizes.radiusPill),
              ),
              child: Text(
                granted ? statusLabel : 'Grant',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Info tile ──────────────────────────────────────────────────────────────────

class SettingsInfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color primaryColor;

  const SettingsInfoTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingMd, vertical: AppSizes.paddingMd),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
            child: Icon(icon, size: 18, color: primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: theme.textTheme.bodyMedium),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
