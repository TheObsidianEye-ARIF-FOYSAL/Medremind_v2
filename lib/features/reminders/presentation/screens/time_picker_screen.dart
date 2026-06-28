import 'package:flutter/material.dart';
import '../../../../core/common/widgets/circular_time_dial.dart';
import '../../../../core/common/widgets/pill_button.dart';
import '../../../../core/theme/theme_constants.dart';

/// Full circular-dial time picker — matches Images 2/3/4.
/// Returns the selected [TimeOfDay] via Navigator.pop.
class TimePickerScreen extends StatefulWidget {
  final TimeOfDay initial;
  final String? label; // e.g. "Morning"

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

  @override
  void initState() {
    super.initState();
    _time = widget.initial;
  }

  String get _hourStr =>
      (_time.hour % 12 == 0 ? 12 : _time.hour % 12).toString().padLeft(2, '0');
  String get _minStr => _time.minute.toString().padLeft(2, '0');
  String get _period => _time.hour < 12 ? 'AM' : 'PM';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingMd, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Text('Reminder',
                        style: theme.textTheme.titleLarge,
                        textAlign: TextAlign.center),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Label chip (e.g. "Morning ☀")
            if (widget.label != null)
              Padding(
                padding:
                    const EdgeInsets.only(bottom: AppSizes.paddingMd),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.12),
                    borderRadius:
                        BorderRadius.circular(AppSizes.radiusPill),
                  ),
                  child: Text(
                    widget.label!,
                    style: theme.textTheme.labelMedium
                        ?.copyWith(color: primary),
                  ),
                ),
              ),

            const Spacer(),

            // ── "Select time" label ────────────────────────────────────────
            Text(
              'Select time',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 12),

            // ── HH : MM AM/PM display ──────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Hour
                GestureDetector(
                  onTap: () => setState(() => _isHourMode = true),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _isHourMode
                          ? primary.withValues(alpha: 0.15)
                          : Colors.transparent,
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusMd),
                    ),
                    child: Text(
                      _hourStr,
                      style: theme.textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: _isHourMode
                            ? primary
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),

                Text(
                  ' : ',
                  style: theme.textTheme.displayMedium
                      ?.copyWith(fontWeight: FontWeight.w300),
                ),

                // Minute
                GestureDetector(
                  onTap: () => setState(() => _isHourMode = false),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: !_isHourMode
                          ? primary.withValues(alpha: 0.15)
                          : Colors.transparent,
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusMd),
                    ),
                    child: Text(
                      _minStr,
                      style: theme.textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: !_isHourMode
                            ? primary
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // AM/PM toggle
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

            const SizedBox(height: AppSizes.paddingXl),

            // ── Circular dial ───────────────────────────────────────────────
            CircularTimeDial(
              value: _time,
              isHourMode: _isHourMode,
              onChanged: (t) {
                setState(() => _time = t);
                // Auto-advance to minute mode after hour is set.
                if (_isHourMode) {
                  Future.delayed(
                    const Duration(milliseconds: 600),
                    () {
                      if (mounted) setState(() => _isHourMode = false);
                    },
                  );
                }
              },
            ),

            const Spacer(),

            // ── Set Reminder button ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSizes.paddingLg, 0,
                  AppSizes.paddingLg, AppSizes.paddingLg),
              child: PillButton(
                label: 'Set Reminder',
                onPressed: () => Navigator.of(context).pop(_time),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleAmPm() {
    final h = _time.hour;
    final newH = h < 12 ? h + 12 : h - 12;
    setState(() => _time = TimeOfDay(hour: newH, minute: _time.minute));
  }
}
