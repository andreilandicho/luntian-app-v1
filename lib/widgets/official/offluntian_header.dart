import 'package:flutter/material.dart';

class LuntianHeader extends StatelessWidget implements PreferredSizeWidget {
  final bool isSmallScreen;

  const LuntianHeader({
    super.key,
    required this.isSmallScreen,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF328E6E),
      elevation: 0,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo and Title
          Row(
            children: [
              Image.asset(
                'assets/logo only luntian.png',
                width: isSmallScreen ? 24 : 30,
                height: isSmallScreen ? 24 : 30,
              ),
              const SizedBox(width: 8),
              Text(
                'LUNTIAN',
                style: TextStyle(
                  fontFamily: 'MaryKate',
                  fontSize: isSmallScreen ? 20 : 24,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}