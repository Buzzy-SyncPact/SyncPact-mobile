import 'package:flutter/material.dart';

class AnimatedConnectionIcon extends StatefulWidget {
  const AnimatedConnectionIcon({super.key});

  @override
  _AnimatedConnectionIconState createState() => _AnimatedConnectionIconState();
}

class _AnimatedConnectionIconState extends State<AnimatedConnectionIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final iconSize = screenSize.width * 0.5;

    return Center(
      child: RotationTransition(
        turns: _animation,
        child: Icon(
          Icons.autorenew,
          size: iconSize,
          color: Colors.deepPurpleAccent,
        ),
      ),
    );
  }
}
