import 'package:flutter/material.dart';

/// A reusable card that expands/collapses to reveal [expandedContent] when
/// [header] is tapped. The chevron icon rotates in sync with the expansion
/// progress.
///
/// ARCHITECTURAL DECISIONS:
/// - We drive everything off a single [AnimationController] (0.0 = collapsed,
///   1.0 = expanded) rather than reaching for `AnimatedContainer`. That gives
///   us a single source of truth for "how expanded are we right now", which
///   is what lets the interrupt-and-reverse behavior below work correctly.
/// - We use [AnimatedBuilder] instead of rebuilding the whole widget tree on
///   every tick. Only the subtree that actually changes (height clip + icon
///   rotation) is wrapped, so the header/content widgets themselves are built
///   once and reused across frames (they're passed in as `child`).
/// - We size the expanded content by animating a `heightFactor` inside a
///   [ClipRect] + [Align], rather than animating an explicit pixel height.
///   This avoids needing to know the content's height up front and still
///   clips correctly at any intermediate progress value.
class ExpandableCard extends StatefulWidget {
  const ExpandableCard({
    super.key,
    required this.header,
    required this.expandedContent,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
    this.onExpansionChanged,
    this.initiallyExpanded = false,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 12,
  });

  /// Always-visible header row. Tapping it toggles expansion.
  final Widget header;

  /// Content revealed when expanded.
  final Widget expandedContent;

  final Duration duration;
  final Curve curve;
  final EdgeInsets padding;
  final double borderRadius;

  /// Called with the new expansion state whenever it changes (i.e. once per
  /// tap, not once per animation frame).
  final ValueChanged<bool>? onExpansionChanged;

  final bool initiallyExpanded;

  @override
  State<ExpandableCard> createState() => _ExpandableCardState();
}

class _ExpandableCardState extends State<ExpandableCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _curvedProgress;

  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      // Start already at 1.0 if initially expanded, so no animation plays
      // on first frame.
      value: _isExpanded ? 1.0 : 0.0,
    );

    _curvedProgress = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
      reverseCurve: widget.curve.flipped,
    );
  }

  void _handleTap() {
    final bool willExpand = !_isExpanded;
    setState(() => _isExpanded = willExpand);

    // KEY REQUIREMENT: interruption handling.
    // `forward()` / `reverse()` on an AnimationController do NOT reset the
    // controller's value first — they animate from whatever `_controller
    // .value` currently is towards the target (1.0 or 0.0). So if the user
    // taps again mid-animation, this naturally reverses smoothly from the
    // current position instead of snapping back to 0/1 and restarting.
    if (willExpand) {
      _controller.forward();
    } else {
      _controller.reverse();
    }

    widget.onExpansionChanged?.call(willExpand);
  }

  @override
  void dispose() {
    // Controller disposal discipline: an AnimationController holds a Ticker
    // subscription tied to this State's vsync. Failing to dispose it leaks
    // the ticker and keeps this State (and everything it closes over) alive
    // even after the widget is removed from the tree.
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(widget.borderRadius),
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      child: InkWell(
        onTap: _handleTap,
        child: Padding(
          padding: widget.padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: widget.header),
                  // AnimatedBuilder rebuilds only this icon on every tick,
                  // not the header or expandedContent subtrees.
                  AnimatedBuilder(
                    animation: _curvedProgress,
                    builder: (context, child) {
                      return Transform.rotate(
                        // 0 -> 0.5 turns (180deg) as it expands.
                        angle: _curvedProgress.value * 3.14159265,
                        child: child,
                      );
                    },
                    child: const Icon(Icons.expand_more),
                  ),
                ],
              ),
              AnimatedBuilder(
                animation: _curvedProgress,
                // `child` is built once and passed through unchanged; only
                // the ClipRect/Align wrapper around it rebuilds per frame.
                child: widget.expandedContent,
                builder: (context, child) {
                  return ClipRect(
                    child: Align(
                      alignment: Alignment.topCenter,
                      heightFactor: _curvedProgress.value,
                      child: child,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
