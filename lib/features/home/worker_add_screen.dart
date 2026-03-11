import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import '../common/modern_app_bar.dart';

class WorkerAddScreen extends StatefulWidget {
  const WorkerAddScreen({super.key, this.initialCategoryId});

  final int? initialCategoryId;

  @override
  State<WorkerAddScreen> createState() => _WorkerAddScreenState();
}

class _WorkerAddScreenState extends State<WorkerAddScreen> {
  final _formKey = GlobalKey<FormState>();
  late final ApiClient _api = ApiClient(getToken: SessionStorage().getToken);

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _experienceController = TextEditingController();
  final _priceController = TextEditingController();
  final _skillsController = TextEditingController();
  final _areaController = TextEditingController();
  final _descriptionController = TextEditingController();

  final List<XFile> _pickedImages = [];
  final ImagePicker _picker = ImagePicker();

  bool _loading = false;
  bool _loadingCategories = true;
  List<Map<String, dynamic>> _categories = [];
  int? _selectedCategoryId;
  bool _available = true;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.initialCategoryId;
    _loadCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _experienceController.dispose();
    _priceController.dispose();
    _skillsController.dispose();
    _areaController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _loadingCategories = true;
    });
    try {
      final res = await _api.get('/worker/categories');
      if (res is List) {
        _categories = res.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        if (_selectedCategoryId == null && _categories.isNotEmpty) {
          _selectedCategoryId = (_categories.first['id'] as num?)?.toInt();
        }
      }
    } catch (_) {
      // keep empty
    } finally {
      if (mounted) {
        setState(() => _loadingCategories = false);
      }
    }
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ক্যাটাগরি সিলেক্ট করুন')));
      return;
    }

    setState(() => _loading = true);

    try {
      final body = {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'category_id': _selectedCategoryId,
        'experience': num.tryParse(_experienceController.text.trim()) ?? 0,
        'hourly_price': num.tryParse(_priceController.text.trim()) ?? 0,
        'skills': _skillsController.text.trim().isEmpty ? null : _skillsController.text.trim(),
        'service_area': _areaController.text.trim().isEmpty ? null : _areaController.text.trim(),
        'availability': _available ? 1 : 0,
        'description': _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      };

      final response = await _api.post('/worker/apply', body: body);

      if (_pickedImages.isNotEmpty) {
        final targetId = _extractTargetId(response);
        if (targetId != null) {
          await _api.postMultipart(
            '/media/upload',
            fields: {
              'section': 'workers',
              'target_type': 'worker',
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('কর্মী যোগ হয়েছে')));
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('সাবমিট ব্যর্থ হয়েছে')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  int? _extractTargetId(dynamic response) {
    if (response is! Map<String, dynamic>) return null;
    final worker = response['worker'];
    if (worker is Map<String, dynamic>) {
      return (worker['id'] as num?)?.toInt();
    }
    return null;
  }

  Future<void> _fillCurrentLocation() async {
    // no-op: map picker removed; keep method for compatibility if needed later
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: const ModernAppBar(title: 'কর্মী যোগ করুন', subtitle: 'তথ্য পূরণ করুন'),
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
                _field(
                  controller: _nameController,
                  label: 'কর্মীর নাম',
                  required: true,
                ),
                _field(
                  controller: _phoneController,
                  label: 'ফোন নম্বর',
                  required: true,
                  hint: '১১ ডিজিট',
                  keyboard: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(11),
                  ],
                  validator: (v) {
                    final value = v?.trim() ?? '';
                    if (value.isEmpty) return 'ফোন নম্বর আবশ্যক';
                    if (!RegExp(r'^\d{11}$').hasMatch(value)) {
                      return '১১ ডিজিটের সঠিক নম্বর দিন';
                    }
                    return null;
                  },
                ),
                _field(
                  controller: _addressController,
                  label: 'ঠিকানা',
                  required: true,
                  hint: 'ল্যাট, লং লিখুন (যেমন: 22.45, 90.38)',
                ),
                _categoryDropdown(scheme),
                _field(
                  controller: _experienceController,
                  label: 'অভিজ্ঞতা (বছর)',
                  required: false,
                  hint: 'না দিলে ও হবে',
                  keyboard: TextInputType.number,
                ),
                _field(
                  controller: _priceController,
                  label: 'ঘন্টা প্রতি মূল্য',
                  required: false,
                  hint: 'না দিলে ও হবে',
                  keyboard: TextInputType.number,
                ),
                _field(
                  controller: _skillsController,
                  label: 'স্কিলস',
                  required: false,
                  hint: 'না দিলে ও হবে',
                ),
                _field(
                  controller: _areaController,
                  label: 'সার্ভিস এরিয়া',
                  required: false,
                  hint: 'না দিলে ও হবে',
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _available,
                  onChanged: (v) => setState(() => _available = v),
                  title: const Text('এভেইলেবল'),
                  subtitle: Text(_available ? 'হ্যাঁ' : 'না', style: TextStyle(color: scheme.onSurfaceVariant)),
                ),
                _field(
                  controller: _descriptionController,
                  label: 'বিবরণ',
                  required: false,
                  hint: 'না দিলে ও হবে',
                  maxLines: 3,
                ),
                _imagePickerSection(scheme),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('সাবমিট করুন'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required bool required,
    String? hint,
    TextInputType? keyboard,
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    Widget? suffixIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard ?? TextInputType.text,
        maxLines: maxLines,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(labelText: label, hintText: hint, suffixIcon: suffixIcon),
        validator: validator ??
            (v) {
              if (required && (v == null || v.trim().isEmpty)) {
                return '$label আবশ্যক';
              }
              return null;
            },
      ),
    );
  }

  Widget _categoryDropdown(ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<int>(
        value: _selectedCategoryId,
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'ক্যাটাগরি'),
        items: _categories
            .map(
              (c) => DropdownMenuItem<int>(
                value: (c['id'] as num?)?.toInt(),
                child: Text(c['name']?.toString() ?? '-'),
              ),
            )
            .toList(),
        onChanged: _loadingCategories
            ? null
            : (val) {
                setState(() => _selectedCategoryId = val);
              },
        validator: (val) => val == null ? 'ক্যাটাগরি নির্বাচন করুন' : null,
        hint: _loadingCategories ? const Text('লোড হচ্ছে...') : const Text('ক্যাটাগরি নির্বাচন করুন'),
        style: TextStyle(color: scheme.onSurface),
      ),
    );
  }

  Widget _imagePickerSection(ColorScheme scheme) {
    return Container(
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
    );
  }
}
