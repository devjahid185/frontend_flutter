import 'package:flutter/material.dart';

class CheckoutPaymentSection extends StatelessWidget {
  const CheckoutPaymentSection({
    super.key,
    required this.options,
    required this.selectedMethod,
    required this.total,
    required this.onChanged,
  });

  final List<dynamic> options;
  final String? selectedMethod;
  final dynamic total;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (options.isEmpty) {
      return const _PaymentInfoNote(
        text: 'এই রেস্টুরেন্টে এখন কোনো পেমেন্ট পদ্ধতি চালু নেই।',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'পেমেন্ট পদ্ধতি',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        ...options.map((raw) {
          final option = Map<String, dynamic>.from(raw as Map);
          final method = option['method']?.toString() ?? '';
          final selected = selectedMethod == method;
          final isManual = method.startsWith('manual_');
          final icon = method == 'manual_bkash'
              ? Icons.account_balance_wallet_rounded
              : method == 'manual_nagad'
              ? Icons.send_to_mobile_rounded
              : Icons.payments_rounded;

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: selected
                  ? scheme.primaryContainer.withValues(alpha: 0.55)
                  : scheme.surface,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: method.isEmpty ? null : () => onChanged(method),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: selected
                          ? scheme.primary
                          : scheme.outlineVariant.withValues(alpha: 0.6),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(icon, color: selected ? scheme.primary : null),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              option['title']?.toString() ?? 'Payment',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              option['subtitle']?.toString() ?? '',
                              style: TextStyle(
                                color: scheme.onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                            if (isManual) ...[
                              const SizedBox(height: 8),
                              _ManualPaymentInstruction(
                                number: option['number']?.toString() ?? '',
                                instructions:
                                    option['instructions']?.toString() ?? '',
                                total: total,
                              ),
                            ],
                          ],
                        ),
                      ),
                      Icon(
                        selected
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_off_rounded,
                        color: selected ? scheme.primary : scheme.outline,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _ManualPaymentInstruction extends StatelessWidget {
  const _ManualPaymentInstruction({
    required this.number,
    required this.instructions,
    required this.total,
  });

  final String number;
  final String instructions;
  final dynamic total;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'নম্বর: $number',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text('পরিমাণ: ৳$total'),
          const SizedBox(height: 4),
          Text(
            instructions.trim().isEmpty
                ? 'Send Money করে transaction ID অর্ডার নোটে লিখুন।'
                : instructions,
          ),
        ],
      ),
    );
  }
}

class _PaymentInfoNote extends StatelessWidget {
  const _PaymentInfoNote({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(text),
    );
  }
}
