import 'package:flutter/material.dart';

class GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget title;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final Widget? leading;
  final bool centerTitle;

  const GradientAppBar({super.key, required this.title, this.actions, this.bottom, this.leading, this.centerTitle = false});

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      title: title,
      actions: actions,
      bottom: bottom,
      leading: leading,
      centerTitle: centerTitle,
      flexibleSpace: const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF64B5F6), // Blue 300
              Color(0xFFBBDEFB), // Blue 100
            ],
          ),
        ),
      ),
    );
  }
}
