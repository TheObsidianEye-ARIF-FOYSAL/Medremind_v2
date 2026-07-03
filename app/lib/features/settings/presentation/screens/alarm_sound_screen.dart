import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/app_settings_provider.dart';
import '../../../../core/services/app_settings_service.dart';
import '../../../../core/theme/theme_constants.dart';

class AlarmSoundScreen extends ConsumerStatefulWidget {
  const AlarmSoundScreen({super.key});

  @override
  ConsumerState<AlarmSoundScreen> createState() => _AlarmSoundScreenState();
}

class _AlarmSoundScreenState extends ConsumerState<AlarmSoundScreen> {
  final AudioPlayer _player = AudioPlayer();
  String? _playingPath;
  bool _loading = false;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePreview(String assetPath) async {
    if (_loading) return;

    if (_playingPath == assetPath) {
      // Tap again → stop
      await _player.stop();
      setState(() => _playingPath = null);
      return;
    }

    setState(() {
      _playingPath = assetPath;
      _loading = true;
    });

    try {
      await _player.stop();
      await _player.play(AssetSource(
        // AssetSource expects path WITHOUT "assets/" prefix
        assetPath.replaceFirst('assets/', ''),
      ));
      _player.onPlayerComplete.listen((_) {
        if (mounted && _playingPath == assetPath) {
          setState(() => _playingPath = null);
        }
      });
    } catch (_) {
      setState(() => _playingPath = null);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _select(String path) async {
    await ref.read(appSettingsProvider.notifier).setAlarmSound(path);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final appSettings = ref.watch(appSettingsProvider);

    // Split into two groups
    final classic = alarmSoundOptions
        .where((o) => _isClassic(o.assetPath))
        .toList();
    final melodic = alarmSoundOptions
        .where((o) => !_isClassic(o.assetPath))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alarm Sound'),
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSizes.paddingLg, AppSizes.paddingMd,
            AppSizes.paddingLg, 100),
        children: [
          // Info banner
          Container(
            padding: const EdgeInsets.all(AppSizes.paddingMd),
            margin: const EdgeInsets.only(bottom: AppSizes.paddingLg),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppSizes.radiusCard),
              border: Border.all(color: primary.withValues(alpha: 0.20)),
            ),
            child: Row(children: [
              Icon(Icons.touch_app_rounded, size: 18, color: primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Tap a ringtone to preview it. '
                  'Tap again to stop. '
                  'Press the ✓ button to save your selection.',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            ]),
          ),

          // ── Classic alarms ───────────────────────────────────────────────
          _SectionHeader('Classic Alarms',
              icon: Icons.alarm_rounded, isDark: isDark),
          const SizedBox(height: AppSizes.paddingSm),
          _SoundGroup(
            sounds: classic,
            selectedPath: appSettings.alarmSoundPath,
            playingPath: _playingPath,
            loading: _loading,
            primary: primary,
            isDark: isDark,
            onPreview: _togglePreview,
            onSelect: _select,
          ),

          const SizedBox(height: AppSizes.paddingXl),

          // ── Melodic / bell sounds ────────────────────────────────────────
          _SectionHeader('Melodic & Bells',
              icon: Icons.music_note_rounded, isDark: isDark),
          const SizedBox(height: AppSizes.paddingSm),
          _SoundGroup(
            sounds: melodic,
            selectedPath: appSettings.alarmSoundPath,
            playingPath: _playingPath,
            loading: _loading,
            primary: primary,
            isDark: isDark,
            onPreview: _togglePreview,
            onSelect: _select,
          ),
        ],
      ),

      // ── Floating save button ─────────────────────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await _player.stop();
          if (context.mounted) Navigator.of(context).pop();
        },
        backgroundColor: primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.check_rounded),
        label: const Text('Save'),
      ),
    );
  }

  bool _isClassic(String path) => path.contains('alarm') ||
      path.contains('scratch') ||
      path.contains('generic') ||
      path.contains('digital') ||
      path.contains('lesiakower') ||
      path.contains('jeremay') ||
      path.contains('u_inx5oo');
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isDark;

  const _SectionHeader(this.title, {required this.icon, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(children: [
      Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
      const SizedBox(width: 6),
      Text(
        title,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    ]);
  }
}

// ── Sound group (card) ────────────────────────────────────────────────────────

class _SoundGroup extends StatelessWidget {
  final List<AlarmSoundOption> sounds;
  final String selectedPath;
  final String? playingPath;
  final bool loading;
  final Color primary;
  final bool isDark;
  final Future<void> Function(String) onPreview;
  final Future<void> Function(String) onSelect;

  const _SoundGroup({
    required this.sounds,
    required this.selectedPath,
    required this.playingPath,
    required this.loading,
    required this.primary,
    required this.isDark,
    required this.onPreview,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = isDark ? DarkColors.surface : LightColors.surface;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
      ),
      child: Column(
        children: sounds.asMap().entries.map((entry) {
          final i = entry.key;
          final opt = entry.value;
          final isSelected = selectedPath == opt.assetPath;
          final isPlaying = playingPath == opt.assetPath;

          return Column(
            children: [
              if (i > 0)
                Divider(
                    height: 1,
                    indent: 16,
                    color: isDark
                        ? DarkColors.outlineVariant
                        : LightColors.outlineVariant),
              _SoundTile(
                option: opt,
                isSelected: isSelected,
                isPlaying: isPlaying,
                loading: loading && playingPath == opt.assetPath,
                primary: primary,
                theme: theme,
                onPreview: () => onPreview(opt.assetPath),
                onSelect: () => onSelect(opt.assetPath),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ── Individual sound tile ─────────────────────────────────────────────────────

class _SoundTile extends StatelessWidget {
  final AlarmSoundOption option;
  final bool isSelected;
  final bool isPlaying;
  final bool loading;
  final Color primary;
  final ThemeData theme;
  final VoidCallback onPreview;
  final VoidCallback onSelect;

  const _SoundTile({
    required this.option,
    required this.isSelected,
    required this.isPlaying,
    required this.loading,
    required this.primary,
    required this.theme,
    required this.onPreview,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPreview,
      borderRadius: BorderRadius.circular(AppSizes.radiusCard),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.paddingMd, vertical: 12),
        child: Row(children: [
          // Play / loading indicator
          SizedBox(
            width: 40,
            height: 40,
            child: loading
                ? Padding(
                    padding: const EdgeInsets.all(10),
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: primary),
                  )
                : AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isPlaying
                          ? primary
                          : primary.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isPlaying
                          ? Icons.stop_rounded
                          : Icons.play_arrow_rounded,
                      color: isPlaying ? Colors.white : primary,
                      size: 22,
                    ),
                  ),
          ),

          const SizedBox(width: 12),

          // Label + playing indicator
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  option.label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isSelected ? primary : null,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                if (isPlaying)
                  Text(
                    'Playing…',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: primary, fontWeight: FontWeight.w500),
                  ),
              ],
            ),
          ),

          // Select (save) button
          GestureDetector(
            onTap: onSelect,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? primary : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? primary
                      : theme.colorScheme.outlineVariant,
                  width: isSelected ? 0 : 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 16)
                  : null,
            ),
          ),
        ]),
      ),
    );
  }
}
