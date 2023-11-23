import 'package:flutter/material.dart';
import 'package:pip_flutter/pipflutter_player_controller.dart';

///Widget which is used to inherit PipFlutterPlayerController through widget tree.
class PipFlutterPlayerControllerProvider extends InheritedWidget {
  const PipFlutterPlayerControllerProvider({
    super.key,
    required this.controller,
    required super.child,
  });

  final PipFlutterPlayerController controller;

  @override
  bool updateShouldNotify(PipFlutterPlayerControllerProvider oldWidget) =>
      controller != oldWidget.controller;
}
