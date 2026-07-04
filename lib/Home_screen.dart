// lib/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'graph_provider.dart';
import 'graph_canvas.dart';
import 'inspector_panel.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: Column(
        children: [
          _Toolbar(),
          Expanded(
            child: Row(
              children: const [
                Expanded(child: GraphCanvas()),
                InspectorPanel(),
              ],
            ),
          ),
          _StatusBar(),
        ],
      ),
    );
  }
}

// ─── Toolbar ─────────────────────────────────────────────────────────────────

class _Toolbar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<GraphProvider>(
      builder: (context, provider, _) {
        return Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: const BoxDecoration(
            color: Color(0xFF161B22),
            border: Border(bottom: BorderSide(color: Color(0xFF30363D))),
          ),
          child: Row(
            children: [
              // Branding
              const Icon(Icons.auto_stories, color: Color(0xFFD4AF37), size: 20),
              const SizedBox(width: 8),
              const Text(
                'D&D Adventure Map',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(width: 14),
              _divider(),
              const SizedBox(width: 10),

              // Mode group
              _ModeBtn(
                icon: Icons.open_with_rounded,
                label: 'Select',
                tooltip: 'Select & Move  (Esc)',
                active: provider.mode == InteractionMode.select,
                onTap: () => provider.setMode(InteractionMode.select),
              ),
              const SizedBox(width: 4),
              _ModeBtn(
                icon: Icons.add_location_alt_outlined,
                label: 'Add Node',
                tooltip: 'Add Node  (A) — then click canvas',
                active: provider.mode == InteractionMode.addNode,
                onTap: () => provider.setMode(InteractionMode.addNode),
              ),
              const SizedBox(width: 4),
              _ModeBtn(
                icon: Icons.account_tree_outlined,
                label: 'Connect',
                tooltip: 'Connect Nodes  (C) — click source then target',
                active: provider.mode == InteractionMode.connect,
                onTap: () => provider.setMode(InteractionMode.connect),
              ),
              const SizedBox(width: 10),
              _divider(),
              const SizedBox(width: 10),

              // Delete (only when something is selected)
              AnimatedOpacity(
                opacity: (provider.selectedNodeId != null ||
                        provider.selectedEdgeId != null)
                    ? 1
                    : 0.25,
                duration: const Duration(milliseconds: 150),
                child: _ModeBtn(
                  icon: Icons.delete_outline_rounded,
                  label: 'Delete',
                  tooltip: 'Delete selected  (Del)',
                  active: false,
                  accentColor: Colors.redAccent,
                  onTap: provider.deleteSelected,
                ),
              ),

              const Spacer(),

              // Demo / New / Save / Load
              _ModeBtn(
                icon: Icons.auto_fix_high_outlined,
                label: 'Load Demo',
                tooltip: 'Load a sample adventure to get started',
                active: false,
                accentColor: const Color(0xFFD4AF37),
                onTap: () => _confirmAndRun(
                  context,
                  'Load Demo Adventure?',
                  'This will replace your current map.',
                  provider.loadDemo,
                ),
              ),
              const SizedBox(width: 4),
              _ModeBtn(
                icon: Icons.fiber_new_outlined,
                label: 'New',
                tooltip: 'Clear everything and start fresh',
                active: false,
                onTap: () => _confirmAndRun(
                  context,
                  'Start New Map?',
                  'This will clear all nodes and paths.',
                  provider.clearAll,
                ),
              ),
              const SizedBox(width: 4),
              _divider(),
              const SizedBox(width: 4),
              _ModeBtn(
                icon: Icons.save_outlined,
                label: 'Save',
                tooltip: 'Save map to a JSON file',
                active: false,
                onTap: () async {
                  final result = await provider.saveMap();
                  if (context.mounted) {
                    _snack(
                      context,
                      result != null
                          ? 'Saved: $result'
                          : 'Save cancelled or failed',
                      error: result == null,
                    );
                  }
                },
              ),
              const SizedBox(width: 4),
              _ModeBtn(
                icon: Icons.folder_open_outlined,
                label: 'Load',
                tooltip: 'Load map from a JSON file',
                active: false,
                onTap: () async {
                  final ok = await provider.loadMap();
                  if (context.mounted) {
                    _snack(
                      context,
                      ok ? 'Map loaded!' : 'Load cancelled or failed',
                      error: !ok,
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _divider() => const SizedBox(
    height: 24,
    child: VerticalDivider(color: Color(0xFF30363D), width: 1),
  );

  void _confirmAndRun(
    BuildContext ctx,
    String title,
    String message,
    VoidCallback action,
  ) {
    showDialog(
      context: ctx,
      builder: (_) => _DarkDialog(
        title: title,
        content: Text(
          message,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              action();
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _showFileDialog(
    BuildContext ctx,
    String title,
    String defaultPath,
    void Function(String) onConfirm,
  ) {
    final ctrl = TextEditingController(text: defaultPath);
    showDialog(
      context: ctx,
      builder: (_) => _DarkDialog(
        title: title,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'File path (relative to where you run the app, or absolute):',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: ctrl,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                filled: true,
                fillColor: Color(0xFF0D1117),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF30363D)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF1F6FEB)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm(ctrl.text.trim());
            },
            child: Text(title),
          ),
        ],
      ),
    );
  }

  void _snack(BuildContext ctx, String msg, {bool error = false}) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? Colors.red.shade800 : null,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

// ─── Mode button ──────────────────────────────────────────────────────────────

class _ModeBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final String tooltip;
  final bool active;
  final Color? accentColor;
  final VoidCallback onTap;

  const _ModeBtn({
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.active,
    required this.onTap,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = active
        ? Colors.white
        : accentColor ?? Colors.white60;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: active ? const Color(0xFF1F6FEB) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: active
                ? Border.all(color: const Color(0xFF388BFD))
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 15),
              const SizedBox(width: 5),
              Text(label, style: TextStyle(color: color, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Status bar ───────────────────────────────────────────────────────────────

class _StatusBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<GraphProvider>(
      builder: (context, provider, _) {
        final hint = switch (provider.mode) {
          InteractionMode.select => 'Click node to select  ·  Drag to move  ·  Del to delete',
          InteractionMode.addNode => '✦  Click anywhere on the canvas to place a new node',
          InteractionMode.connect => provider.connectingFromId == null
              ? '⇢  Click the SOURCE node…'
              : '⇢  Now click the TARGET node to create a path',
        };
        return Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: const BoxDecoration(
            color: Color(0xFF161B22),
            border: Border(top: BorderSide(color: Color(0xFF30363D))),
          ),
          child: Row(
            children: [
              Text(
                hint,
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
              const Spacer(),
              Text(
                '${provider.nodes.length} nodes  ·  ${provider.edges.length} paths',
                style: const TextStyle(color: Colors.white24, fontSize: 11),
              ),
              const SizedBox(width: 12),
              const Text(
                'Auto-saved to adventure_map.json',
                style: TextStyle(color: Colors.white12, fontSize: 10),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Shared dark dialog ───────────────────────────────────────────────────────

class _DarkDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget> actions;

  const _DarkDialog({
    required this.title,
    required this.content,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1F2937),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Color(0xFF30363D)),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 15)),
      content: content,
      actions: actions,
    );
  }
}