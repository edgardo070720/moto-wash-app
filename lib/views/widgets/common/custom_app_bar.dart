import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import 'connectivity_indicator.dart';
import 'sync_indicator.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBackButton;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 10),
          Text(title),
          const SizedBox(width: 12),
          const ConnectivityIndicator(),
          const SizedBox(width: 8),
          const SyncIndicator(),
        ],
      ),
      leading: leading,
      automaticallyImplyLeading: showBackButton,
      actions: actions,
      flexibleSpace: Container(
        decoration: BoxDecoration(gradient: AppTheme.primaryGradient),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
