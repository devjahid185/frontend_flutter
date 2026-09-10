import 'package:flutter/material.dart';

class LanguageSettingsScreen extends StatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  State<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen> {
  String _selected = 'bn';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff4f7f6),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        children: [
          const _SimpleHeader(title: 'ভাষা'),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xffe5e7eb)),
            ),
            child: Column(
              children: [
                RadioListTile<String>(
                  value: 'bn',
                  groupValue: _selected,
                  onChanged: (v) => setState(() => _selected = v ?? 'bn'),
                  title: const Text('বাংলা'),
                  activeColor: const Color(0xff006a4e),
                  subtitle: const Text(
                    'ডিফল্ট ভাষা',
                    style: TextStyle(color: Color(0xff4b5563), fontSize: 12),
                  ),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                RadioListTile<String>(
                  value: 'en',
                  groupValue: _selected,
                  onChanged: (v) => setState(() => _selected = v ?? 'bn'),
                  title: const Text('English'),
                  activeColor: const Color(0xff006a4e),
                  subtitle: const Text(
                    'Coming soon',
                    style: TextStyle(color: Color(0xff4b5563), fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SimpleHeader extends StatelessWidget {
  const _SimpleHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.chevron_left_rounded),
          style: IconButton.styleFrom(
            foregroundColor: const Color(0xff1f2937),
            padding: EdgeInsets.zero,
            minimumSize: const Size(28, 28),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xff1f2937),
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
