import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';

class TvBackIntent extends Intent {
  const TvBackIntent();
}

/// Jumps between the page and the now-playing bar, however far down the page the bar is.
class TvNowPlayingBarIntent extends Intent {
  const TvNowPlayingBarIntent();
}

class TvDirectionIntent extends Intent {
  const TvDirectionIntent(this.direction);
  final TraversalDirection direction;
}

/// A single activation target for touch, remotes and controllers, with the same focus treatment everywhere.
class TvFocusable extends StatefulWidget {
  const TvFocusable({
    super.key,
    required this.child,
    required this.onActivate,
    this.focusNode,
    this.autofocus = false,
    this.label,
    this.descendantsAreFocusable = false,
    this.skipTraversal = false,
    this.focusScale = 1.06,
  });

  final Widget child;
  final VoidCallback? onActivate;
  final FocusNode? focusNode;
  final bool autofocus;
  final String? label;

  /// Wide rows grow less so they stay on screen.
  final double focusScale;
  final bool descendantsAreFocusable;
  final bool skipTraversal;

  @override
  State<TvFocusable> createState() => _TvFocusableState();
}

class _TvFocusableState extends State<TvFocusable> {
  bool _focused = false;

  void _focusChanged(bool focused) {
    setState(() => _focused = focused);
    if (focused) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Scrollable.ensureVisible(context, duration: const Duration(milliseconds: 150), alignment: 0.5);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) => Actions(
    actions: {ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => widget.onActivate?.call())},
    child: Focus(
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      skipTraversal: widget.skipTraversal,
      canRequestFocus: widget.onActivate != null,
      onFocusChange: _focusChanged,
      onKeyEvent: (_, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        if ({
          LogicalKeyboardKey.enter,
          LogicalKeyboardKey.numpadEnter,
          LogicalKeyboardKey.select,
          LogicalKeyboardKey.gameButtonA,
          LogicalKeyboardKey.space,
        }.contains(event.logicalKey)) {
          widget.onActivate?.call();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Semantics(
        button: true,
        enabled: widget.onActivate != null,
        label: widget.label,
        child: GestureDetector(
          onTap: widget.onActivate,
          child: AnimatedScale(
            scale: _focused ? widget.focusScale : 1,
            duration: const Duration(milliseconds: 150),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                color: Palette.card,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _focused ? Colors.white : Colors.transparent, width: 3),
                boxShadow: [
                  if (_focused) BoxShadow(color: Colors.white.withValues(alpha: 0.3), blurRadius: 20, spreadRadius: 2),
                ],
              ),
              child: ExcludeFocus(excluding: !widget.descendantsAreFocusable, child: widget.child),
            ),
          ),
        ),
      ),
    ),
  );
}

class TvButton extends StatelessWidget {
  const TvButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.autofocus = false,
    this.active = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool autofocus;

  /// Toggles that are on (shuffle) tint their icon with the accent colour.
  final bool active;

  @override
  Widget build(BuildContext context) => TvFocusable(
    autofocus: autofocus,
    label: label,
    onActivate: onPressed,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 32, color: active ? Theme.of(context).colorScheme.primary : null),
          const SizedBox(width: 10),
          Text(label),
        ],
      ),
    ),
  );
}
