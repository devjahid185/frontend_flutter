import 'package:flutter/material.dart';

import '../common/modern_app_bar.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  int _rating = 5;
  final TextEditingController _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: const ModernAppBar(title: 'ফিডব্যাক', subtitle: 'মতামত ও রেটিং'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.35)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('আপনার অভিজ্ঞতা জানাতে সাহায্য করবে', style: TextStyle(color: scheme.onSurfaceVariant)),
                const SizedBox(height: 12),
                Row(
                  children: List.generate(5, (index) {
                    final value = index + 1;
                    return IconButton(
                      onPressed: () => setState(() => _rating = value),
                      icon: Icon(
                        value <= _rating ? Icons.star_rounded : Icons.star_border_rounded,
                        color: Colors.amber.shade700,
                      ),
                    );
                  }),
                ),
                TextField(
                  controller: _messageController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'মেসেজ লিখুন',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('ধন্যবাদ! আপনার ফিডব্যাক জমা হয়েছে')),
                      );
                      _messageController.clear();
                      setState(() => _rating = 5);
                    },
                    child: const Text('সাবমিট'),
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