// lib/graph_provider.dart
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'models.dart';

// Conditional import: picks storage_web on browser, storage_native everywhere else.
import 'storage_native.dart'
    if (dart.library.html) 'storage_web.dart' as storage;

enum InteractionMode { select, addNode, connect }

class GraphProvider extends ChangeNotifier {
  final List<AdventureNode> nodes = [];
  final List<NodeEdge> edges = [];
  final _uuid = const Uuid();

  String? _selectedNodeId;
  String? _selectedEdgeId;
  InteractionMode _mode = InteractionMode.select;
  String? connectingFromId;

  static const double nodeWidth = 210.0;
  static const double nodeHeight = 130.0;
  static const String _saveKey = 'adventure_map';

  // ─── Getters ──────────────────────────────────────────────────────────────

  String? get selectedNodeId => _selectedNodeId;
  String? get selectedEdgeId => _selectedEdgeId;
  InteractionMode get mode => _mode;

  AdventureNode? get selectedNode {
    if (_selectedNodeId == null) return null;
    for (final n in nodes) {
      if (n.id == _selectedNodeId) return n;
    }
    return null;
  }

  NodeEdge? get selectedEdge {
    if (_selectedEdgeId == null) return null;
    for (final e in edges) {
      if (e.id == _selectedEdgeId) return e;
    }
    return null;
  }

  AdventureNode? nodeById(String id) {
    for (final n in nodes) {
      if (n.id == id) return n;
    }
    return null;
  }

  List<NodeEdge> edgesFrom(String nodeId) =>
      edges.where((e) => e.fromNodeId == nodeId).toList();

  List<NodeEdge> edgesTo(String nodeId) =>
      edges.where((e) => e.toNodeId == nodeId).toList();

  // ─── Mode & Selection ─────────────────────────────────────────────────────

  void setMode(InteractionMode m) {
    _mode = m;
    if (m != InteractionMode.connect) connectingFromId = null;
    notifyListeners();
  }

  void selectNode(String id) {
    if (_mode == InteractionMode.connect) {
      if (connectingFromId == null) {
        connectingFromId = id;
        notifyListeners();
      } else if (connectingFromId != id) {
        _createEdge(connectingFromId!, id);
        connectingFromId = null;
        _mode = InteractionMode.select;
      }
      return;
    }
    _selectedNodeId = id;
    _selectedEdgeId = null;
    notifyListeners();
  }

  void selectEdge(String id) {
    _selectedEdgeId = id;
    _selectedNodeId = null;
    notifyListeners();
  }

  void clearSelection() {
    _selectedNodeId = null;
    _selectedEdgeId = null;
    if (_mode == InteractionMode.connect) {
      connectingFromId = null;
      _mode = InteractionMode.select;
    }
    notifyListeners();
  }

  // ─── Node Mutations ───────────────────────────────────────────────────────

  void addNode(Offset position) {
    final id = 'N-${_uuid.v4().substring(0, 6).toUpperCase()}';
    nodes.add(AdventureNode(id: id, position: position));
    _selectedNodeId = id;
    _selectedEdgeId = null;
    _mode = InteractionMode.select;
    notifyListeners();
    _autoSave();
  }

  void updateNodePosition(String id, Offset delta) {
    final node = nodeById(id);
    if (node == null) return;
    node.position = Offset(
      (node.position.dx + delta.dx).clamp(0.0, 4800.0),
      (node.position.dy + delta.dy).clamp(0.0, 3870.0),
    );
    notifyListeners();
  }

  void finishDrag() => _autoSave();

  void updateNode({
    String? name,
    String? description,
    String? entryConditions,
    String? notes,
    NodeState? state,
  }) {
    final node = selectedNode;
    if (node == null) return;
    if (name != null) node.name = name;
    if (description != null) node.description = description;
    if (entryConditions != null) node.entryConditions = entryConditions;
    if (notes != null) node.notes = notes;
    if (state != null) node.state = state;
    notifyListeners();
    _autoSave();
  }

  void updateEdge({String? label, String? condition}) {
    final edge = selectedEdge;
    if (edge == null) return;
    if (label != null) edge.label = label;
    if (condition != null) edge.condition = condition;
    notifyListeners();
    _autoSave();
  }

  void deleteSelected() {
    if (_selectedNodeId != null) {
      edges.removeWhere(
        (e) => e.fromNodeId == _selectedNodeId || e.toNodeId == _selectedNodeId,
      );
      nodes.removeWhere((n) => n.id == _selectedNodeId);
      _selectedNodeId = null;
    } else if (_selectedEdgeId != null) {
      edges.removeWhere((e) => e.id == _selectedEdgeId);
      _selectedEdgeId = null;
    }
    notifyListeners();
    _autoSave();
  }

  void clearAll() {
    nodes.clear();
    edges.clear();
    _selectedNodeId = null;
    _selectedEdgeId = null;
    _mode = InteractionMode.select;
    connectingFromId = null;
    notifyListeners();
    _autoSave();
  }

  void _createEdge(String fromId, String toId) {
    final exists = edges.any(
      (e) => e.fromNodeId == fromId && e.toNodeId == toId,
    );
    if (!exists) {
      edges.add(NodeEdge(
        id: 'E-${_uuid.v4().substring(0, 6).toUpperCase()}',
        fromNodeId: fromId,
        toNodeId: toId,
      ));
    }
    _selectedNodeId = null;
    notifyListeners();
    _autoSave();
  }

