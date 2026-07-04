// lib/models.dart
import 'dart:ui';

enum NodeState { unvisited, available, current, visited, locked }

const nodeStateLabels = {
  NodeState.unvisited: 'Unvisited',
  NodeState.available: 'Available',
  NodeState.current: 'Current Location',
  NodeState.visited: 'Visited',
  NodeState.locked: 'Locked',
};

class AdventureNode {
  final String id;
  String name;
  String description;
  String entryConditions;
  String notes;
  NodeState state;
  Offset position;

  AdventureNode({
    required this.id,
    this.name = 'New Location',
    this.description = '',
    this.entryConditions = '',
    this.notes = '',
    this.state = NodeState.unvisited,
    this.position = const Offset(200, 200),
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'entryConditions': entryConditions,
    'notes': notes,
    'state': state.index,
    'x': position.dx,
    'y': position.dy,
  };

  factory AdventureNode.fromJson(Map<String, dynamic> json) => AdventureNode(
    id: json['id'] as String,
    name: (json['name'] as String?) ?? 'Unknown',
    description: (json['description'] as String?) ?? '',
    entryConditions: (json['entryConditions'] as String?) ?? '',
    notes: (json['notes'] as String?) ?? '',
    state: NodeState.values[(json['state'] as int?) ?? 0],
    position: Offset(
      (json['x'] as num?)?.toDouble() ?? 200,
      (json['y'] as num?)?.toDouble() ?? 200,
    ),
  );
}

class NodeEdge {
  final String id;
  String fromNodeId;
  String toNodeId;
  String label;
  String condition;

  NodeEdge({
    required this.id,
    required this.fromNodeId,
    required this.toNodeId,
    this.label = '',
    this.condition = '',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'fromNodeId': fromNodeId,
    'toNodeId': toNodeId,
    'label': label,
    'condition': condition,
  };

  factory NodeEdge.fromJson(Map<String, dynamic> json) => NodeEdge(
    id: json['id'] as String,
    fromNodeId: json['fromNodeId'] as String,
    toNodeId: json['toNodeId'] as String,
    label: (json['label'] as String?) ?? '',
    condition: (json['condition'] as String?) ?? '',
  );
}