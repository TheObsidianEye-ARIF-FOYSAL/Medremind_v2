import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/medicine.dart';
import '../../../../core/models/medicine_info.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/theme/theme_constants.dart';

/// Full medicine info page: why it's taken, its medicine group (drug class),
/// other brands with the same generic, dosage, side effects and precautions.
///
/// All data comes from a bundled offline dataset (21k+ Bangladesh brands),
/// so this works with no internet connection. If a medicine isn't in the
/// dataset, a friendly "more details coming soon" state is shown instead.
class MedicineDetailScreen extends ConsumerStatefulWidget {
  final Medicine medicine;
  const MedicineDetailScreen({super.key, required this.medicine});

  @override
  ConsumerState<MedicineDetailScreen> createState() =>
      _MedicineDetailScreenState();
}

class _MedicineDetailScreenState extends ConsumerState<MedicineDetailScreen> {
  static const _formIcons = {
    MedicineForm.tablet: Icons.circle_outlined,
    MedicineForm.pill: Icons.medication_rounded,
    MedicineForm.syrup: Icons.local_drink_rounded,
    MedicineForm.syringe: Icons.vaccines_rounded,
    MedicineForm.other: Icons.more_horiz_rounded,
  };

  BrandInfo? _brand;
  GenericInfo? _generic;
  List<BrandInfo> _sameGenericBrands = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = ref.read(medicineDatasetRepositoryProvider);
    final brand = await repo.findBrand(widget.medicine.brandName);
    GenericInfo? generic;
    List<BrandInfo> related = const [];
    if (brand != null) {
      generic = await repo.getGenericInfo(brand.generic);
      related = await repo.brandsForGeneric(brand.generic,
          excludeBrand: brand.brand);
    }
    if (!mounted) return;
    setState(() {
      _brand = brand;
      _generic = generic;
      _sameGenericBrands = related;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final med = widget.medicine;
    final iconColor = primary;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ───────────────────────────────────────────────
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
                  child: Text('Medicine Info',
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ),
              ]),
            ),

            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.all(AppSizes.paddingLg),
                      children: [
                        // ── Brand card ─────────────────────────────
                        Container(
                          padding: const EdgeInsets.all(AppSizes.paddingMd),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                primary.withValues(alpha: 0.16),
                                primary.withValues(alpha: 0.05),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusCard),
                            border: Border.all(
                                color: primary.withValues(alpha: 0.3)),
                          ),
                          child: Row(children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: iconColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(
                                    AppSizes.radiusMd),
                              ),
                              child: Icon(
                                  _formIcons[med.form] ??
                                      Icons.medication_rounded,
                                  color: iconColor,
                                  size: 26),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(med.brandName,
                                      style: theme.textTheme.titleLarge
                                          ?.copyWith(
                                              fontWeight: FontWeight.w800)),
                                  if (med.strength.isNotEmpty ||
                                      _brand?.strength.isNotEmpty == true)
                                    Text(
                                      med.strength.isNotEmpty
                                          ? med.strength
                                          : _brand!.strength,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(color: primary),
                                    ),
                                  if (_brand?.manufacturer.isNotEmpty == true)
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(top: 2),
                                      child: Text(
                                        _brand!.manufacturer,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                          color: theme
                                              .colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ]),
                        ),

                        const SizedBox(height: AppSizes.paddingLg),

                        if (_brand == null || _generic == null)
                          _ComingSoon(primary: primary)
                        else ...[
                          if (_generic!.indication.isNotEmpty ||
                              _generic!.indicationDescription.isNotEmpty)
                            _InfoSection(
                              icon: Icons.help_outline_rounded,
                              title: 'Why people take this',
                              color: primary,
                              isDark: isDark,
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  if (_generic!.indication.isNotEmpty)
                                    Text(_generic!.indication,
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                                fontWeight:
                                                    FontWeight.w700)),
                                  if (_generic!.indicationDescription
                                      .isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(_generic!.indicationDescription,
                                        style: theme.textTheme.bodyMedium),
                                  ],
                                ],
                              ),
                            ),

                          if (_generic!.drugClass.isNotEmpty)
                            _InfoSection(
                              icon: Icons.science_rounded,
                              title: 'Medicine Group',
                              color: primary,
                              isDark: isDark,
                              child: Text(_generic!.drugClass,
                                  style: theme.textTheme.bodyMedium),
                            ),

                          if (_sameGenericBrands.isNotEmpty)
                            _InfoSection(
                              icon: Icons.compare_arrows_rounded,
                              title:
                                  'Other brands (same generic: ${_brand!.generic})',
                              color: primary,
                              isDark: isDark,
                              child: Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: _sameGenericBrands
                                    .take(20)
                                    .map((b) => Container(
                                          padding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 5),
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? DarkColors.surfaceVariant
                                                : LightColors
                                                    .surfaceVariant,
                                            borderRadius:
                                                BorderRadius.circular(
                                                    AppSizes.radiusPill),
                                          ),
                                          child: Text(b.brand,
                                              style: theme
                                                  .textTheme.labelSmall),
                                        ))
                                    .toList(),
                              ),
                            ),

                          if (_generic!.dosageDescription.isNotEmpty)
                            _ExpandableSection(
                              icon: Icons.medication_liquid_rounded,
                              title: 'Dosage',
                              color: primary,
                              isDark: isDark,
                              text: _generic!.dosageDescription,
                            ),

                          if (_generic!.sideEffectsDescription.isNotEmpty)
                            _ExpandableSection(
                              icon: Icons.warning_amber_rounded,
                              title: 'Side Effects',
                              color: Colors.amber.shade800,
                              isDark: isDark,
                              text: _generic!.sideEffectsDescription,
                            ),

                          if (_generic!.precautionsDescription.isNotEmpty)
                            _ExpandableSection(
                              icon: Icons.shield_outlined,
                              title: 'Precautions',
                              color: Colors.redAccent,
                              isDark: isDark,
                              text: _generic!.precautionsDescription,
                            ),

                          if (_generic!.contraindicationsDescription
                              .isNotEmpty)
                            _ExpandableSection(
                              icon: Icons.block_rounded,
                              title: 'Contraindications',
                              color: Colors.redAccent,
                              isDark: isDark,
                              text:
                                  _generic!.contraindicationsDescription,
                            ),
                        ],

                        const SizedBox(height: AppSizes.paddingXl),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Coming soon state ──────────────────────────────────────────────────────────

