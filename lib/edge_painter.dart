// lib/edge_painter.dart
import 'package:flutter/material.dart';
import 'models.dart';
import '../graph_provider.dart';

class EdgePainter extends CustomPainter {
  final List<AdventureNode> nodes;
  final List<NodeEdge> edges;
  final String? selectedEdgeId;
  final String? connectingFromId;

  const EdgePainter({
    required this.nodes,
    required this.edges,
    this.selectedEdgeId,
    this.connectingFromId,
  });

  static const double nw = GraphProvider.nodeWidth;
  static const double nh = GraphProvider.nodeHeight;

  Offset _outPort(AdventureNode n) =>
      Offset(n.position.dx + nw, n.position.dy + nh / 2);

  Offset _inPort(AdventureNode n) =>
      Offset(n.position.dx, n.position.dy + nh / 2);

  AdventureNode? _find(String id) {
    for (final n in nodes) {
      if (n.id == id) return n;
    }
    return null;
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Highlight the node we're connecting from with a pulsing ring
    if (connectingFromId != null) {
      final src = _find(connectingFromId!);
      if (src != null) {
        final paint = Paint()
          ..color = Colors.yellowAccent.withOpacity(0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(src.position.dx - 4, src.position.dy - 4, nw + 8, nh + 8),
            const Radius.circular(12),
          ),
          paint,
        );
      }
    }

    for (final edge in edges) {
      final from = _find(edge.fromNodeId);
      final to = _find(edge.toNodeId);
      if (from == null || to == null) continue;

      final isSelected = edge.id == selectedEdgeId;
      final color = isSelected ? Colors.amber : const Color(0xFF58A6FF);
      final width = isSelected ? 2.5 : 1.6;

      _drawEdge(canvas, _outPort(from), _inPort(to), color, width, edge.label);
    }
  }

  void _drawEdge(
    Canvas canvas,
    Offset from,
    Offset to,
    Color color,
    double strokeWidth,
    String label,
  ) {
    final dx = ((to.dx - from.dx).abs() * 0.55).clamp(60.0, 220.0);
    final cp1 = Offset(from.dx + dx, from.dy);
    final cp2 = Offset(to.dx - dx, to.dy);

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(from.dx, from.dy)
      ..cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, to.dx, to.dy);
    canvas.drawPath(path, linePaint);

    // Arrowhead
    _drawArrow(canvas, cp2, to, color, strokeWidth > 2 ? 11.0 : 9.0);

    // Label at midpoint
    if (label.isNotEmpty) {
      final mid = _bezierAt(from, cp1, cp2, to, 0.5);
      _drawLabel(canvas, mid, label);
    }
  }

  void _drawArrow(Canvas canvas, Offset cp, Offset tip, Color color, double size) {
    final dir = tip - cp;
    final len = dir.distance;
    if (len < 1e-3) return;
    final u = dir / len;
    final perp = Offset(-u.dy, u.dx);
    final base = tip - u * size;

    final paint = Paint()..color = color..style = PaintingStyle.fill;
    canvas.drawPath(
      Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo((base + perp * size * 0.45).dx, (base + perp * size * 0.45).dy)
        ..lineTo((base - perp * size * 0.45).dx, (base - perp * size * 0.45).dy)
        ..close(),
      paint,
    );
  }

  Offset _bezierAt(Offset p0, Offset p1, Offset p2, Offset p3, double t) {
    final mt = 1 - t;
    return Offset(
      mt * mt * mt * p0.dx +
          3 * mt * mt * t * p1.dx +
          3 * mt * t * t * p2.dx +
          t * t * t * p3.dx,
      mt * mt * mt * p0.dy +
          3 * mt * mt * t * p1.dy +
          3 * mt * t * t * p2.dy +
          t * t * t * p3.dy,
    );
  }

  void _drawLabel(Canvas canvas, Offset center, String text) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Color(0xFFCDD9E5),
          fontSize: 10,
          fontWeight: FontWeight.w500,
          shadows: [Shadow(color: Colors.black, blurRadius: 6)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    // Background pill
    final bgRect = Rect.fromCenter(
      center: center,
      width: tp.width + 12,
      height: tp.height + 6,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bgRect, const Radius.circular(4)),
      Paint()..color = const Color(0xFF1C2128),
    );
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(EdgePainter old) => true;
}