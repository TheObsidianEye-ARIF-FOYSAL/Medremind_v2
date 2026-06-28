import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/common/widgets/circular_time_dial.dart';
import '../../../../core/common/widgets/pill_button.dart';
import '../../../../core/theme/theme_constants.dart';

/// Full circular-dial time picker with optional keyboard input mode.
/// Returns the selected [TimeOfDay] via Navigator.pop.
class TimePickerScreen extends StatefulWidget {
  final TimeOfDay initial;
  final String? label;

  const TimePickerScreen({
    super.key,
    required this.initial,
    this.label,
  });

  @override
  State<TimePickerScreen> createState() => _TimePickerScreenState();
}

class _TimePickerScreenState extends State<TimePickerScreen> {
  late TimeOfDay _time;
  bool _isHourMode = true;
  bool _keyboardMode = false;

  // For keyboard mode
  late final TextEditingController _hourCtrl;
  late final TextEditingController _minCtrl;

  @override
  void initState() {
    super.initState();
    _time = widget.initial;
    final displayH = _time.hour % 12 == 0 ? 12 : _time.hour % 12;
    _hourCtrl = TextEditingController(text: displayH.toString().padLeft(2, '0'));
    _minCtrl = TextEditingController(text: _time.minute.toString().padLeft(2, '0'));
  }

  @override
  void dispose() {
    _hourCtrl.dispose();
    _minCtrl.dispose();
    super.dispose();
  }

  // ── Dynamic label based on current time ──────────────────────────────────

  String get _periodLabel {
    final h = _time.hour;
    if (h >= 5 && h < 12) return 'Morning';
    if (h >= 12 && h < 17) return 'Afternoon';
    if (h >= 17 && h < 20) return 'Evening';
    return 'Night';
  }

  Color get _periodColor {
    switch (_periodLabel) {
      case 'Morning':
        return TagColors.morning;
      case 'Afternoon':
        return TagColors.afternoon;
      case 'Evening':
        return TagColors.evening;
      default:
        return TagColors.night;
    }
  }

  IconData get _periodIcon {
    switch (_periodLabel) {
      case 'Morning':
        return Icons.wb_twilight_rounded;
      case 'Afternoon':
        return Icons.wb_sunny_rounded;
      case 'Evening':
        return Icons.wb_cloudy_rounded;
      default:
        return Icons.bedtime_rounded;
    }
  }

  // ── Getters ───────────────────────────────────────────────────────────────

  String get _hourStr =>
      (_time.hour % 12 == 0 ? 12 : _time.hour % 12).toString().padLeft(2, '0');
  String get _minStr => _time.minute.toString().padLeft(2, '0');
  String get _period => _time.hour < 12 ? 'AM' : 'PM';

  void _toggleAmPm() {
    final h = _time.hour;
    final newH = h < 12 ? h + 12 : h - 12;
    _updateTime(TimeOfDay(hour: newH, minute: _time.minute));
  }

  void _updateTime(TimeOfDay t) {
    setState(() {
      _time = t;
      // Sync keyboard fields if in dial mode
      if (!_keyboardMode) {
        final displayH = t.hour % 12 == 0 ? 12 : t.hour % 12;
        _hourCtrl.text = displayH.toString().padLeft(2, '0');
        _minCtrl.text = t.minute.toString().padLeft(2, '0');
      }
    });
  }

