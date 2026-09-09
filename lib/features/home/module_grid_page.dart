import 'package:flutter/material.dart';

import '../common/module_navigator.dart';
import 'module_config.dart';

class ModuleGridPage extends StatelessWidget {
  const ModuleGridPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.modules,
  });

  final String title;
  final String subtitle;
  final List<ReadModule> modules;

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<ReadModule>>{};
    for (final module in modules) {
      grouped.putIfAbsent(module.section, () => <ReadModule>[]).add(module);
    }

    return Scaffold(
      backgroundColor: const Color(0xfff4f7f6),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        children: [
          const SizedBox(height: 4),
          Row(
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
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xff1f2937),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...grouped.entries.expand(
            (entry) => [
              _ModuleSection(title: entry.key, modules: entry.value),
              const SizedBox(height: 20),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModuleSection extends StatelessWidget {
  const _ModuleSection({required this.title, required this.modules});

  final String title;
  final List<ReadModule> modules;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _sectionTitle(title),
          style: const TextStyle(
            color: Color(0xff006a4e),
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        ...modules.map(
          (module) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _ModuleListTile(
              module: module,
              onTap: () => openReadModule(context, module),
            ),
          ),
        ),
      ],
    );
  }

  String _sectionTitle(String value) {
    return switch (value) {
      'মার্কেট' => 'প্রতিদিনের প্রয়োজন',
      'জরুরি' => 'জরুরি সেবা সমূহ',
      _ => value,
    };
  }
}

class _ModuleListTile extends StatelessWidget {
  const _ModuleListTile({required this.module, required this.onTap});

  final ReadModule module;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xffe5e7eb)),
          ),
          child: Row(
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: const Color(0xffe6f1ee),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  module.icon,
                  color: const Color(0xff006a4e),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      module.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xff1f2937),
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      module.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xff4b5563),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xff9ca3af),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
