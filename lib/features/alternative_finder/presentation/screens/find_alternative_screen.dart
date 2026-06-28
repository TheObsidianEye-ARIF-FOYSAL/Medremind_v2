import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/generic_group.dart';
import '../../../../core/theme/theme_constants.dart';
import '../providers/alternative_finder_provider.dart';

class FindAlternativeScreen extends ConsumerStatefulWidget {
  const FindAlternativeScreen({super.key});

  @override
  ConsumerState<FindAlternativeScreen> createState() =>
      _FindAlternativeScreenState();
}

class _FindAlternativeScreenState
    extends ConsumerState<FindAlternativeScreen> {
  final _ctrl = TextEditingController();
  final _debounce = _Debouncer(duration: const Duration(milliseconds: 350));

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final state = ref.watch(alternativeFinderProvider);
    final notifier = ref.read(alternativeFinderProvider.notifier);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSizes.paddingLg, AppSizes.paddingLg,
                  AppSizes.paddingLg, 0),
              child: Text(
                'Find Alternative',
                style: theme.textTheme.headlineMedium,
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSizes.paddingLg, AppSizes.paddingMd,
                  AppSizes.paddingLg, 0),
              child: Text(
                'Type a brand name to find medicines with the same generic',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),

            // ── Search field ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(AppSizes.paddingLg),
              child: TextField(
                controller: _ctrl,
                autofocus: false,
                decoration: InputDecoration(
                  hintText: 'e.g. Napa, Seclo, Amdocal…',
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Icon(Icons.search_rounded, color: primary),
                  ),
                  suffixIcon: state.query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _ctrl.clear();
                            notifier.clear();
                          },
                        )
                      : null,
                ),
                onChanged: (v) =>
                    _debounce.run(() => notifier.search(v)),
              ),
            ),

            // ── Results ──────────────────────────────────────────────────
            Expanded(
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : state.query.isEmpty
                      ? _EmptyPrompt(primary: primary)
                      : state.results.isEmpty
                          ? _NoResults(query: state.query)
                          : ListView(
                              padding: const EdgeInsets.fromLTRB(
                                  AppSizes.paddingLg, 0,
                                  AppSizes.paddingLg, 110),
                              children: [
                                // Exact brand match card (highlighted)
                                if (state.exactMatch != null)
                                  _ExactMatchCard(
                                    group: state.exactMatch!,
                                    searchedBrand: state.query.trim(),
                                    isDark: isDark,
                                    primary: primary,
                                  ),

                                if (state.exactMatch != null &&
                                    state.results.length > 1)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        top: AppSizes.paddingMd,
                                        bottom: AppSizes.paddingSm),
                                    child: Text(
                                      'Also in this search',
                                      style: theme.textTheme.labelMedium
                                          ?.copyWith(
                                        color: theme.colorScheme
                                            .onSurfaceVariant,
                                      ),
                                    ),
                                  ),

                                // All other result cards
                                ...state.results
                                    .where((g) =>
                                        state.exactMatch == null ||
                                        g.id != state.exactMatch!.id)
                                    .map((g) => Padding(
                                          padding: const EdgeInsets.only(
                                              bottom: AppSizes.paddingSm),
                                          child: _GenericGroupCard(
                                            group: g,
                                            isDark: isDark,
                                            primary: primary,
                                          ),
                                        )),
                              ],
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Exact match card (brand found) ────────────────────────────────────────────

class _ExactMatchCard extends StatelessWidget {
  final GenericGroup group;
  final String searchedBrand;
  final bool isDark;
  final Color primary;

  const _ExactMatchCard({
    required this.group,
    required this.searchedBrand,
    required this.isDark,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final otherBrands =
        group.brands.where((b) => b.toLowerCase() != searchedBrand.toLowerCase()).toList();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primary.withValues(alpha: 0.18),
            primary.withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        border: Border.all(color: primary.withValues(alpha: 0.4), width: 1.5),
      ),
      padding: const EdgeInsets.all(AppSizes.paddingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Brand → Generic
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius:
                      BorderRadius.circular(AppSizes.radiusPill),
                ),
                child: Text(
                  searchedBrand.length > 1
                      ? searchedBrand[0].toUpperCase() +
                          searchedBrand.substring(1)
                      : searchedBrand,
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: Colors.white),
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_rounded,
                  size: 16, color: primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  group.name,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(color: primary),
                ),
              ),
            ],
          ),

          if (group.description != null) ...[
            const SizedBox(height: 6),
            Text(
              group.description!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],

          const SizedBox(height: AppSizes.paddingMd),

          Text(
            '${otherBrands.length} alternatives available',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),

          // Brand chips
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: otherBrands
                .map((b) => _BrandChip(brand: b, primary: primary))
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ── Generic group card (non-exact result) ─────────────────────────────────────

class _GenericGroupCard extends StatelessWidget {
  final GenericGroup group;
  final bool isDark;
  final Color primary;

  const _GenericGroupCard({
    required this.group,
    required this.isDark,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? DarkColors.surface : LightColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
      ),
      padding: const EdgeInsets.all(AppSizes.paddingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.12),
                  borderRadius:
                      BorderRadius.circular(AppSizes.radiusSm),
                ),
                child: Icon(Icons.science_rounded,
                    color: primary, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(group.name,
                        style: theme.textTheme.titleSmall),
                    if (group.description != null)
                      Text(
                        group.description!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color:
                              theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.1),
                  borderRadius:
                      BorderRadius.circular(AppSizes.radiusPill),
                ),
                child: Text(
                  '${group.brands.length} brands',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.paddingMd),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: group.brands
                .map((b) => _BrandChip(brand: b, primary: primary))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _BrandChip extends StatelessWidget {
  final String brand;
  final Color primary;
  const _BrandChip({required this.brand, required this.primary});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDark
            ? DarkColors.surfaceVariant
            : LightColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppSizes.radiusPill),
      ),
      child: Text(
        brand,
        style: Theme.of(context).textTheme.labelSmall,
      ),
    );
  }
}

// ── Empty / no-result states ──────────────────────────────────────────────────

class _EmptyPrompt extends StatelessWidget {
  final Color primary;
  const _EmptyPrompt({required this.primary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.compare_arrows_rounded,
                size: 40, color: primary),
          ),
          const SizedBox(height: 20),
          Text('Search for a medicine',
              style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Text(
            'Type a brand name like "Napa" or\n"Seclo" to find alternatives',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 110),
        ],
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  final String query;
  const _NoResults({required this.query});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off_rounded, size: 56),
          const SizedBox(height: 16),
          Text('No results for "$query"',
              style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Text(
            'Try a different spelling or a generic name',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 110),
        ],
      ),
    );
  }
}

// ── Simple debouncer ──────────────────────────────────────────────────────────

class _Debouncer {
  final Duration duration;
  _Debouncer({required this.duration});

  void run(void Function() fn) {
    Future.delayed(duration).then((_) => fn());
  }
}
