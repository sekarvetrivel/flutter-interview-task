# Bonus: 3 Hard Questions — Answers

## Bonus Q1 — Isolates & Heavy Computation

**Approach:** Use `compute()` here, not a manually managed long-lived
`Isolate`. `compute()` is exactly for this shape of problem: a single,
one-shot, CPU-bound transformation (raw JSON bytes → list of model
objects) with a clear input and output, no ongoing communication needed
after it returns. A manual `Isolate` earns its complexity when you need a
long-lived worker that receives a *stream* of messages over time (e.g. a
background compression queue, or a socket you keep pushing frames to) —
here we just want one function call off the UI thread, once.

**Critical constraint:** the isolate function must be a **top-level or
static function** and everything passed into it must be copyable across
the isolate boundary (no closures capturing `BuildContext`, no
`ChangeNotifier`/widget state, no platform channel objects). Isolates
don't share memory — arguments are serialized/copied, not referenced.

```dart
// Top-level function — required by compute(). Cannot be a closure that
// captures UI state.
List<MyModel> _parseJsonInBackground(String rawJson) {
  final decoded = jsonDecode(rawJson) as List<dynamic>;
  return decoded
      .map((e) => MyModel.fromJson(e as Map<String, dynamic>))
      .toList();
}

Future<List<MyModel>> loadModelsFromFile(String path) async {
  final rawJson = await File(path).readAsString();
  // compute() spawns (or reuses, depending on Flutter version) an
  // isolate, runs `_parseJsonInBackground(rawJson)` on it, and returns
  // the result back on the main isolate — the actual decode+parse never
  // blocks a UI frame.
  return compute(_parseJsonInBackground, rawJson);
}
```

If this needed to become a repeated/streaming operation (e.g. parsing
chunks as they arrive), that's when I'd reach for a manual
`Isolate.spawn` + `ReceivePort`/`SendPort` pair instead, since `compute()`
is strictly single call in, single result out.

---

## Bonus Q2 — Diagnosing a Memory Leak

**Scenario:** a chart screen driven by `Stream.periodic` + an
`AnimationController`, and memory climbs every time the user navigates to
it and back.

**Two likely root causes:**

1. **The `StreamSubscription` to `Stream.periodic` is never cancelled.**
   `Stream.periodic` keeps firing forever until something cancels its
   subscription. If the subscription is created in `initState` but not
   stored and cancelled in `dispose`, the timer keeps running (and, if the
   listener closure captures `setState` or `this`, keeps the whole State
   object alive) even after the screen is popped.

2. **The `AnimationController` is never disposed**, or is disposed but a
   `Ticker`/listener added to it directly (via `addListener` /
   `addStatusListener`) isn't removed first. An undisposed controller
   keeps its `Ticker` registered with the scheduler, and if any listener
   closure captures the State/BuildContext, that whole subtree becomes
   unreachable-but-referenced — a classic leak, not a crash, which is why
   it shows up as gradually climbing memory rather than an immediate
   error.

**Corrected `dispose()`:**

```dart
late final StreamSubscription<void> _tickerSubscription;
late final AnimationController _controller;

@override
void initState() {
  super.initState();
  _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
  _tickerSubscription = Stream.periodic(const Duration(seconds: 1)).listen((_) {
    if (!mounted) return;
    setState(() { /* refresh chart data */ });
  });
}

@override
void dispose() {
  _tickerSubscription.cancel(); // stop the periodic stream from firing forever
  _controller.dispose();        // release the ticker + any attached listeners
  super.dispose();
}
```

**What happens if one is omitted:** if `_tickerSubscription.cancel()` is
left out, the periodic stream keeps emitting after the widget is popped;
its listener calls `setState` on a disposed State, which either throws
("setState() called after dispose()") in debug or, if guarded with a
`mounted` check as above, silently keeps the old State object (and
everything it closes over — old chart data, old context references)
resident in memory forever, since the Stream still holds a reference to
the listener closure. Each visit to the screen adds another live
subscription doing this, which is exactly the "climbs every time I
navigate back" symptom described.

---

## Bonus Q3 — CustomPainter vs. Composing Widgets (200+ animated ticks at 60fps)

**Answer: reach for `CustomPainter`, not 200+ individual widgets.**

Every widget in the widget tree has a matching Element and (for
`RenderObject`-backed widgets) a RenderObject. Rebuilding/re-laying-out
200+ individual tick-mark widgets every frame means walking and diffing
200+ Elements through the widget→element→render tree pipeline, 60 times a
second — that's real overhead in tree diffing, layout, and paint dispatch
that has nothing to do with the actual pixels being drawn.

A `CustomPainter` collapses all 200+ ticks into a *single* RenderObject
(`RenderCustomPaint`) whose `paint()` method issues raw `Canvas` draw
calls directly. There's no per-tick widget/element overhead at all — the
animation just needs to invalidate and repaint one object each frame,
which is exactly what 60fps with many small repeated shapes calls for.

```dart
class GaugePainter extends CustomPainter {
  GaugePainter({required this.progress, required this.tickCount})
      : super(); // pass a repaint Listenable here instead, in the real version — see below

  final double progress; // 0.0-1.0, drives which ticks are "lit"
  final int tickCount;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 8;

    for (var i = 0; i < tickCount; i++) {
      final angle = (i / tickCount) * 2 * math.pi;
      final isLit = i / tickCount <= progress;
      final paint = Paint()
        ..color = isLit ? Colors.orange : Colors.grey.shade300
        ..strokeWidth = 3;

      final start = center + Offset(math.cos(angle), math.sin(angle)) * (radius - 6);
      final end = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      canvas.drawLine(start, end, paint);
    }
  }

  @override
  bool shouldRepaint(covariant GaugePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
```

In the real implementation, I'd drive this with `AnimatedBuilder` /
`CustomPainter`'s `repaint: animationController` constructor parameter
(a `Listenable`) rather than passing a raw `progress` double and relying
on the parent rebuilding — that way the `CustomPaint` widget itself
doesn't need to rebuild every frame; only `paint()` re-runs, which is
cheaper still.

**Where I'd place a `RepaintBoundary` and why:** wrap the `CustomPaint`
widget in its own `RepaintBoundary`. The gauge repaints on every one of
the 60 ticks/sec, but the rest of the screen (surrounding labels, other
UI) does not need to. Without the boundary, Flutter may fold the gauge's
repaint into the same paint layer as its neighbors, meaning nearby static
widgets get needlessly repainted/composited alongside it. A
`RepaintBoundary` gives the gauge its own compositing layer, so the
60fps repaint is isolated to just that layer and doesn't force
recompositing of unrelated, unchanging UI around it.