  void _applyKeyboardInput() {
    final hRaw = int.tryParse(_hourCtrl.text.trim()) ?? _time.hour % 12;
    final mRaw = int.tryParse(_minCtrl.text.trim()) ?? _time.minute;
    final h12 = hRaw.clamp(1, 12);
    final m = mRaw.clamp(0, 59);
    final isAm = _time.hour < 12;
    final h24 = h12 == 12 ? (isAm ? 0 : 12) : (isAm ? h12 : h12 + 12);
    setState(() => _time = TimeOfDay(hour: h24, minute: m));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;
    final periodColor = _periodColor;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingMd, vertical: 12),
              child: Row(children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: Text('Set Time',
                      style: theme.textTheme.titleLarge,
                      textAlign: TextAlign.center),
                ),
                // Toggle dial/keyboard
                IconButton(
                  icon: Icon(
                    _keyboardMode ? Icons.schedule_rounded : Icons.keyboard_rounded,
                    color: primary,
                  ),
                  tooltip: _keyboardMode ? 'Switch to dial' : 'Type time',
                  onPressed: () {
                    if (_keyboardMode) _applyKeyboardInput();
                    setState(() => _keyboardMode = !_keyboardMode);
                  },
                ),
              ]),
            ),

            // ── Dynamic period label ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(bottom: AppSizes.paddingMd),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Container(
                  key: ValueKey(_periodLabel),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 7),
                  decoration: BoxDecoration(
                    color: periodColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                    border: Border.all(color: periodColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(_periodIcon, size: 16, color: periodColor),
                    const SizedBox(width: 6),
                    Text(
                      _periodLabel,
                      style: theme.textTheme.labelMedium
                          ?.copyWith(color: periodColor, fontWeight: FontWeight.w700),
                    ),
                  ]),
                ),
              ),
            ),

            const Spacer(),

            // ── HH : MM AM/PM display ──────────────────────────────────
            if (!_keyboardMode)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _TimeSegment(
                    value: _hourStr,
                    selected: _isHourMode,
                    primary: primary,
                    onTap: () => setState(() => _isHourMode = true),
                    style: theme.textTheme.displayMedium,
                  ),
                  Text(' : ',
                      style: theme.textTheme.displayMedium
                          ?.copyWith(fontWeight: FontWeight.w300)),
                  _TimeSegment(
                    value: _minStr,
                    selected: !_isHourMode,
                    primary: primary,
                    onTap: () => setState(() => _isHourMode = false),
                    style: theme.textTheme.displayMedium,
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _toggleAmPm,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        _period,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            else
              // ── Keyboard input mode ──────────────────────────────────
              _KeyboardInput(
                hourCtrl: _hourCtrl,
                minCtrl: _minCtrl,
                period: _period,
                primary: primary,
                isDark: isDark,
                theme: theme,
                onTogglePeriod: _toggleAmPm,
                onChanged: _applyKeyboardInput,
              ),

            const SizedBox(height: AppSizes.paddingXl),

            // ── Dial (only in dial mode) ───────────────────────────────
            if (!_keyboardMode) ...[
              CircularTimeDial(
                value: _time,
                isHourMode: _isHourMode,
                onChanged: (t) {
                  _updateTime(t);
                  if (_isHourMode) {
                    Future.delayed(const Duration(milliseconds: 600), () {
                      if (mounted) setState(() => _isHourMode = false);
                    });
                  }
                },
              ),
            ],

            const Spacer(),

            // ── Confirm button ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSizes.paddingLg, 0,
                  AppSizes.paddingLg, AppSizes.paddingLg),
              child: PillButton(
                label: 'Confirm Time',
                onPressed: () {
                  if (_keyboardMode) _applyKeyboardInput();
                  Navigator.of(context).pop(_time);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Time segment (tap to select hour/minute) ──────────────────────────────────

class _TimeSegment extends StatelessWidget {
  final String value;
  final bool selected;
  final Color primary;
  final VoidCallback onTap;
  final TextStyle? style;

  const _TimeSegment({
    required this.value,
    required this.selected,
    required this.primary,
    required this.onTap,
    this.style,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? primary.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          child: Text(
            value,
            style: style?.copyWith(
              fontWeight: FontWeight.w700,
              color: selected ? primary : Theme.of(context).colorScheme.onSurface,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      );
}

// ── Keyboard input mode widget ────────────────────────────────────────────────

class _KeyboardInput extends StatelessWidget {
  final TextEditingController hourCtrl;
  final TextEditingController minCtrl;
  final String period;
  final Color primary;
  final bool isDark;
  final ThemeData theme;
  final VoidCallback onTogglePeriod;
  final VoidCallback onChanged;

  const _KeyboardInput({
    required this.hourCtrl,
    required this.minCtrl,
    required this.period,
    required this.primary,
    required this.isDark,
    required this.theme,
    required this.onTogglePeriod,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingXl),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Hour
          _NumField(
            controller: hourCtrl,
            hint: 'HH',
            primary: primary,
            isDark: isDark,
            theme: theme,
            max: 12,
            onChanged: onChanged,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(':',
                style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w300,
                    color: theme.colorScheme.onSurfaceVariant)),
          ),
          // Minute
          _NumField(
            controller: minCtrl,
            hint: 'MM',
            primary: primary,
            isDark: isDark,
            theme: theme,
            max: 59,
            onChanged: onChanged,
          ),
          const SizedBox(width: 12),
          // AM/PM
          GestureDetector(
            onTap: onTogglePeriod,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              child: Text(
                period,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NumField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final Color primary;
  final bool isDark;
  final ThemeData theme;
  final int max;
  final VoidCallback onChanged;

  const _NumField({
    required this.controller,
    required this.hint,
    required this.primary,
    required this.isDark,
    required this.theme,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(2),
        ],
        style: theme.textTheme.displaySmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: primary,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: theme.textTheme.displaySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
            fontWeight: FontWeight.w300,
          ),
          filled: true,
          fillColor: isDark ? DarkColors.surfaceVariant : LightColors.surfaceVariant,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            borderSide: BorderSide(color: primary, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
        onChanged: (_) => onChanged(),
      ),
    );
  }
}
