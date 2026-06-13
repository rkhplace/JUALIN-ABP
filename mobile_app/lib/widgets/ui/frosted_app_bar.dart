import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FrostedAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final bool centerTitle;
  final bool scrolled;

  const FrostedAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.centerTitle = false,
    this.scrolled = false,
  });

  static const double height = 52;

  @override
  Size get preferredSize => const Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final backgroundColor =
        scrolled ? Colors.white.withValues(alpha: 0.78) : Colors.white;
    final dividerColor = scrolled
        ? Colors.black.withValues(alpha: 0.10)
        : Colors.grey.withValues(alpha: 0.18);

    return AppBar(
      toolbarHeight: height,
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.black87,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      centerTitle: centerTitle,
      titleSpacing: 16,
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading: leading,
      title: titleWidget ??
          (title == null
              ? null
              : Text(
                  title!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                )),
      actions: actions,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: scrolled ? 10 : 0,
            sigmaY: scrolled ? 10 : 0,
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: backgroundColor,
              border: Border(
                bottom: BorderSide(color: dividerColor, width: 1),
              ),
              boxShadow: scrolled
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

class FrostedScaffold extends StatefulWidget {
  final String? title;
  final Widget? titleWidget;
  final Widget body;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final bool centerTitle;
  final Color? backgroundColor;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final bool? resizeToAvoidBottomInset;
  final bool showAppBar;

  const FrostedScaffold({
    super.key,
    this.title,
    this.titleWidget,
    required this.body,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.centerTitle = false,
    this.backgroundColor,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.resizeToAvoidBottomInset,
    this.showAppBar = true,
  });

  @override
  State<FrostedScaffold> createState() => _FrostedScaffoldState();
}

class _FrostedScaffoldState extends State<FrostedScaffold> {
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
      backgroundColor: widget.backgroundColor ?? Colors.white,
      resizeToAvoidBottomInset: widget.resizeToAvoidBottomInset,
      appBar: widget.showAppBar
          ? FrostedAppBar(
              title: widget.title,
              titleWidget: widget.titleWidget,
              actions: widget.actions,
              leading: widget.leading,
              automaticallyImplyLeading: widget.automaticallyImplyLeading,
              centerTitle: widget.centerTitle,
              scrolled: _scrolled,
            )
          : null,
      floatingActionButton: widget.floatingActionButton,
      bottomNavigationBar: widget.bottomNavigationBar,
      body: NotificationListener<ScrollNotification>(
        onNotification: _handleScroll,
        child: widget.body,
      ),
    );
  }
}
