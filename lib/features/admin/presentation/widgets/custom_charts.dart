import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class PatientTrendsChart extends StatelessWidget {
  final List<double> values;
  final List<String> labels;

  const PatientTrendsChart({
    super.key,
    required this.values,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: PatientTrendsPainter(
        values: values,
        labels: labels,
      ),
    );
  }
}

class DepartmentDistributionChart extends StatelessWidget {
  final Map<String, double> departmentPercentages;
  final Map<String, Color> departmentColors;

  const DepartmentDistributionChart({
    super.key,
    required this.departmentPercentages,
    required this.departmentColors,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(200, 200),
      painter: DepartmentDistributionPainter(
        departmentPercentages: departmentPercentages,
        departmentColors: departmentColors,
      ),
    );
  }
}

class PatientTrendsPainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;

  PatientTrendsPainter({required this.values, required this.labels});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final paintLine = Paint()
      ..color = const Color(0xFF2563EB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    final paintGrid = Paint()
      ..color = Colors.grey.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final textPainter = TextPainter(
      textDirection: ui.TextDirection.ltr,
    );

    double maxValue = values.reduce((curr, next) => curr > next ? curr : next);
    if (maxValue < 240) maxValue = 240;

    double paddingLeft = 32.0;
    double paddingRight = 12.0;
    double paddingTop = 15.0;
    double paddingBottom = 25.0;

    double chartWidth = size.width - paddingLeft - paddingRight;
    double chartHeight = size.height - paddingTop - paddingBottom;

    int gridLines = 6;
    for (int i = 0; i <= gridLines; i++) {
      double val = (maxValue / gridLines) * i;
      double y = size.height - paddingBottom - (chartHeight / gridLines) * i;

      canvas.drawLine(
        Offset(paddingLeft, y),
        Offset(size.width - paddingRight, y),
        paintGrid,
      );

      textPainter.text = TextSpan(
        text: val.toInt().toString().padLeft(2, '0'),
        style: TextStyle(
          color: Colors.grey.shade400,
          fontSize: 9.5,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(paddingLeft - textPainter.width - 6, y - textPainter.height / 2),
      );
    }

    List<Offset> points = [];
    double dx = chartWidth / (values.length - 1);
    for (int i = 0; i < values.length; i++) {
      double x = paddingLeft + dx * i;
      double y = size.height - paddingBottom - (values[i] / maxValue) * chartHeight;
      points.add(Offset(x, y));
    }

    if (points.isNotEmpty) {
      final pathArea = Path();
      pathArea.moveTo(points.first.dx, size.height - paddingBottom);

      for (int i = 0; i < points.length - 1; i++) {
        var p0 = points[i];
        var p1 = points[i + 1];
        var controlPoint1 = Offset(p0.dx + dx * 0.45, p0.dy);
        var controlPoint2 = Offset(p1.dx - dx * 0.45, p1.dy);
        pathArea.cubicTo(
          controlPoint1.dx, controlPoint1.dy,
          controlPoint2.dx, controlPoint2.dy,
          p1.dx, p1.dy,
        );
      }

      pathArea.lineTo(points.last.dx, size.height - paddingBottom);
      pathArea.close();

      final paintArea = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF2563EB).withValues(alpha: 0.24),
            const Color(0xFF2563EB).withValues(alpha: 0.01),
          ],
        ).createShader(Rect.fromLTRB(
          paddingLeft,
          paddingTop,
          size.width - paddingRight,
          size.height - paddingBottom,
        ));

      canvas.drawPath(pathArea, paintArea);
    }

    if (points.isNotEmpty) {
      final pathLine = Path();
      pathLine.moveTo(points.first.dx, points.first.dy);

      for (int i = 0; i < points.length - 1; i++) {
        var p0 = points[i];
        var p1 = points[i + 1];
        var controlPoint1 = Offset(p0.dx + dx * 0.45, p0.dy);
        var controlPoint2 = Offset(p1.dx - dx * 0.45, p1.dy);
        pathLine.cubicTo(
          controlPoint1.dx, controlPoint1.dy,
          controlPoint2.dx, controlPoint2.dy,
          p1.dx, p1.dy,
        );
      }

      canvas.drawPath(pathLine, paintLine);
    }

    for (int i = 0; i < labels.length; i++) {
      double x = paddingLeft + dx * i;

      textPainter.text = TextSpan(
        text: labels[i],
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, size.height - paddingBottom + 6),
      );
    }

    final paintAxis = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawLine(
      Offset(paddingLeft, size.height - paddingBottom),
      Offset(size.width - paddingRight + 6, size.height - paddingBottom),
      paintAxis,
    );
    canvas.drawLine(
      Offset(size.width - paddingRight + 6, size.height - paddingBottom),
      Offset(size.width - paddingRight, size.height - paddingBottom - 3),
      paintAxis,
    );
    canvas.drawLine(
      Offset(size.width - paddingRight + 6, size.height - paddingBottom),
      Offset(size.width - paddingRight, size.height - paddingBottom + 3),
      paintAxis,
    );

    canvas.drawLine(
      Offset(paddingLeft, size.height - paddingBottom),
      Offset(paddingLeft, paddingTop - 6),
      paintAxis,
    );
    canvas.drawLine(
      Offset(paddingLeft, paddingTop - 6),
      Offset(paddingLeft - 3, paddingTop),
      paintAxis,
    );
    canvas.drawLine(
      Offset(paddingLeft, paddingTop - 6),
      Offset(paddingLeft + 3, paddingTop),
      paintAxis,
    );
  }

  @override
  bool shouldRepaint(covariant PatientTrendsPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.labels != labels;
  }
}

class DepartmentDistributionPainter extends CustomPainter {
  final Map<String, double> departmentPercentages;
  final Map<String, Color> departmentColors;

  DepartmentDistributionPainter({
    required this.departmentPercentages,
    required this.departmentColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    double totalPercent = departmentPercentages.values.fold(0.0, (acc, val) => acc + val);
    if (totalPercent == 0.0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 10;
    const strokeWidth = 16.0;

    final rect = Rect.fromCircle(center: center, radius: radius);
    double startAngle = -pi / 2;

    departmentPercentages.forEach((dept, percentage) {
      if (percentage <= 0.0) return;

      final sweepAngle = 2 * pi * (percentage / totalPercent);
      final color = departmentColors[dept] ?? Colors.grey;

      final paintArc = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true;

      double gap = departmentPercentages.values.where((v) => v > 0).length > 1 ? 0.06 : 0.0;

      canvas.drawArc(
        rect,
        startAngle + gap / 2,
        sweepAngle - gap,
        false,
        paintArc,
      );

      startAngle += sweepAngle;
    });
  }

  @override
  bool shouldRepaint(covariant DepartmentDistributionPainter oldDelegate) {
    return oldDelegate.departmentPercentages != departmentPercentages;
  }
}
