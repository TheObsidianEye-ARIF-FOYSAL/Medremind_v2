import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Two-ring circular time picker.
///
/// • **Outer ring** (large) — drag to set the **hour** (1–12).
/// • **Inner ring** (small) — drag to set the **minute** (0–55, 5-min steps).
/// Both rings are always interactive; the touch is routed to whichever ring
/// is geometrically closer to the starting touch point.
class CircularTimeDial extends StatefulWidget {
  final TimeOfDay value;
  final ValueChanged<TimeOfDay> onChanged;

  const CircularTimeDial({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  State<CircularTimeDial> createState() => _CircularTimeDialState();
}

enum _DragRing { hour, minute }

class _CircularTimeDialState extends State<CircularTimeDial> {
  Offset? _center;
  _DragRing _active = _DragRing.hour;

  static const double _outerR = 118.0;
  static const double _innerR = 68.0;

  void _onPanStart(DragStartDetails d) {
    final box = context.findRenderObject() as RenderBox;
    _center = box.size.center(Offset.zero);
    final local = box.globalToLocal(d.globalPosition);
    final dist = (local - _center!).distance;
    final toOuter = (dist - _outerR).abs();
    final toInner = (dist - _innerR).abs();
    _active = toOuter <= toInner ? _DragRing.hour : _DragRing.minute;
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

    if (_active == _DragRing.hour) {
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
        painter: _TwoRingPainter(
          value: widget.value,
          primaryColor: primary,
          isDark: isDark,
        ),
        child: const SizedBox(width: 300, height: 300),
      ),
    );
  }
}

// ── Painter ───────────────────────────────────────────────────────────────────

class _TwoRingPainter extends CustomPainter {
  final TimeOfDay value;
  final Color primaryColor;
  final bool isDark;

  _TwoRingPainter({
    required this.value,
    required this.primaryColor,
    required this.isDark,
  });

  static const double _outerR = 118.0;
  static const double _outerStroke = 26.0;
  static const double _innerR = 68.0;
  static const double _innerStroke = 20.0;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final trackColor = isDark
        ? const Color(0xFF2C2C3E)
        : const Color(0xFFDDDDEE);

    // Secondary colour for the minute ring (slightly transparent primary)
    final minuteArcColor = primaryColor.withValues(alpha: isDark ? 0.65 : 0.55);

    // ── Outer ring track (hours) ──────────────────────────────────────────────
    canvas.drawCircle(
      center,
      _outerR,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = _outerStroke,
    );

    // ── Inner ring track (minutes) ────────────────────────────────────────────
    canvas.drawCircle(
      center,
      _innerR,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = _innerStroke,
    );

    // ── Hour arc (outer ring, full primary colour) ────────────────────────────
    final h12 = value.hour % 12;
    final hourFraction = h12 / 12.0;
    final hourSweep = hourFraction * 2 * math.pi;

    if (hourSweep > 0.001) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: _outerR),
        -math.pi / 2,
        hourSweep,
        false,
        Paint()
          ..color = isDark
              ? Colors.white.withValues(alpha: 0.88)
              : Colors.white.withValues(alpha: 0.72)
          ..style = PaintingStyle.stroke
          ..strokeWidth = _outerStroke
          ..strokeCap = StrokeCap.round,
      );
    }

    // ── Minute arc (inner ring) ───────────────────────────────────────────────
    final minFraction = value.minute / 60.0;
    final minSweep = minFraction * 2 * math.pi;

    if (minSweep > 0.001) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: _innerR),
        -math.pi / 2,
        minSweep,
        false,
        Paint()
          ..color = minuteArcColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = _innerStroke
          ..strokeCap = StrokeCap.round,
      );
    }

    // ── Hour handle (outer ring) ──────────────────────────────────────────────
    final hourAngle = -math.pi / 2 + hourSweep;
    final hourHandlePos = Offset(
      center.dx + _outerR * math.cos(hourAngle),
      center.dy + _outerR * math.sin(hourAngle),
    );

    // Glow
    canvas.drawCircle(
      hourHandlePos,
      22,
      Paint()
        ..color = primaryColor.withValues(alpha: 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
    );
    // Handle circle
    canvas.drawCircle(hourHandlePos, 17, Paint()..color = primaryColor);
    // Hour label
    final hLabel = h12 == 0 ? '12' : h12.toString();
    _drawText(canvas, hLabel, hourHandlePos, Colors.white, 13, FontWeight.bold);

    // 12 o'clock marker (outer)
    _drawRingMarker(
      canvas,
      center: center,
      radius: _outerR,
      label: '12',
      isDark: isDark,
    );

    // ── Minute handle (inner ring) ────────────────────────────────────────────
    final minAngle = -math.pi / 2 + minSweep;
    final minHandlePos = Offset(
      center.dx + _innerR * math.cos(minAngle),
      center.dy + _innerR * math.sin(minAngle),
    );

    // Glow
    canvas.drawCircle(
      minHandlePos,
      18,
      Paint()
        ..color = primaryColor.withValues(alpha: 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );
    // Handle circle
    canvas.drawCircle(
        minHandlePos, 13, Paint()..color = primaryColor.withValues(alpha: 0.85));
    // Minute label
    final mLabel = value.minute.toString().padLeft(2, '0');
    _drawText(canvas, mLabel, minHandlePos, Colors.white, 11, FontWeight.bold);

    // 00 marker (inner)
    _drawRingMarker(
      canvas,
      center: center,
      radius: _innerR,
      label: '00',
      isDark: isDark,
      markerRadius: 12,
      fontSize: 9,
    );

    // ── Clock hands (thin lines from centre to each handle) ───────────────────
    final handPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.40)
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    // Hour hand — stops just inside outer ring
    final hourHandEnd = Offset(
      center.dx + (_outerR - _outerStroke / 2 - 4) * math.cos(hourAngle),
      center.dy + (_outerR - _outerStroke / 2 - 4) * math.sin(hourAngle),
    );
    canvas.drawLine(center, hourHandEnd, handPaint);

    // Minute hand — stops just inside inner ring
    final minHandEnd = Offset(
      center.dx + (_innerR - _innerStroke / 2 - 4) * math.cos(minAngle),
      center.dy + (_innerR - _innerStroke / 2 - 4) * math.sin(minAngle),
    );
    canvas.drawLine(center, minHandEnd, handPaint);

    // ── Centre dot ────────────────────────────────────────────────────────────
    canvas.drawCircle(
      center,
      5.5,
      Paint()..color = primaryColor,
    );
  }

  /// Draws the "12" / "00" reference marker on the ring at 12 o'clock.
  void _drawRingMarker(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required String label,
    required bool isDark,
    double markerRadius = 14,
    double fontSize = 10,
  }) {
    final topPos = Offset(center.dx, center.dy - radius);
    canvas.drawCircle(
      topPos,
      markerRadius,
      Paint()
        ..color = isDark
            ? const Color(0xFF4A4A60)
            : const Color(0xFFB0B0C8),
    );
    _drawText(
      canvas,
      label,
      topPos,
      isDark ? Colors.white54 : Colors.black54,
      fontSize,
      FontWeight.w600,
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
  bool shouldRepaint(_TwoRingPainter old) =>
      old.value != value ||
      old.primaryColor != primaryColor ||
      old.isDark != isDark;
}
