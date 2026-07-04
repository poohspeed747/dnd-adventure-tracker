// lib/node_card.dart
import 'package:flutter/material.dart';
import 'models.dart';
import '../graph_provider.dart';

class NodeCard extends StatelessWidget {
  final AdventureNode node;
  final bool isSelected;
  final bool isConnectingFrom;
  final VoidCallback onTap;
  final void Function(DragUpdateDetails) onDrag;
  final VoidCallback onDragEnd;

  const NodeCard({
    super.key,
    required this.node,
    required this.isSelected,
    this.isConnectingFrom = false,
    required this.onTap,
    required this.onDrag,
    required this.onDragEnd,
  });

  // ─── State theming ─────────────────────────────────────────────────────────

  Color get _accent {
    switch (node.state) {
      case NodeState.unvisited:
        return const Color(0xFF546E7A); // blue-grey
      case NodeState.available:
        return const Color(0xFF1565C0); // royal blue
      case NodeState.current:
        return const Color(0xFFE65100); // deep orange / gold
      case NodeState.visited:
        return const Color(0xFF2E7D32); // forest green
      case NodeState.locked:
        return const Color(0xFF6A1B9A); // purple
    }
  }

  IconData get _stateIcon {
    switch (node.state) {
      case NodeState.unvisited:
        return Icons.help_outline_rounded;
      case NodeState.available:
        return Icons.arrow_circle_right_outlined;
      case NodeState.current:
        return Icons.my_location_rounded;
      case NodeState.visited:
        return Icons.check_circle_outline_rounded;
      case NodeState.locked:
        return Icons.lock_outline_rounded;
    }
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final borderColor = isConnectingFrom
        ? Colors.yellowAccent
        : isSelected
            ? Colors.white
            : _accent;
    final borderWidth = (isSelected || isConnectingFrom) ? 2.5 : 1.5;

    return GestureDetector(
      onTap: onTap,
      onPanUpdate: onDrag,
      onPanEnd: (_) => onDragEnd(),
      child: Container(
        width: GraphProvider.nodeWidth,
        height: GraphProvider.nodeHeight,
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: borderWidth),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: _accent.withOpacity(0.55),
                blurRadius: 16,
                spreadRadius: 2,
              )
            else
              const BoxShadow(
                color: Colors.black45,
                blurRadius: 6,
                offset: Offset(2, 3),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header bar ──────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: _accent,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
              ),
              child: Row(
                children: [
                  Icon(_stateIcon, color: Colors.white, size: 13),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      node.id,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 9,
                        fontFamily: 'monospace',
                        letterSpacing: 0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (node.entryConditions.isNotEmpty)
                    Tooltip(
                      message: 'Has entry conditions',
                      child: const Icon(
                        Icons.vpn_key_outlined,
                        color: Colors.white60,
                        size: 11,
                      ),
                    ),
                  if (node.notes.isNotEmpty)
                    Tooltip(
                      message: 'Has DM notes',
                      child: const Padding(
                        padding: EdgeInsets.only(left: 3),
                        child: Icon(Icons.sticky_note_2_outlined,
                            color: Colors.white60, size: 11),
                      ),
                    ),
                ],
              ),
            ),
            // ── Body ────────────────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(9, 7, 9, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      node.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (node.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        node.description,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 9.5,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const Spacer(),
                    // State pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _accent.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(
                          color: _accent.withOpacity(0.4),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        nodeStateLabels[node.state] ?? '',
                        style: TextStyle(
                          color: _accent.withOpacity(0.9),
                          fontSize: 8.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}