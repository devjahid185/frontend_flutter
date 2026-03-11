import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import 'form_field_config.dart';
import 'modern_app_bar.dart';

class SimplePostScreen extends StatefulWidget {
  const SimplePostScreen({
    super.key,
    required this.title,
    required this.endpoint,
    required this.fields,
    this.useDelete = false,
    this.allowImages = false,
    this.mediaTargetType,
    this.mediaSection,
    this.mediaResponseKey,
  });

  final String title;
  final String endpoint;
  final List<FormFieldConfig> fields;
  final bool useDelete;
  final bool allowImages;
  final String? mediaTargetType;
  final String? mediaSection;
  final String? mediaResponseKey;

  @override
  State<SimplePostScreen> createState() => _SimplePostScreenState();
}

class _SimplePostScreenState extends State<SimplePostScreen> {
  final _formKey = GlobalKey<FormState>();
  late final ApiClient _api = ApiClient(getToken: SessionStorage().getToken);
  late final Map<String, TextEditingController> _controllers;
  final List<XFile> _pickedImages = [];
  final ImagePicker _picker = ImagePicker();

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (final f in widget.fields) f.key: TextEditingController(text: f.initialValue ?? ''),
    };
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final body = <String, dynamic>{};
      for (final field in widget.fields) {
        final raw = _controllers[field.key]!.text.trim();
        if (!field.required && raw.isEmpty) continue;
        body[field.key] = field.numeric ? (num.tryParse(raw) ?? raw) : raw;
      }

      final dynamic response = widget.useDelete
          ? await _api.delete(widget.endpoint, body: body)
          : await _api.post(widget.endpoint, body: body);

      if (widget.allowImages &&
          widget.mediaTargetType != null &&
          widget.mediaSection != null &&
          _pickedImages.isNotEmpty &&
          !widget.useDelete) {
        final targetId = _extractTargetId(response, widget.mediaResponseKey);
        if (targetId != null) {
          await _api.postMultipart(
            '/media/upload',
            fields: {
              'section': widget.mediaSection!,
              'target_type': widget.mediaTargetType!,
              'target_id': '$targetId',
              'set_primary': 'true',
            },
            files: {
              'images[]': _pickedImages.map((e) => e.path).toList(),
            },
          );
        }
      }

      if (!mounted) return;

      final msg = response is Map<String, dynamic> && response['message'] is String
          ? response['message'] as String
          : 'সফলভাবে সম্পন্ন হয়েছে';

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('সাবমিট ব্যর্থ হয়েছে')));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  int? _extractTargetId(dynamic response, String? responseKey) {
    if (response is! Map<String, dynamic>) return null;
    final key = responseKey;
    if (key != null && response[key] is Map<String, dynamic>) {
      return (response[key]['id'] as num?)?.toInt();
    }

    for (final fallback in ['item', 'business', 'property', 'job', 'worker', 'user']) {
      final value = response[fallback];
      if (value is Map<String, dynamic> && value['id'] != null) {
        return (value['id'] as num).toInt();
      }
    }

    return null;
  }

  Future<void> _pickImages() async {
    if (_loading) return;

    final files = await _picker.pickMultiImage(
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (files.isEmpty) return;

    setState(() {
      _pickedImages
        ..clear()
        ..addAll(files.take(10));
    });
  }

  Future<void> _pickFromCamera() async {
    if (_loading || _pickedImages.length >= 10) return;

    final file = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (file == null) return;

    setState(() {
      if (_pickedImages.length < 10) {
        _pickedImages.add(file);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: ModernAppBar(title: widget.title, subtitle: 'তথ্য পূরণ করুন'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'সব আবশ্যক ঘর পূরণ করে সাবমিট করুন।',
              style: TextStyle(color: scheme.onPrimaryContainer, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 12),
          Form(
            key: _formKey,
            child: Column(
              children: [
                ...widget.fields.map((field) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TextFormField(
                        controller: _controllers[field.key],
                        keyboardType: field.numeric ? TextInputType.number : TextInputType.text,
                        decoration: InputDecoration(labelText: field.label, hintText: field.hint),
                        validator: (v) {
                          if (field.required && (v == null || v.trim().isEmpty)) {
                            return '${field.label} আবশ্যক';
                          }
                          return null;
                        },
                      ),
                    )),
                if (widget.allowImages)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ছবি যোগ করুন', style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: 6),
                        Text(
                          _pickedImages.isEmpty ? 'সর্বোচ্চ ১০টি ছবি' : 'সিলেক্টেড: ${_pickedImages.length} টি ছবি',
                          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _pickImages,
                              icon: const Icon(Icons.photo_library_outlined),
                              label: const Text('গ্যালারি থেকে বাছাই'),
                            ),
                            OutlinedButton.icon(
                              onPressed: _pickFromCamera,
                              icon: const Icon(Icons.photo_camera_outlined),
                              label: const Text('ক্যামেরা'),
                            ),
                            if (_pickedImages.isNotEmpty)
                              OutlinedButton.icon(
                                onPressed: () => setState(_pickedImages.clear),
                                icon: const Icon(Icons.delete_outline),
                                label: const Text('রিসেট'),
                              ),
                          ],
                        ),
                        if (_pickedImages.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: List.generate(_pickedImages.length, (index) {
                              final img = _pickedImages[index];
                              return Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.file(
                                      File(img.path),
                                      width: 70,
                                      height: 70,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: -6,
                                    right: -6,
                                    child: IconButton(
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () => setState(() => _pickedImages.removeAt(index)),
                                      icon: const Icon(Icons.cancel, size: 18),
                                    ),
                                  ),
                                ],
                              );
                            }),
                          ),
                        ],
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(widget.useDelete ? 'ডিলিট করুন' : 'সাবমিট করুন'),
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
