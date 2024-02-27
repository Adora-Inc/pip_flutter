import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pip_flutter/pipflutter_player_controller.dart';
import 'package:pip_flutter/pipflutter_player_progress_colors.dart';
import 'package:pip_flutter/video_player.dart';
import 'package:pip_flutter/video_player_platform_interface.dart';

class PipFlutterPlayerMaterialVideoProgressBar extends StatefulWidget {
  PipFlutterPlayerMaterialVideoProgressBar(
    this.controller,
    this.pipFlutterPlayerController, {
    PipFlutterPlayerProgressColors? colors,
    this.onDragEnd,
    this.onDragStart,
    this.onDragUpdate,
    this.onTapDown,
    super.key,
  }) : colors = colors ?? PipFlutterPlayerProgressColors();

  final VideoPlayerController? controller;
  final PipFlutterPlayerController? pipFlutterPlayerController;
  final PipFlutterPlayerProgressColors colors;
  final Function()? onDragStart;
  final Function()? onDragEnd;
  final Function()? onDragUpdate;
  final Function()? onTapDown;
  @override
  State<PipFlutterPlayerMaterialVideoProgressBar> createState() =>
      _PipFlutterPlayerMaterialVideoProgressBarState();
}

class _PipFlutterPlayerMaterialVideoProgressBarState
    extends State<PipFlutterPlayerMaterialVideoProgressBar> {
  _PipFlutterPlayerMaterialVideoProgressBarState() {
    listener = () {
      setState(() {});
    };
  }

  late VoidCallback listener;
  bool _controllerWasPlaying = false;

  VideoPlayerController? get controller => widget.controller;

  PipFlutterPlayerController? get pipFlutterPlayerController =>
      widget.pipFlutterPlayerController;

  bool shouldPlayAfterDragEnd = false;
  Duration? lastSeek;
  Timer? _updateBlockTimer;

  @override
  void initState() {
    super.initState();
    controller!.addListener(listener);
  }

  @override
  void deactivate() {
    controller!.removeListener(listener);
    _cancelUpdateBlockTimer();
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    final bool enableProgressBarDrag = pipFlutterPlayerController!
        .pipFlutterPlayerConfiguration
        .controlsConfiguration
        .enableProgressBarDrag;

    return GestureDetector(
      onHorizontalDragStart: (DragStartDetails details) async {
        if (!controller!.value.initialized || !enableProgressBarDrag) {
          return;
        }

        _controllerWasPlaying = controller!.value.isPlaying;
        if (_controllerWasPlaying) {
          await controller!.pause();
        }

        if (widget.onDragStart != null) {
          widget.onDragStart!();
        }
      },
      onHorizontalDragUpdate: (DragUpdateDetails details) async {
        if (!controller!.value.initialized || !enableProgressBarDrag) {
          return;
        }

        await seekToRelativePosition(details.globalPosition);

        if (widget.onDragUpdate != null) {
          widget.onDragUpdate!();
        }
      },
      onHorizontalDragEnd: (DragEndDetails details) async {
        if (!enableProgressBarDrag) {
          return;
        }

        if (_controllerWasPlaying) {
          await pipFlutterPlayerController?.play();
          shouldPlayAfterDragEnd = true;
        }
        _setupUpdateBlockTimer();

        if (widget.onDragEnd != null) {
          widget.onDragEnd!();
        }
      },
      onTapDown: (TapDownDetails details) async {
        if (!controller!.value.initialized || !enableProgressBarDrag) {
          return;
        }
        await seekToRelativePosition(details.globalPosition);
        _setupUpdateBlockTimer();
        if (widget.onTapDown != null) {
          widget.onTapDown!();
        }
      },
      child: Center(
        child: Container(
          height: MediaQuery.of(context).size.height / 2,
          width: MediaQuery.of(context).size.width,
          color: Colors.transparent,
          child: CustomPaint(
            painter: _ProgressBarPainter(
              _getValue(),
              widget.colors,
            ),
          ),
        ),
      ),
    );
  }

  void _setupUpdateBlockTimer() {
    _updateBlockTimer = Timer(const Duration(milliseconds: 1000), () {
      lastSeek = null;
      _cancelUpdateBlockTimer();
    });
  }

  void _cancelUpdateBlockTimer() {
    _updateBlockTimer?.cancel();
    _updateBlockTimer = null;
  }

  VideoPlayerValue _getValue() {
    if (lastSeek != null) {
      return controller!.value.copyWith(position: lastSeek);
    } else {
      return controller!.value;
    }
  }

  Future<void> seekToRelativePosition(Offset globalPosition) async {
    final RenderObject? renderObject = context.findRenderObject();
    if (renderObject != null) {
      final box = renderObject as RenderBox;
      final Offset tapPos = box.globalToLocal(globalPosition);
      final double relative = tapPos.dx / box.size.width;
      if (relative > 0) {
        final Duration position = controller!.value.duration! * relative;
        lastSeek = position;
        await pipFlutterPlayerController!.seekTo(position);
        await onFinishedLastSeek();
        if (relative >= 1) {
          lastSeek = controller!.value.duration;
          await pipFlutterPlayerController!.seekTo(controller!.value.duration!);
          await onFinishedLastSeek();
        }
      }
    }
  }

  Future<void> onFinishedLastSeek() async {
    if (shouldPlayAfterDragEnd) {
      shouldPlayAfterDragEnd = false;
      await pipFlutterPlayerController?.play();
    }
  }
}

class _ProgressBarPainter extends CustomPainter {
  _ProgressBarPainter(this.value, this.colors);

  VideoPlayerValue value;
  PipFlutterPlayerProgressColors colors;

  @override
  bool shouldRepaint(CustomPainter painter) {
    return true;
  }

  @override
  void paint(Canvas canvas, Size size) {
    const height = 2.0;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromPoints(
          Offset(0.0, size.height / 2),
          Offset(size.width, size.height / 2 + height),
        ),
        const Radius.circular(4.0),
      ),
      colors.backgroundPaint,
    );
    if (!value.initialized) {
      return;
    }
    double playedPartPercent =
        value.position.inMilliseconds / value.duration!.inMilliseconds;
    if (playedPartPercent.isNaN) {
      playedPartPercent = 0;
    }
    final double playedPart =
        playedPartPercent > 1 ? size.width : playedPartPercent * size.width;
    for (final DurationRange range in value.buffered) {
      double start = range.startFraction(value.duration!) * size.width;
      if (start.isNaN) {
        start = 0;
      }
      double end = range.endFraction(value.duration!) * size.width;
      if (end.isNaN) {
        end = 0;
      }
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromPoints(
            Offset(start, size.height / 2),
            Offset(end, size.height / 2 + height),
          ),
          const Radius.circular(4.0),
        ),
        colors.bufferedPaint,
      );
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromPoints(
          Offset(0.0, size.height / 2),
          Offset(playedPart, size.height / 2 + height),
        ),
        const Radius.circular(4.0),
      ),
      colors.playedPaint,
    );
    canvas.drawCircle(
      Offset(playedPart, size.height / 2 + height / 2),
      height * 3,
      colors.handlePaint,
    );
  }
}
