import 'package:flutter/material.dart';

import '../common/module_navigator.dart';
import 'module_config.dart';

class CommunityPage extends StatelessWidget {
  const CommunityPage({super.key});

  @override
  Widget build(BuildContext context) {
    final emergency = homeServiceModules.firstWhere(
      (m) => m.endpoint == '/emergency',
    );
    final blood = homeServiceModules.firstWhere(
      (m) => m.endpoint == '/blood-donors',
    );

    return Scaffold(
      backgroundColor: const Color(0xfff4f7f6),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        children: [
          const SizedBox(height: 4),
          const Text(
            'কমিউনিটি ফিড',
            style: TextStyle(
              color: Color(0xff1f2937),
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _CommunityTag(label: '#খবরের আপডেট'),
                _CommunityTag(label: '#জরুরি সেবা'),
                _CommunityTag(label: '#রক্তদাতা'),
                _CommunityTag(label: '#নোটিশ'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...communityModules.map(
            (module) => _CommunityCard(
              module: module,
              onTap: () => openReadModule(context, module),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'জরুরি শর্টকাট',
            style: TextStyle(
              color: Color(0xff006a4e),
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _EmergencyShortcut(
                  icon: Icons.call_rounded,
                  label: 'জরুরি নম্বর',
                  onPressed: () => openReadModule(context, emergency),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _EmergencyShortcut(
                  icon: Icons.bloodtype_rounded,
                  label: 'রক্তদাতা',
                  onPressed: () => openReadModule(context, blood),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CommunityTag extends StatelessWidget {
  const _CommunityTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xffe5e7eb)),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Color(0xff4b5563), fontSize: 12),
      ),
    );
  }
}

class _CommunityCard extends StatelessWidget {
  const _CommunityCard({required this.module, required this.onTap});

  final ReadModule module;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffe5e7eb)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xffe6f1ee),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(
                        module.icon,
                        color: const Color(0xff006a4e),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
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
                          const SizedBox(height: 2),
                          const Text(
                            'সর্বশেষ আপডেট',
                            style: TextStyle(
                              color: Color(0xff9ca3af),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xffe6f1ee),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        module.title,
                        style: const TextStyle(
                          color: Color(0xff006a4e),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  module.subtitle,
                  style: const TextStyle(
                    color: Color(0xff4b5563),
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xffe5e7eb)),
                const SizedBox(height: 10),
                Row(
                  children: const [
                    Icon(
                      Icons.touch_app_outlined,
                      size: 16,
                      color: Color(0xff4b5563),
                    ),
                    SizedBox(width: 5),
                    Text(
                      'দেখুন',
                      style: TextStyle(color: Color(0xff4b5563), fontSize: 12),
                    ),
                    Spacer(),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: Color(0xff9ca3af),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmergencyShortcut extends StatelessWidget {
  const _EmergencyShortcut({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xff006a4e),
          backgroundColor: Colors.white,
          side: const BorderSide(color: Color(0xffe5e7eb)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}
