import 'package:flutter/material.dart';

class LoadingDots extends StatefulWidget {
  const LoadingDots({super.key});

  @override
  State<LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<LoadingDots> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat();

    _animations = List.generate(3, (index) {
      return Tween<double>(begin: 0.0, end: -10.0).animate(CurvedAnimation(
        parent: _controller,
        curve: Interval(
          (index * 0.2), // Stagger the start of each dot's animation
          (index * 0.2) + 0.6, // End the animation before the next dot starts
          curve: Curves.easeInOut,
        ),
      ));
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60, // Adjust width as needed
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(3, (index) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _animations[index].value),
                child: Opacity(
                  opacity: 1.0 - (_animations[index].value.abs() / 10.0), // Fade out as it moves up
                  child: Container(
                    width: 10, // Dot size
                    height: 10, // Dot size
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor, // Use theme primary color
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
