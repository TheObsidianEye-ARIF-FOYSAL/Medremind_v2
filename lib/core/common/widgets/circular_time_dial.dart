import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/haptic_feedback.dart';

/// The circular drag-dial time picker matching the design (Images 2/3/4).
///
/// • Hour mode: drag the purple handle around the outer ring to set the hour.
/// • Minute mode: drag to set minutes (in 5-min steps).
/// • Toggle between modes by tapping the central time display in the parent.
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
  double _dragAngle = 0;

  @override
  void didUpdateWidget(CircularTimeDial old) {
    super.didUpdateWidget(old);
    _dragAngle = _currentAngle();
  }

  double _currentAngle() {
    if (widget.isHourMode) {
      final h = widget.value.hour % 12;
      return (h / 12) * 2 * math.pi;
    } else {
      return (widget.value.minute / 60) * 2 * math.pi;
    }
  }

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

    // atan2 gives angle from positive-x axis; we want from top (negative-y).
    var angle = math.atan2(dx, -dy);
    if (angle < 0) angle += 2 * math.pi;

    int newHour = widget.value.hour;
    int newMinute = widget.value.minute;

    if (widget.isHourMode) {
      // Map [0, 2π] to [0, 12)
      var h12 = ((angle / (2 * math.pi)) * 12).round() % 12;
      // Preserve AM/PM
      final isPm = widget.value.hour >= 12;
      newHour = isPm ? h12 + 12 : h12;
      if (newHour != widget.value.hour) HapticFeedback.selectionClick();
    } else {
      // Snap to 5-minute increments
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
        child: const SizedBox(width: 280, height: 280),
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

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2 - 10;
    final ringWidth = 28.0;

    // ── 1. Background ring (track) ──────────────────────────────────────────
    final trackPaint = Paint()
      ..color = isDark
          ? const Color(0xFF2A2A3A)
          : const Color(0xFFE0E0EC)
      ..style = PaintingStyle.stroke
      ..strokeWidth = ringWidth;
    canvas.drawCircle(center, outerRadius, trackPaint);

    // ── 2. White progress arc — from 12 o'clock clockwise to handle ────────
    final h12 = value.hour % 12;
    final handleFraction = isHourMode
        ? (h12 / 12.0)
        : (value.minute / 60.0);
    final sweepAngle = handleFraction * 2 * math.pi;

    if (sweepAngle > 0.001) {
      final arcPaint = Paint()
        ..color = isDark
            ? Colors.white.withValues(alpha: 0.85)
            : Colors.white.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = ringWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: outerRadius),
        -math.pi / 2,  // start at top (12 o'clock)
        sweepAngle,
        false,
        arcPaint,
      );
    }

    // ── 3. Handle position ──────────────────────────────────────────────────
    final handleAngle = -math.pi / 2 + sweepAngle;
    final handlePos = Offset(
      center.dx + outerRadius * math.cos(handleAngle),
      center.dy + outerRadius * math.sin(handleAngle),
    );

    // Handle glow
    final glowPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(handlePos, 22, glowPaint);

    // Handle circle
    final handlePaint = Paint()..color = primaryColor;
    canvas.drawCircle(handlePos, 18, handlePaint);

    // Handle label (hour or minute number)
    final label = isHourMode
        ? (h12 == 0 ? '12' : h12.toString())
        : value.minute.toString().padLeft(2, '0');
    _drawText(canvas, label, handlePos, Colors.white, 14, FontWeight.bold);

    // ── 4. 12 o'clock reference marker ─────────────────────────────────────
    final topPos = Offset(center.dx, center.dy - outerRadius);
    final markerPaint = Paint()
      ..color = isDark ? const Color(0xFF555566) : const Color(0xFFB0B0C8);
    canvas.drawCircle(topPos, 16, markerPaint);
    _drawText(
      canvas,
      isHourMode ? '12' : '00',
      topPos,
      isDark ? Colors.white54 : Colors.black54,
      11,
      FontWeight.w600,
    );

    // ── 5. Center dot ───────────────────────────────────────────────────────
    canvas.drawCircle(
      center,
      5,
      Paint()..color = primaryColor.withValues(alpha: 0.6),
    );

    // ── 6. Minute hand (thin line from center outward to minute position) ──
    // Shown in both modes as a subtle indicator.
    final minFraction = value.minute / 60.0;
    final minAngle = -math.pi / 2 + minFraction * 2 * math.pi;
    final innerRadius = outerRadius * 0.55;
    final minEnd = Offset(
      center.dx + innerRadius * math.cos(minAngle),
      center.dy + innerRadius * math.sin(minAngle),
    );
    final linePaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.45)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, minEnd, linePaint);

    // Minute dot
    canvas.drawCircle(
      minEnd,
      5,
      Paint()..color = Colors.white.withValues(alpha: 0.8),
    );
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset position,
    Color color,
    double fontSize,
    FontWeight weight,
  ) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: weight,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      position - Offset(tp.width / 2, tp.height / 2),
    );
  }

  @override
  bool shouldRepaint(_DialPainter old) =>
      old.value != value ||
      old.isHourMode != isHourMode ||
      old.primaryColor != primaryColor ||
      old.isDark != isDark;
}
