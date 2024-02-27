import 'package:flutter/material.dart';

class PipFlutterPlayerMaterialClickableWidget extends StatelessWidget {
  final Widget child;
  final void Function() onTap;

  const PipFlutterPlayerMaterialClickableWidget({
    super.key,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(60),
      ),
      clipBehavior: Clip.hardEdge,
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: child,
      ),
    );
  }
}
