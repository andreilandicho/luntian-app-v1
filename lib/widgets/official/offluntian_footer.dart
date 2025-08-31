import 'package:flutter/material.dart';

class LuntianFooter extends StatelessWidget {
  final int selectedIndex;
  final bool isNavVisible;
  final bool isSmallScreen;
  final Function(int) onItemTapped;

  const LuntianFooter({
    super.key,
    required this.selectedIndex,
    required this.isNavVisible,
    required this.isSmallScreen,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: isNavVisible ? 70 : 0,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [const BoxShadow(color: Colors.black12, blurRadius: 10)],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: isNavVisible
          ? Container(
              padding: EdgeInsets.symmetric(
                vertical: 8,
                horizontal: isSmallScreen ? 12 : 16,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [const BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavIcon(context, Icons.home_rounded, 0),
                  _buildNavIcon(context, Icons.leaderboard_rounded, 1),
                  _buildNavIcon(context, Icons.notifications_rounded, 2),
                  _buildNavIcon(context, Icons.person_rounded, 3),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildNavIcon(BuildContext context, IconData icon, int index) {
    bool isSelected = selectedIndex == index;

    return GestureDetector(
      onTap: () => onItemTapped(index), // delegate back to parent
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF328E6E) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected ? [const BoxShadow(color: Colors.black26, blurRadius: 6)] : [],
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.white : Colors.grey[600],
          size: isSelected ? (isSmallScreen ? 26 : 30) : (isSmallScreen ? 20 : 24),
        ),
      ),
    );
  }
}
