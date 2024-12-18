import 'package:flutter/material.dart';

///Helper class for GestureDetector used within PipFlutter Player. Used to pass
///gestures to upper GestureDetectors.
class PipFlutterPlayerMultipleGestureDetector extends InheritedWidget {
  final void Function()? onTap;
  final void Function()? onDoubleTap;
  final void Function()? onLongPress;

  const PipFlutterPlayerMultipleGestureDetector({
    super.key,
    required super.child,
    this.onTap,
    this.onDoubleTap,
    this.onLongPress,
  });

  static PipFlutterPlayerMultipleGestureDetector? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<
        PipFlutterPlayerMultipleGestureDetector>();
  }

  @override
  bool updateShouldNotify(PipFlutterPlayerMultipleGestureDetector oldWidget) =>
      false;
}
