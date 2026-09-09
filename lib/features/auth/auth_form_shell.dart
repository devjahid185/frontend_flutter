import 'package:flutter/material.dart';

class AuthFormShell extends StatelessWidget {
  const AuthFormShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.appBarTitle,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final String? appBarTitle;

  @override
  Widget build(BuildContext context) {
    const green = Color(0xff006a4e);
    return Scaffold(
      backgroundColor: const Color(0xfff4f7f6),
      appBar: appBarTitle == null
          ? null
          : AppBar(
              title: Text(
                appBarTitle!,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              backgroundColor: Colors.white,
              foregroundColor: green,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              bottom: const PreferredSize(
                preferredSize: Size.fromHeight(1),
                child: Divider(height: 1, color: Color(0xffe5e7eb)),
              ),
            ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 22, 18, 24),
                decoration: BoxDecoration(
                  color: green,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.lock_outline_rounded,
                        color: green,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        height: 1.08,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xffe5e7eb)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
