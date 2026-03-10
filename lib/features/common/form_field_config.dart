class FormFieldConfig {
  const FormFieldConfig({
    required this.key,
    required this.label,
    this.required = true,
    this.numeric = false,
    this.hint,
    this.initialValue,
  });

  final String key;
  final String label;
  final bool required;
  final bool numeric;
  final String? hint;
  final String? initialValue;
}
