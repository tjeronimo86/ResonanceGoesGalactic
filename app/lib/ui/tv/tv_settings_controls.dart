import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'tv_focusable.dart';

class TvSettingsList extends StatefulWidget {
  const TvSettingsList({super.key, required this.tvMode, required this.padding, required this.children});
  final bool tvMode;
  final EdgeInsetsGeometry padding;
  final List<Widget> children;

  @override
  State<TvSettingsList> createState() => _TvSettingsListState();
}

class _TvSettingsListState extends State<TvSettingsList> {
  @override
  void initState() {
    super.initState();
    FocusManager.instance.addEarlyKeyEventHandler(_handleKey);
  }

  bool _move(TraversalDirection direction, {bool controller = false}) {
    final focus = FocusManager.instance.primaryFocus;
    final focused = focus?.context;
    if (focused == null) return false;
    final horizontalGroup = focused.findAncestorWidgetOfExactType<TvHorizontalGroup>();
    if (horizontalGroup != null) {
      if (direction == TraversalDirection.left || direction == TraversalDirection.right) {
        final nodes = _sortByPosition(
          FocusManager.instance.rootScope.descendants.where((node) {
            final nodeContext = node.context;
            return nodeContext != null &&
                identical(nodeContext.findAncestorWidgetOfExactType<TvHorizontalGroup>(), horizontalGroup) &&
                node.canRequestFocus &&
                !node.skipTraversal;
          }).toList(),
          horizontal: true,
        );
        final current = nodes.indexOf(focus!);
        if (current < 0) return true;
        final target = current + (direction == TraversalDirection.right ? 1 : -1);
        if (target < 0) return false;
        if (target >= nodes.length) return true;
        final moved = focus.focusInDirection(direction);
        final nextContext = FocusManager.instance.primaryFocus?.context;
        if (!moved || !identical(nextContext?.findAncestorWidgetOfExactType<TvHorizontalGroup>(), horizontalGroup)) {
          nodes[target].requestFocus();
        }
        return true;
      }
      return _moveAdjacentTile(focused, direction);
    }
    if (direction == TraversalDirection.down || direction == TraversalDirection.up) {
      if (_moveAdjacentTile(focused, direction)) return true;
      return direction == TraversalDirection.down ? focus!.nextFocus() : focus!.previousFocus();
    }
    final right = direction == TraversalDirection.right;
    final tile = focused.findAncestorWidgetOfExactType<SwitchListTile>();
    if (tile?.onChanged != null) {
      tile!.onChanged!(right);
      return true;
    }
    final slider = focused.findAncestorWidgetOfExactType<Slider>();
    if (controller && slider?.onChanged != null) {
      final step = (slider!.max - slider.min) / (slider.divisions ?? 20);
      slider.onChanged!((slider.value + (right ? step : -step)).clamp(slider.min, slider.max));
      return true;
    }
    return false;
  }

  List<FocusNode> _sortByPosition(List<FocusNode> nodes, {bool horizontal = false}) {
    Rect? bounds(FocusNode node) {
      final renderObject = node.context?.findRenderObject();
      if (renderObject is! RenderBox || !renderObject.hasSize) return null;
      return renderObject.localToGlobal(Offset.zero) & renderObject.size;
    }

    nodes.sort((a, b) {
      final aRect = bounds(a);
      final bRect = bounds(b);
      if (!horizontal) {
        final vertical = (aRect?.top ?? 0).compareTo(bRect?.top ?? 0);
        if (vertical != 0) return vertical;
      }
      return (aRect?.left ?? 0).compareTo(bRect?.left ?? 0);
    });
    return nodes;
  }