class _ComingSoon extends StatelessWidget {
  final Color primary;
  const _ComingSoon({required this.primary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingLg),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        border: Border.all(color: primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(Icons.hourglass_top_rounded,
              size: 40, color: primary.withValues(alpha: 0.7)),
          const SizedBox(height: 12),
          Text('More details will be added soon',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(
            'We couldn\'t find this medicine in our offline database yet.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Info section (non-collapsible) ────────────────────────────────────────────

class _InfoSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final bool isDark;
  final Widget child;

  const _InfoSection({
    required this.icon,
    required this.title,
    required this.color,
    required this.isDark,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingMd),
      padding: const EdgeInsets.all(AppSizes.paddingMd),
      decoration: BoxDecoration(
        color: isDark ? DarkColors.surface : LightColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(title,
                  style: theme.textTheme.labelLarge
                      ?.copyWith(fontWeight: FontWeight.w700, color: color)),
            ),
          ]),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

// ── Expandable section (long text, collapsed by default) ─────────────────────

class _ExpandableSection extends StatefulWidget {
  final IconData icon;
  final String title;
  final Color color;
  final bool isDark;
  final String text;

  const _ExpandableSection({
    required this.icon,
    required this.title,
    required this.color,
    required this.isDark,
    required this.text,
  });

  @override
  State<_ExpandableSection> createState() => _ExpandableSectionState();
}

class _ExpandableSectionState extends State<_ExpandableSection> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingMd),
      decoration: BoxDecoration(
        color: widget.isDark ? DarkColors.surface : LightColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        border: Border(left: BorderSide(color: widget.color, width: 3)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _open = !_open),
            borderRadius: BorderRadius.circular(AppSizes.radiusCard),
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.paddingMd),
              child: Row(children: [
                Icon(widget.icon, size: 18, color: widget.color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(widget.title,
                      style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700, color: widget.color)),
                ),
                Icon(
                  _open
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ]),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState:
                _open ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            firstChild: Padding(
              padding: const EdgeInsets.fromLTRB(AppSizes.paddingMd, 0,
                  AppSizes.paddingMd, AppSizes.paddingMd),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(widget.text, style: theme.textTheme.bodyMedium),
              ),
            ),
            secondChild: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
