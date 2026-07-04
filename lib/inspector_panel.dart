// lib/inspector_panel.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../graph_provider.dart';
import 'models.dart';

class InspectorPanel extends StatefulWidget {
  const InspectorPanel({super.key});

  @override
  State<InspectorPanel> createState() => _InspectorPanelState();
}

class _InspectorPanelState extends State<InspectorPanel> {
  // Node controllers
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _condCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  // Edge controllers
  final _eLabelCtrl = TextEditingController();
  final _eCondCtrl = TextEditingController();

  String? _loadedNodeId;
  String? _loadedEdgeId;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _condCtrl.dispose();
    _notesCtrl.dispose();
    _eLabelCtrl.dispose();
    _eCondCtrl.dispose();
    super.dispose();
  }

  void _syncNode(AdventureNode node) {
    if (_loadedNodeId == node.id) return;
    _loadedNodeId = node.id;
    _loadedEdgeId = null;
    _nameCtrl.text = node.name;
    _descCtrl.text = node.description;
    _condCtrl.text = node.entryConditions;
    _notesCtrl.text = node.notes;
  }

  void _syncEdge(NodeEdge edge) {
    if (_loadedEdgeId == edge.id) return;
    _loadedEdgeId = edge.id;
    _loadedNodeId = null;
    _eLabelCtrl.text = edge.label;
    _eCondCtrl.text = edge.condition;
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Consumer<GraphProvider>(
      builder: (context, provider, _) {
        final node = provider.selectedNode;
        final edge = provider.selectedEdge;

        if (node != null) {
          _syncNode(node);
          return _nodePanel(context, provider, node);
        }
        if (edge != null) {
          _syncEdge(edge);
          return _edgePanel(context, provider, edge);
        }
        return _emptyPanel();
      },
    );
  }

  // ─── Empty state ───────────────────────────────────────────────────────────

  Widget _emptyPanel() {
    return Container(
      width: 290,
      color: const Color(0xFF161B22),
      child: Column(
        children: [
          _sectionHeader('INSPECTOR', null),
          const Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.touch_app_outlined, color: Colors.white24, size: 44),
                  SizedBox(height: 10),
                  Text(
                    'Select a node or path\nto view details',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white24, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          // Legend
          _legend(),
        ],
      ),
    );
  }

  Widget _legend() {
    const states = [
      (NodeState.unvisited, Color(0xFF546E7A), 'Unvisited'),
      (NodeState.available, Color(0xFF1565C0), 'Available'),
      (NodeState.current, Color(0xFFE65100), 'Current'),
      (NodeState.visited, Color(0xFF2E7D32), 'Visited'),
      (NodeState.locked, Color(0xFF6A1B9A), 'Locked'),
    ];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFF30363D))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'STATE LEGEND',
            style: TextStyle(
              color: Colors.white30,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          ...states.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: s.$2,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    s.$3,
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Node inspector ────────────────────────────────────────────────────────

  Widget _nodePanel(
    BuildContext context,
    GraphProvider provider,
    AdventureNode node,
  ) {
    return Container(
      width: 290,
      color: const Color(0xFF161B22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionHeader('NODE', () => provider.deleteSelected()),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
              children: [
                // ID badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1117),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFF30363D)),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'ID  ',
                        style: TextStyle(
                          color: Colors.white30,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        node.id,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _label('Name'),
                _field(_nameCtrl, 1, (v) => provider.updateNode(name: v)),
                const SizedBox(height: 12),
                _label('State'),
                _stateDropdown(provider, node),
                const SizedBox(height: 12),
                _label('Description'),
                _field(
                  _descCtrl,
                  3,
                  (v) => provider.updateNode(description: v),
                  hint: 'What does the party see/experience here?',
                ),
                const SizedBox(height: 12),
                _label('Entry Conditions'),
                _field(
                  _condCtrl,
                  3,
                  (v) => provider.updateNode(entryConditions: v),
                  hint: 'What must happen before entry is possible?',
                ),
                const SizedBox(height: 12),
                _label('DM Notes'),
                _field(
                  _notesCtrl,
                  4,
                  (v) => provider.updateNode(notes: v),
                  hint: 'Secret DM notes, encounter details…',
                ),
                const SizedBox(height: 16),
                // Connections list
                if (provider.edgesFrom(node.id).isNotEmpty) ...[
                  _label('Paths FROM Here'),
                  ...provider.edgesFrom(node.id).map((e) {
                    final target = provider.nodeById(e.toNodeId);
                    return _edgeTile(
                      '→  ${target?.name ?? e.toNodeId}',
                      e.label.isNotEmpty ? e.label : null,
                      () => provider.selectEdge(e.id),
                    );
                  }),
                  const SizedBox(height: 12),
                ],
                if (provider.edgesTo(node.id).isNotEmpty) ...[
                  _label('Paths TO Here'),
                  ...provider.edgesTo(node.id).map((e) {
                    final src = provider.nodeById(e.fromNodeId);
                    return _edgeTile(
                      '←  ${src?.name ?? e.fromNodeId}',
                      e.label.isNotEmpty ? e.label : null,
                      () => provider.selectEdge(e.id),
                    );
                  }),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Edge inspector ────────────────────────────────────────────────────────

  Widget _edgePanel(
    BuildContext context,
    GraphProvider provider,
    NodeEdge edge,
  ) {
    final from = provider.nodeById(edge.fromNodeId);
    final to = provider.nodeById(edge.toNodeId);

    return Container(
      width: 290,
      color: const Color(0xFF161B22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionHeader('PATH', () => provider.deleteSelected()),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF0D1117),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF30363D)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      from?.name ?? edge.fromNodeId,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: Color(0xFF58A6FF),
                      size: 16,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      to?.name ?? edge.toNodeId,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                      textAlign: TextAlign.right,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
              children: [
                _label('Path Label'),
                _field(
                  _eLabelCtrl,
                  1,
                  (v) => provider.updateEdge(label: v),
                  hint: 'e.g.  "Cross the old bridge"',
                ),
                const SizedBox(height: 12),
                _label('Travel Condition'),
                _field(
                  _eCondCtrl,
                  4,
                  (v) => provider.updateEdge(condition: v),
                  hint: 'Requirements to use this path…',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Shared UI helpers ─────────────────────────────────────────────────────

  Widget _sectionHeader(String title, VoidCallback? onDelete) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF1F2937),
        border: Border(bottom: BorderSide(color: Color(0xFF30363D))),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const Spacer(),
          if (onDelete != null)
            InkWell(
              onTap: onDelete,
              borderRadius: BorderRadius.circular(4),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.redAccent,
                  size: 17,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(
      text,
      style: const TextStyle(
        color: Colors.white38,
        fontSize: 9.5,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.1,
      ),
    ),
  );

  Widget _field(
    TextEditingController ctrl,
    int maxLines,
    void Function(String) onChanged, {
    String? hint,
  }) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      onChanged: onChanged,
      style: const TextStyle(
        color: Color(0xFFCDD9E5),
        fontSize: 12,
        height: 1.4,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white12, fontSize: 11),
        filled: true,
        fillColor: const Color(0xFF0D1117),
        contentPadding: const EdgeInsets.all(9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: const BorderSide(color: Color(0xFF30363D)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: const BorderSide(color: Color(0xFF30363D)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: const BorderSide(color: Color(0xFF1F6FEB), width: 1.5),
        ),
      ),
    );
  }

  Widget _stateDropdown(GraphProvider provider, AdventureNode node) {
    return DropdownButtonFormField<NodeState>(
      value: node.state,
      dropdownColor: const Color(0xFF1F2937),
      style: const TextStyle(color: Color(0xFFCDD9E5), fontSize: 12),
      decoration: const InputDecoration(
        filled: true,
        fillColor: Color(0xFF0D1117),
        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        border: OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF30363D)),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF30363D)),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF1F6FEB), width: 1.5),
        ),
      ),
      items: NodeState.values
          .map(
            (s) => DropdownMenuItem(
              value: s,
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _stateColor(s),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(nodeStateLabels[s] ?? ''),
                ],
              ),
            ),
          )
          .toList(),
      onChanged: (s) {
        if (s != null) provider.updateNode(state: s);
      },
    );
  }

  Color _stateColor(NodeState s) {
    switch (s) {
      case NodeState.unvisited:
        return const Color(0xFF546E7A);
      case NodeState.available:
        return const Color(0xFF1565C0);
      case NodeState.current:
        return const Color(0xFFE65100);
      case NodeState.visited:
        return const Color(0xFF2E7D32);
      case NodeState.locked:
        return const Color(0xFF6A1B9A);
    }
  }

  Widget _edgeTile(String label, String? sub, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        margin: const EdgeInsets.only(bottom: 5),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1117),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFF30363D)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Color(0xFF58A6FF), fontSize: 11),
            ),
            if (sub != null)
              Text(
                sub,
                style: const TextStyle(color: Colors.white38, fontSize: 9.5),
              ),
          ],
        ),
      ),
    );
  }
}