  bool _moveAdjacentTile(BuildContext focused, TraversalDirection direction) {
    final currentTile = focused.findAncestorWidgetOfExactType<TvSettingsTile>();
    if (currentTile == null) return false;
    final tiles = <TvSettingsTile>[];
    final nodesByTile = <TvSettingsTile, List<FocusNode>>{};
    for (final node in FocusManager.instance.rootScope.descendants) {
      if (!node.canRequestFocus || node.skipTraversal || node.context == null) continue;
      final tile = node.context!.findAncestorWidgetOfExactType<TvSettingsTile>();
      if (tile == null) continue;
      if (!nodesByTile.containsKey(tile)) {
        tiles.add(tile);
        nodesByTile[tile] = [];
      }
      nodesByTile[tile]!.add(node);
    }
    final index = tiles.indexOf(currentTile);
    if (index < 0) return false;
    final offset = direction == TraversalDirection.down ? 1 : -1;
    var target = index + offset;
    while (target >= 0 && target < tiles.length) {
      final nodes = nodesByTile[tiles[target]]!;
      if (nodes.isNotEmpty) {
        final group = nodes
            .map((node) => node.context!.findAncestorWidgetOfExactType<TvHorizontalGroup>())
            .whereType<TvHorizontalGroup>()
            .firstOrNull;
        if (group?.initialFocusIndex case final index?) {
          final groupNodes = _sortByPosition(
            nodes
                .where((node) => identical(node.context!.findAncestorWidgetOfExactType<TvHorizontalGroup>(), group))
                .toList(),
          );
          if (index >= 0 && index < groupNodes.length) {
            groupNodes[index].requestFocus();
            return true;
          }
        }
        _sortByPosition(nodes).first.requestFocus();
        return true;
      }
      target += offset;
    }
    return false;
  }

  bool _bubble(TvDirectionIntent intent) {
    if (Actions.maybeFind<TvDirectionIntent>(context) != null) {
      Actions.invoke(context, intent);
      return true;
    }
    return FocusManager.instance.primaryFocus?.focusInDirection(intent.direction) ?? false;
  }

  KeyEventResult _handleKey(KeyEvent event) {
    if (!widget.tvMode || event is KeyUpEvent) return KeyEventResult.ignored;
    final focused = FocusManager.instance.primaryFocus?.context;
    if (focused?.findAncestorStateOfType<_TvSettingsListState>() != this) return KeyEventResult.ignored;
    final direction = switch (event.logicalKey) {
      LogicalKeyboardKey.arrowUp => TraversalDirection.up,
      LogicalKeyboardKey.arrowDown => TraversalDirection.down,
      LogicalKeyboardKey.arrowLeft => TraversalDirection.left,
      LogicalKeyboardKey.arrowRight => TraversalDirection.right,
      _ => null,
    };
    if (direction == null) return KeyEventResult.ignored;
    if (_move(direction)) return KeyEventResult.handled;
    return _bubble(TvDirectionIntent(direction)) ? KeyEventResult.handled : KeyEventResult.ignored;
  }

  @override
  void dispose() {
    FocusManager.instance.removeEarlyKeyEventHandler(_handleKey);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.tvMode
      ? Actions(
          actions: {
            TvDirectionIntent: CallbackAction<TvDirectionIntent>(
              onInvoke: (intent) {
                if (!_move(intent.direction, controller: true)) _bubble(intent);
                return null;
              },
            ),
          },
          child: SingleChildScrollView(
            padding: widget.padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [for (final child in widget.children) TvSettingsTile(child: child)],
            ),
          ),
        )
      : ListView(padding: widget.padding, children: widget.children);
}

/// Keeps Material's tile/slider actions while adding the TV focus treatment and remote switch adjustment.
class TvSettingsTile extends StatelessWidget {
  const TvSettingsTile({super.key, required this.child});
  final Widget child;

  /// Set while a tile forwards an activation, so one landing on the tile itself (focus on the tile, not on a
  /// control inside it) ends there instead of forwarding to itself until the stack overflows.
  static bool _forwarding = false;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
    child: TvFocusable(
      skipTraversal: true,
      descendantsAreFocusable: true,
      onActivate: () {
        final focused = FocusManager.instance.primaryFocus?.context;
        if (focused == null || _forwarding) return;
        _forwarding = true;
        try {
          Actions.maybeInvoke(focused, const ActivateIntent());
        } finally {
          _forwarding = false;
        }
      },
      child: Material(color: Colors.transparent, child: child),
    ),
  );
}

/// Marks a subtree whose focusable children handle horizontal movement as one row.
class TvHorizontalGroup extends StatelessWidget {
  const TvHorizontalGroup({super.key, required this.child, this.initialFocusIndex});
  final Widget child;
  final int? initialFocusIndex;

  @override
  Widget build(BuildContext context) => child;
}
