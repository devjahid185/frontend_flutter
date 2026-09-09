import 'package:flutter/material.dart';

class AuthFormShell extends StatelessWidget {
  const AuthFormShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.appBarTitle,
    this.centerHeader = false,
    this.headerIcon,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final String? appBarTitle;
  final bool centerHeader;
  final IconData? headerIcon;

  @override
  Widget build(BuildContext context) {
    const green = Color(0xff006a4e);
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xffe5e7eb)),
    );

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
        child: Theme(
          data: Theme.of(context).copyWith(
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 15,
              ),
              labelStyle: const TextStyle(
                color: Color(0xff1f2937),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
              hintStyle: const TextStyle(
                color: Color(0xff6b7280),
                fontSize: 14,
              ),
              enabledBorder: inputBorder,
              focusedBorder: inputBorder.copyWith(
                borderSide: const BorderSide(color: green, width: 1.6),
              ),
              errorBorder: inputBorder.copyWith(
                borderSide: const BorderSide(color: Color(0xffef4444)),
              ),
              focusedErrorBorder: inputBorder.copyWith(
                borderSide: const BorderSide(color: Color(0xffef4444)),
              ),
            ),
            filledButtonTheme: FilledButtonThemeData(
              style: FilledButton.styleFrom(
                backgroundColor: green,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
            child: Column(
              crossAxisAlignment: centerHeader
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              children: [
                if (headerIcon != null) ...[
                  Container(
                    height: 88,
                    width: 88,
                    decoration: const BoxDecoration(
                      color: Color(0xffe6f1ee),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(headerIcon, color: green, size: 44),
                  ),
                  const SizedBox(height: 28),
                ],
                Text(
                  title,
                  textAlign: centerHeader ? TextAlign.center : TextAlign.start,
                  style: TextStyle(
                    color: const Color(0xff1f2937),
                    fontSize: centerHeader ? 20 : 24,
                    height: 1.12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  textAlign: centerHeader ? TextAlign.center : TextAlign.start,
                  style: const TextStyle(
                    color: Color(0xff6b7280),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 28),
                DefaultTextStyle.merge(
                  style: const TextStyle(color: Color(0xff1f2937)),
                  child: child,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
