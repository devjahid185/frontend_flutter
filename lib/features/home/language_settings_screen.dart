import 'package:flutter/material.dart';

import '../common/modern_app_bar.dart';

class LanguageSettingsScreen extends StatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  State<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen> {
  String _selected = 'bn';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: const ModernAppBar(
        title: 'ভাষা',
        subtitle: 'অ্যাপের ভাষা নির্বাচন',
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.35),
              ),
            ),
            child: Column(
              children: [
                RadioListTile<String>(
                  value: 'bn',
                  groupValue: _selected,
                  onChanged: (v) => setState(() => _selected = v ?? 'bn'),
                  title: const Text('বাংলা'),
                  subtitle: Text(
                    'ডিফল্ট ভাষা',
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                ),
                RadioListTile<String>(
                  value: 'en',
                  groupValue: _selected,
                  onChanged: (v) => setState(() => _selected = v ?? 'bn'),
                  title: const Text('English'),
                  subtitle: Text(
                    'Coming soon',
                    style: TextStyle(color: scheme.onSurfaceVariant),
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
