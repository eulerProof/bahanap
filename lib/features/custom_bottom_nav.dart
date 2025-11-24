import 'package:flutter/material.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: const Color(0xff32ade6),
      shape: const CircularNotchedRectangle(),
      notchMargin: 6.0,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.home),
              color: currentIndex == 0 ? Colors.black : Colors.white,
              onPressed: currentIndex == 0 ? null : () => onTap(0),
            ),
            IconButton(
              icon: const Icon(Icons.map),
              color: currentIndex == 1 ? Colors.black : Colors.white,
              onPressed: currentIndex == 1 ? null : () => onTap(1),
            ),
            const SizedBox(width: 20),
            IconButton(
              icon: const Icon(Icons.notifications),
              color: currentIndex == 2 ? Colors.black : Colors.white,
              onPressed: currentIndex == 2 ? null : () => onTap(2),
            ),
            IconButton(
              icon: const Icon(Icons.person),
              color: currentIndex == 3 ? Colors.black : Colors.white,
              onPressed: currentIndex == 3 ? null : () => onTap(3),
            ),
          ],
        ),
      ),
    );
  }
}
