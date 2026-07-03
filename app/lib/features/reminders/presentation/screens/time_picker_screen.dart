import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/common/widgets/circular_time_dial.dart';
import '../../../../core/common/widgets/pill_button.dart';
import '../../../../core/theme/theme_constants.dart';

/// Full-screen time picker with a two-ring circular dial and keyboard mode.
///
/// • **Outer ring** — drag to change the hour.
/// • **Inner ring** — drag to change the minute.
/// • Tapping the HH : MM display or pressing the keyboard icon (top-right)
///   switches to keyboard input.
/// Returns the chosen [TimeOfDay] via Navigator.pop.
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
  bool _keyboardMode = false;

  late final TextEditingController _hourCtrl;
  late final TextEditingController _minCtrl;

  @override
  void initState() {
    super.initState();
    _time = widget.initial;
    _hourCtrl = TextEditingController(text: _fmtH(_time));
    _minCtrl = TextEditingController(text: _fmtM(_time));
  }

  @override
  void dispose() {
    _hourCtrl.dispose();
    _minCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _fmtH(TimeOfDay t) =>
      (t.hour % 12 == 0 ? 12 : t.hour % 12).toString().padLeft(2, '0');
  String _fmtM(TimeOfDay t) => t.minute.toString().padLeft(2, '0');
  String get _period => _time.hour < 12 ? 'AM' : 'PM';

  String get _periodLabel {
    final h = _time.hour;
    if (h >= 5 && h < 12) return 'Morning';
    if (h >= 12 && h < 17) return 'Afternoon';
    if (h >= 17 && h < 20) return 'Evening';
    return 'Night';
  }

  Color get _periodColor => switch (_periodLabel) {
        'Morning' => TagColors.morning,
        'Afternoon' => TagColors.afternoon,
        'Evening' => TagColors.evening,
        _ => TagColors.night,
      };

  IconData get _periodIcon => switch (_periodLabel) {
        'Morning' => Icons.wb_twilight_rounded,
        'Afternoon' => Icons.wb_sunny_rounded,
        'Evening' => Icons.wb_cloudy_rounded,
        _ => Icons.bedtime_rounded,
      };

  void _toggleAmPm() {
    final h = _time.hour;
    _updateTime(TimeOfDay(hour: h < 12 ? h + 12 : h - 12, minute: _time.minute));
  }

  void _updateTime(TimeOfDay t) {
    setState(() {
      _time = t;
      if (!_keyboardMode) {
        _hourCtrl.text = _fmtH(t);
        _minCtrl.text = _fmtM(t);
      }
    });
  }

  void _applyKeyboardInput() {
    final hRaw = int.tryParse(_hourCtrl.text.trim()) ?? (_time.hour % 12);
    final mRaw = int.tryParse(_minCtrl.text.trim()) ?? _time.minute;
    final h12 = hRaw.clamp(1, 12);
    final m = mRaw.clamp(0, 59);
    final isAm = _time.hour < 12;
    final h24 = h12 == 12 ? (isAm ? 0 : 12) : (isAm ? h12 : h12 + 12);
    setState(() => _time = TimeOfDay(hour: h24, minute: m));
  }

  void _openKeyboard() {
    if (_keyboardMode) return;
    setState(() => _keyboardMode = true);
  }

  void _toggleKeyboard() {
    if (_keyboardMode) _applyKeyboardInput();
    setState(() => _keyboardMode = !_keyboardMode);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

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
            // ── App bar ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingMd, vertical: 12),
              child: Row(children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: Text(
                    widget.label ?? 'Select Time',
                    style: theme.textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _keyboardMode
                        ? Icons.schedule_rounded
                        : Icons.keyboard_rounded,
                    color: primary,
                  ),
                  tooltip: _keyboardMode ? 'Switch to dial' : 'Type time',
                  onPressed: _toggleKeyboard,
                ),
              ]),
            ),

            // ── Period chip ────────────────────────────────────────────────
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Container(
                key: ValueKey(_periodLabel),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: periodColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                  border:
                      Border.all(color: periodColor.withValues(alpha: 0.30)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(_periodIcon, size: 15, color: periodColor),
                  const SizedBox(width: 6),
                  Text(
                    _periodLabel,
                    style: theme.textTheme.labelMedium?.copyWith(
                        color: periodColor, fontWeight: FontWeight.w700),
                  ),
                ]),
              ),
            ),

            const SizedBox(height: AppSizes.paddingLg),

            // ── Time display — tap to open keyboard ────────────────────────
            GestureDetector(
              onTap: _openKeyboard,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _TimeChip(
                    value: _keyboardMode ? _hourCtrl.text : _fmtH(_time),
                    primary: primary,
                    style: theme.textTheme.displayMedium,
                  ),
                  Text(
                    ' : ',
                    style: theme.textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.w300,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  _TimeChip(
                    value: _keyboardMode ? _minCtrl.text : _fmtM(_time),
                    primary: primary,
                    style: theme.textTheme.displayMedium,
                  ),
                  const SizedBox(width: 10),
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
              ),
            ),

            // Hint text below time display
            if (!_keyboardMode)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Tap time to type  ·  Drag rings to adjust',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),

            const Spacer(),

            // ── Dial or keyboard ───────────────────────────────────────────
            if (!_keyboardMode) ...[
              CircularTimeDial(
                value: _time,
                onChanged: _updateTime,
              ),
            ] else ...[
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
            ],

            const Spacer(),

            // ── Confirm button ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSizes.paddingLg, 0,
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

// ── Tappable time chip ────────────────────────────────────────────────────────

class _TimeChip extends StatelessWidget {
  final String value;
  final Color primary;
  final TextStyle? style;

  const _TimeChip({required this.value, required this.primary, this.style});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: primary.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        child: Text(
          value,
          style: style?.copyWith(
            fontWeight: FontWeight.w700,
            color: primary,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      );
}

// ── Keyboard input ────────────────────────────────────────────────────────────

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
        children: [
          _NumField(
            controller: hourCtrl,
            hint: 'HH',
            primary: primary,
            isDark: isDark,
            theme: theme,
            onChanged: onChanged,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(':',
                style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w300,
                    color: theme.colorScheme.onSurfaceVariant)),
          ),
          _NumField(
            controller: minCtrl,
            hint: 'MM',
            primary: primary,
            isDark: isDark,
            theme: theme,
            onChanged: onChanged,
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onTogglePeriod,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              child: Text(
                period,
                style: theme.textTheme.titleLarge?.copyWith(
                    color: primary, fontWeight: FontWeight.w700),
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
  final VoidCallback onChanged;

  const _NumField({
    required this.controller,
    required this.hint,
    required this.primary,
    required this.isDark,
    required this.theme,
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
        autofocus: true,
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
          fillColor:
              isDark ? DarkColors.surfaceVariant : LightColors.surfaceVariant,
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
