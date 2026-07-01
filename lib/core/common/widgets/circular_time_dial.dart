import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Circular drag-dial time picker matching the clock design.
///
/// • Outer ring: grey track with a coloured arc + draggable handle (number circle).
/// • Inner ring: decorative concentric ring inside the outer track.
/// • Clock hand: thin line from centre to the inner ring, capped with a white dot.
/// • Hour mode: drag the handle around the outer ring to set the hour.
/// • Minute mode: same gesture, but snaps to 5-min increments.
class CircularTimeDial extends StatefulWidget {
  final TimeOfDay value;
  final ValueChanged<TimeOfDay> onChanged;
  final bool isHourMode;

  const CircularTimeDial({
    super.key,
    required this.value,
    required this.onChanged,
    required this.isHourMode,
  });

  @override
  State<CircularTimeDial> createState() => _CircularTimeDialState();
}

class _CircularTimeDialState extends State<CircularTimeDial> {
  Offset? _center;

  void _onPanStart(DragStartDetails d) {
    final box = context.findRenderObject() as RenderBox;
    _center = box.size.center(Offset.zero);
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_center == null) return;
    final local = (context.findRenderObject() as RenderBox)
        .globalToLocal(d.globalPosition);
    final dx = local.dx - _center!.dx;
    final dy = local.dy - _center!.dy;

    var angle = math.atan2(dx, -dy);
    if (angle < 0) angle += 2 * math.pi;

    int newHour = widget.value.hour;
    int newMinute = widget.value.minute;

    if (widget.isHourMode) {
      var h12 = ((angle / (2 * math.pi)) * 12).round() % 12;
      final isPm = widget.value.hour >= 12;
      newHour = isPm ? h12 + 12 : h12;
      if (newHour != widget.value.hour) HapticFeedback.selectionClick();
    } else {
      final raw = ((angle / (2 * math.pi)) * 60).round() % 60;
      newMinute = (raw ~/ 5) * 5;
      if (newMinute != widget.value.minute) HapticFeedback.selectionClick();
    }

    widget.onChanged(TimeOfDay(hour: newHour, minute: newMinute));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      child: CustomPaint(
        painter: _DialPainter(
          value: widget.value,
          isHourMode: widget.isHourMode,
          primaryColor: primary,
          isDark: isDark,
        ),
        child: const SizedBox(width: 288, height: 288),
      ),
    );
  }
}

class _DialPainter extends CustomPainter {
  final TimeOfDay value;
  final bool isHourMode;
  final Color primaryColor;
  final bool isDark;

  _DialPainter({
    required this.value,
    required this.isHourMode,
    required this.primaryColor,
    required this.isDark,
  });

  // Ring geometry
  static const double _ringWidth = 26.0;
  static const double _innerRingWidth = 1.5;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2 - 14; // outer ring radius
    final innerRadius = outerRadius * 0.62;  // decorative inner ring radius

    final trackColor = isDark
        ? const Color(0xFF2C2C3E)
        : const Color(0xFFDDDDEE);
    final innerRingColor = isDark
        ? const Color(0xFF3A3A50)
        : const Color(0xFFCCCCDD);

    // ── 1. Outer background track ─────────────────────────────────────────────
    canvas.drawCircle(
      center,
      outerRadius,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = _ringWidth,
    );

    // ── 2. Inner decorative ring ──────────────────────────────────────────────
    canvas.drawCircle(
      center,
      innerRadius,
      Paint()
        ..color = innerRingColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = _innerRingWidth,
    );

    // ── 3. Progress arc (12 o'clock → handle, clockwise) ─────────────────────
    final h12 = value.hour % 12;
    final fraction =
        isHourMode ? (h12 / 12.0) : (value.minute / 60.0);
    final sweepAngle = fraction * 2 * math.pi;

    if (sweepAngle > 0.001) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: outerRadius),
        -math.pi / 2,
        sweepAngle,
        false,
        Paint()
          ..color = isDark
              ? Colors.white.withValues(alpha: 0.88)
              : Colors.white.withValues(alpha: 0.70)
          ..style = PaintingStyle.stroke
          ..strokeWidth = _ringWidth
          ..strokeCap = StrokeCap.round,
      );
    }

    // ── 4. Clock hand: centre → inner ring, with white cap dot ───────────────
    final handAngle = -math.pi / 2 + sweepAngle;
    final handEnd = Offset(
      center.dx + innerRadius * math.cos(handAngle),
      center.dy + innerRadius * math.sin(handAngle),
    );

    // Hand line
    canvas.drawLine(
      center,
      handEnd,
      Paint()
        ..color = primaryColor.withValues(alpha: 0.55)
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round,
    );

    // White cap dot at end of hand
    canvas.drawCircle(
      handEnd,
      5.5,
      Paint()..color = Colors.white.withValues(alpha: 0.90),
    );

    // ── 5. 12-o'clock reference marker ───────────────────────────────────────
    final topPos = Offset(center.dx, center.dy - outerRadius);
    canvas.drawCircle(
      topPos,
      15,
      Paint()
        ..color = isDark
            ? const Color(0xFF4A4A60)
            : const Color(0xFFAAAAAA),
    );
    _drawText(
      canvas,
      isHourMode ? '12' : '00',
      topPos,
      isDark ? Colors.white54 : Colors.black54,
      11,
      FontWeight.w600,
    );

    // ── 6. Handle circle on outer ring ───────────────────────────────────────
    final handlePos = Offset(
      center.dx + outerRadius * math.cos(handAngle),
      center.dy + outerRadius * math.sin(handAngle),
    );

    // Glow
    canvas.drawCircle(
      handlePos,
      22,
      Paint()
        ..color = primaryColor.withValues(alpha: 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Filled circle
    canvas.drawCircle(handlePos, 18, Paint()..color = primaryColor);

    // Label inside handle
    final label = isHourMode
        ? (h12 == 0 ? '12' : h12.toString())
        : value.minute.toString().padLeft(2, '0');
    _drawText(canvas, label, handlePos, Colors.white, 14, FontWeight.bold);

    // ── 7. Centre dot ─────────────────────────────────────────────────────────
    canvas.drawCircle(
      center,
      5,
      Paint()..color = primaryColor.withValues(alpha: 0.7),
    );
  }

  void _drawText(Canvas canvas, String text, Offset position, Color color,
      double fontSize, FontWeight weight) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: fontSize, fontWeight: weight),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, position - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(_DialPainter old) =>
      old.value != value ||
      old.isHourMode != isHourMode ||
      old.primaryColor != primaryColor ||
      old.isDark != isDark;
}