  // ─── Save / Load ──────────────────────────────────────────────────────────

  Map<String, dynamic> _toJson() => {
    'nodes': nodes.map((n) => n.toJson()).toList(),
    'edges': edges.map((e) => e.toJson()).toList(),
  };

  void _fromJson(Map<String, dynamic> json) {
    nodes.clear();
    edges.clear();
    for (final n in (json['nodes'] as List<dynamic>? ?? [])) {
      nodes.add(AdventureNode.fromJson(n as Map<String, dynamic>));
    }
    for (final e in (json['edges'] as List<dynamic>? ?? [])) {
      edges.add(NodeEdge.fromJson(e as Map<String, dynamic>));
    }
    _selectedNodeId = null;
    _selectedEdgeId = null;
    notifyListeners();
  }

  void _autoSave() {
    storage.autoSave(_saveKey, jsonEncode(_toJson()));
  }

  bool tryLoadAutoSave() {
    try {
      final data = storage.tryLoadAutoSave(_saveKey);
      if (data != null) {
        _fromJson(jsonDecode(data) as Map<String, dynamic>);
        return true;
      }
    } catch (_) {}
    return false;
  }

  /// Save: on web triggers download, on native writes file via picker.
  Future<String?> saveMap() async {
    final json = jsonEncode(_toJson());
    return storage.saveToFile('adventure_map.json', json);
  }

  /// Load: on web opens file upload picker, on native uses FilePicker.
  Future<bool> loadMap() async {
    try {
      String? data;

      // On web, storage.loadFromFile() handles everything via dart:html.
      // On native, we use FilePicker for a proper OS dialog.
      if (identical(0, 0.0)) {
        // This branch is never taken; it just satisfies the import.
        data = await storage.loadFromFile();
      } else {
        // Try native file picker first; fall back to storage implementation.
        try {
          final result = await FilePicker.platform.pickFiles(
            type: FileType.custom,
            allowedExtensions: ['json'],
            withData: true,
          );
          if (result != null && result.files.single.bytes != null) {
            data = String.fromCharCodes(result.files.single.bytes!);
          }
        } catch (_) {
          data = await storage.loadFromFile();
        }
      }

      if (data == null) return false;
      _fromJson(jsonDecode(data) as Map<String, dynamic>);
      _autoSave();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Populate a quick demo adventure so the app isn't blank on first run.
  void loadDemo() {
    clearAll();
    final demoNodes = [
      AdventureNode(
        id: 'N-START',
        name: 'Tavern — The Rusty Flagon',
        description: 'The party receives their quest hook from innkeeper Marta.',
        entryConditions: 'Session start',
        state: NodeState.visited,
        position: const Offset(120, 240),
      ),
      AdventureNode(
        id: 'N-ROAD',
        name: 'King\'s Road',
        description: 'A long journey through the countryside. Possible random encounters.',
        entryConditions: 'Leave the Tavern',
        state: NodeState.current,
        position: const Offset(440, 120),
      ),
      AdventureNode(
        id: 'N-FOREST',
        name: 'Darkwood Forest',
        description: 'An ancient wood rumoured to be haunted. Shortcut to the dungeon.',
        entryConditions: 'Leave the Tavern',
        notes: 'DC 15 Survival to navigate without getting lost.',
        state: NodeState.available,
        position: const Offset(440, 360),
      ),
      AdventureNode(
        id: 'N-VILLAGE',
        name: 'Millhaven Village',
        description: 'Friendly village. Rest, resupply, and a clue from the blacksmith.',
        entryConditions: 'Travel the King\'s Road',
        state: NodeState.available,
        position: const Offset(760, 120),
      ),
      AdventureNode(
        id: 'N-RUINS',
        name: 'Ancient Ruins',
        description: 'Crumbling tower with a hidden entrance to the dungeon below.',
        entryConditions: 'Navigate the Darkwood Forest',
        state: NodeState.unvisited,
        position: const Offset(760, 360),
      ),
      AdventureNode(
        id: 'N-DUNGEON',
        name: 'Dungeon of the Lich King',
        description: 'Final dungeon. Multi-level. Boss fight at the end.',
        entryConditions: 'Find Millhaven clue OR locate the Ancient Ruins entrance',
        notes: 'Lich has legendary resistances ×3. Scale HP for party size.',
        state: NodeState.locked,
        position: const Offset(1060, 240),
      ),
    ];
    for (final n in demoNodes) nodes.add(n);
    final demoEdges = [
      NodeEdge(id: 'E-001', fromNodeId: 'N-START', toNodeId: 'N-ROAD', label: 'Head north'),
      NodeEdge(id: 'E-002', fromNodeId: 'N-START', toNodeId: 'N-FOREST', label: 'Take shortcut'),
      NodeEdge(id: 'E-003', fromNodeId: 'N-ROAD', toNodeId: 'N-VILLAGE', label: 'Continue'),
      NodeEdge(id: 'E-004', fromNodeId: 'N-FOREST', toNodeId: 'N-RUINS', label: 'Emerge from forest', condition: 'DC 15 Survival success'),
      NodeEdge(id: 'E-005', fromNodeId: 'N-VILLAGE', toNodeId: 'N-DUNGEON', label: 'Follow map from blacksmith'),
      NodeEdge(id: 'E-006', fromNodeId: 'N-RUINS', toNodeId: 'N-DUNGEON', label: 'Enter hidden passage'),
    ];
    for (final e in demoEdges) edges.add(e);
    notifyListeners();
    _autoSave();
  }
}