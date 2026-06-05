import 'package:flutter/material.dart';
import 'top_bar.dart';
import 'custom_navbar.dart';

class AppChrome extends StatefulWidget {
  final Widget child;
  final bool showTopBar;
  final bool showNavbar;
  final bool showSearch;
  final bool showLogo;
  final ValueChanged<String>? onSearch;

  const AppChrome({
    super.key,
    required this.child,
    this.showTopBar = false,
    this.showNavbar = true,
    this.showSearch = false,
    this.showLogo = true,
    this.onSearch,
  });

  @override
  State<AppChrome> createState() => _AppChromeState();
}

class _AppChromeState extends State<AppChrome> {
  bool _scrolled = false;

  bool _handleScroll(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;
    final nextScrolled = notification.metrics.pixels > 2;
    if (nextScrolled != _scrolled) {
      setState(() => _scrolled = nextScrolled);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: widget.showNavbar
          ? CustomNavbar(
              showSearch: widget.showSearch,
              showLogo: widget.showLogo,
              onSearch: widget.onSearch,
              scrolled: _scrolled,
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            if (widget.showTopBar) const TopBar(),
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: _handleScroll,
                child: widget.child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
