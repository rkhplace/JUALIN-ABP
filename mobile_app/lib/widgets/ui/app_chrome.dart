import 'package:flutter/material.dart';
import 'top_bar.dart';
import 'custom_navbar.dart';

class AppChrome extends StatelessWidget {
  final Widget child;
  final bool showTopBar;
  final bool showNavbar;
  final bool showSearch;
  final ValueChanged<String>? onSearch;

  const AppChrome({
    super.key,
    required this.child,
    this.showTopBar = false,
    this.showNavbar = true,
    this.showSearch = false,
    this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: showNavbar
          ? CustomNavbar(showSearch: showSearch, onSearch: onSearch)
          : null,
      body: SafeArea(
        child: Column(
          children: [
            if (showTopBar) const TopBar(),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}
