// lib/graph_canvas.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../graph_provider.dart';
import 'edge_painter.dart';
import 'node_card.dart';

class GraphCanvas extends StatefulWidget {
  const GraphCanvas({super.key});

  @override
  State<GraphCanvas> createState() => _GraphCanvasState();
}

class _GraphCanvasState extends State<GraphCanvas> {
  final _transformCtrl = TransformationController();
  final _focusNode = FocusNode();

  static const double _canvasW = 5000;
  static const double _canvasH = 4000;

  @override
  void initState() {
    super.initState();
    // Start viewport centred-ish
    _transformCtrl.value = Matrix4.identity()..translate(-60.0, -40.0);
  }

  @override
  void dispose() {
    _transformCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKey(GraphProvider provider, KeyEvent event) {
    if (event is! KeyDownEvent) return;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.delete:
      case LogicalKeyboardKey.backspace:
        // Only delete when not focused on a text field
        if (_focusNode.hasFocus) provider.deleteSelected();
        break;
      case LogicalKeyboardKey.escape:
        provider.clearSelection();
        provider.setMode(InteractionMode.select);
        break;
      case LogicalKeyboardKey.keyA:
        if (_focusNode.hasFocus) provider.setMode(InteractionMode.addNode);
        break;
      case LogicalKeyboardKey.keyC:
        if (_focusNode.hasFocus) provider.setMode(InteractionMode.connect);
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GraphProvider>(
      builder: (context, provider, _) {
        return KeyboardListener(
          focusNode: _focusNode,
          autofocus: true,
          onKeyEvent: (e) => _handleKey(provider, e),
          child: InteractiveViewer(
            transformationController: _transformCtrl,
            constrained: false,
            minScale: 0.15,
            maxScale: 3.0,
            boundaryMargin: const EdgeInsets.all(double.infinity),
            child: GestureDetector(
              onTapDown: (details) {
                if (provider.mode == InteractionMode.addNode) {
                  provider.addNode(
                    details.localPosition -
                        const Offset(
                          GraphProvider.nodeWidth / 2,
                          GraphProvider.nodeHeight / 2,
                        ),
                  );
                } else {
                  provider.clearSelection();
                }
              },
              child: SizedBox(
                width: _canvasW,
                height: _canvasH,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Dot grid background
                    CustomPaint(
                      size: const Size(_canvasW, _canvasH),
                      painter: _GridPainter(),
                    ),
                    // Edges (drawn behind nodes)
                    CustomPaint(
                      size: const Size(_canvasW, _canvasH),
                      painter: EdgePainter(
                        nodes: provider.nodes,
                        edges: provider.edges,
                        selectedEdgeId: provider.selectedEdgeId,
                        connectingFromId: provider.connectingFromId,
                      ),
                    ),
                    // Nodes
                    ...provider.nodes.map(
                      (node) => Positioned(
                        left: node.position.dx,
                        top: node.position.dy,
                        child: NodeCard(
                          key: ValueKey(node.id),
                          node: node,
                          isSelected: provider.selectedNodeId == node.id,
                          isConnectingFrom:
                              provider.connectingFromId == node.id,
                          onTap: () => provider.selectNode(node.id),
                          onDrag: (details) {
                            if (provider.mode != InteractionMode.connect) {
                              provider.updateNodePosition(
                                node.id,
                                details.delta,
                              );
                            }
                          },
                          onDragEnd: provider.finishDrag,
                        ),
                      ),
                    ),
                    // Cursor hint overlay
                    if (provider.mode == InteractionMode.addNode)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.blueAccent.withOpacity(0.25),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Dot-grid background ─────────────────────────────────────────────────────

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF0D1117),
    );

    // Minor dots
    final dotPaint = Paint()..color = const Color(0xFF21262D);
    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      for (double y = 0; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 1, dotPaint);
      }
    }

    // Major grid lines (every 200 px)
    final linePaint = Paint()
      ..color = const Color(0xFF1A2030)
      ..strokeWidth = 1;
    const major = 200.0;
    for (double x = 0; x < size.width; x += major) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }
    for (double y = 0; y < size.height; y += major) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => false;
}