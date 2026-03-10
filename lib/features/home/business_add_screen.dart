import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import '../common/modern_app_bar.dart';

class BusinessAddScreen extends StatefulWidget {
  const BusinessAddScreen({super.key});

  @override
  State<BusinessAddScreen> createState() => _BusinessAddScreenState();
}

class _BusinessAddScreenState extends State<BusinessAddScreen> {
  final _formKey = GlobalKey<FormState>();
  late final ApiClient _api = ApiClient(getToken: SessionStorage().getToken);

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _hoursController = TextEditingController();
  final _phoneController = TextEditingController();
  final _websiteController = TextEditingController();
  final _facebookController = TextEditingController();

  final List<XFile> _pickedImages = [];
  final ImagePicker _picker = ImagePicker();

  bool _loading = false;
  bool _loadingCategories = true;
  List<Map<String, dynamic>> _categories = [];
  int? _selectedCategoryId;
  String? _categoryError;
  final _categorySearchController = TextEditingController();
  List<Map<String, dynamic>> _filteredCategories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _hoursController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    _facebookController.dispose();
    _categorySearchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _loadingCategories = true;
      _categoryError = null;
    });
    try {
      final res = await _api.get('/business/categories');
      if (res is List) {
        _categories = res.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _filteredCategories = List<Map<String, dynamic>>.from(_categories);
        if (_selectedCategoryId == null && _categories.isNotEmpty) {
          _selectedCategoryId = (_categories.first['id'] as num?)?.toInt();
        }
      } else {
        _categoryError = 'ক্যাটাগরি লোড হয়নি';
      }
    } on ApiException catch (e) {
      _categoryError = e.message;
    } catch (_) {
      _categoryError = 'ক্যাটাগরি লোড হয়নি';
    } finally {
      if (mounted) setState(() => _loadingCategories = false);
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
      final body = <String, dynamic>{
        'name': _nameController.text.trim(),
        'category_id': _selectedCategoryId,
      };

      final description = _descriptionController.text.trim();
      final address = _addressController.text.trim();
      final hours = _hoursController.text.trim();
      final phone = _phoneController.text.trim();
      final website = _websiteController.text.trim();
      final facebook = _facebookController.text.trim();
      final latText = _latitudeController.text.trim();
      final lngText = _longitudeController.text.trim();

      if (description.isNotEmpty) body['description'] = description;
      if (address.isNotEmpty) body['address'] = address;
      if (hours.isNotEmpty) body['opening_hours'] = hours;
      if (phone.isNotEmpty) body['phone'] = phone;
      if (website.isNotEmpty) body['website'] = website;
      if (facebook.isNotEmpty) body['facebook_page'] = facebook;
      if (latText.isNotEmpty) body['latitude'] = double.tryParse(latText);
      if (lngText.isNotEmpty) body['longitude'] = double.tryParse(lngText);

      final response = await _api.post('/business/add', body: body);

      if (_pickedImages.isNotEmpty) {
        final targetId = _extractTargetId(response);
        if (targetId != null) {
          await _api.postMultipart(
            '/media/upload',
            fields: {
              'section': 'business',
              'target_type': 'business',
              'target_id': '$targetId',
              'set_primary': '1',
            },
            files: {
              'images[]': _pickedImages.map((e) => e.path).toList(),
            },
          );
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ব্যবসা যোগ হয়েছে')));
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
    final business = response['business'];
    if (business is Map<String, dynamic>) {
      return (business['id'] as num?)?.toInt();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: const ModernAppBar(title: 'ব্যবসা যোগ করুন', subtitle: 'তথ্য পূরণ করুন'),
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
                  label: 'ব্যবসার নাম',
                  required: true,
                ),
                _categoryDropdown(scheme),
                if (_categoryError != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Expanded(child: Text(_categoryError!, style: TextStyle(color: scheme.error))),
                        TextButton(
                          onPressed: _loadingCategories ? null : _loadCategories,
                          child: const Text('রিফ্রেশ'),
                        ),
                      ],
                    ),
                  ),
                _field(
                  controller: _descriptionController,
                  label: 'বিবরণ',
                  required: false,
                  maxLines: 3,
                  hint: 'ঐচ্ছিক',
                ),
                _field(
                  controller: _addressController,
                  label: 'ঠিকানা',
                  required: false,
                  hint: 'ঐচ্ছিক',
                ),
                Row(
                  children: [
                    Expanded(
                      child: _field(
                        controller: _latitudeController,
                        label: 'অক্ষাংশ (Lat)',
                        required: false,
                        keyboard: TextInputType.number,
                        hint: 'ঐচ্ছিক',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _field(
                        controller: _longitudeController,
                        label: 'দ্রাঘিমাংশ (Lng)',
                        required: false,
                        keyboard: TextInputType.number,
                        hint: 'ঐচ্ছিক',
                      ),
                    ),
                  ],
                ),
                _field(
                  controller: _hoursController,
                  label: 'খোলা সময়',
                  required: false,
                  hint: 'যেমন: ৯টা - ৯টা',
                ),
                _field(
                  controller: _phoneController,
                  label: 'ফোন নম্বর',
                  required: false,
                  hint: 'ঐচ্ছিক (১১ ডিজিট)',
                  keyboard: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(11),
                  ],
                  validator: (v) {
                    final value = v?.trim() ?? '';
                    if (value.isEmpty) return null;
                    if (!RegExp(r'^\d{11}$').hasMatch(value)) {
                      return '১১ ডিজিটের সঠিক নম্বর দিন';
                    }
                    return null;
                  },
                ),
                _linkField(
                  controller: _websiteController,
                  label: 'ওয়েবসাইট',
                  hint: 'https://example.com (ঐচ্ছিক)',
                  icon: Icons.public,
                ),
                _linkField(
                  controller: _facebookController,
                  label: 'ফেসবুক পেজ',
                  hint: 'https://facebook.com/yourpage (ঐচ্ছিক)',
                  icon: Icons.facebook,
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
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard ?? TextInputType.text,
        maxLines: maxLines,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(labelText: label, hintText: hint),
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

  Widget _linkField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.url,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon),
          filled: true,
        ),
      ),
    );
  }

  Widget _categoryDropdown(ColorScheme scheme) {
    final selectedName = _categories
        .firstWhere(
          (c) => (c['id'] as num?)?.toInt() == _selectedCategoryId,
          orElse: () => {'name': ''},
        )['name']
        ?.toString();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: _loadingCategories ? null : _openCategoryPicker,
        borderRadius: BorderRadius.circular(16),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: 'ক্যাটাগরি',
            prefixIcon: const Icon(Icons.category_outlined),
            suffixIcon: _loadingCategories
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : const Icon(Icons.keyboard_arrow_down_rounded),
          ),
          isEmpty: selectedName == null || selectedName.trim().isEmpty,
          child: Text(
            (selectedName == null || selectedName.trim().isEmpty) ? 'ক্যাটাগরি নির্বাচন করুন' : selectedName,
            style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  Future<void> _openCategoryPicker() async {
    if (_loadingCategories) return;

    _categorySearchController.clear();
    _filteredCategories = List<Map<String, dynamic>>.from(_categories);

    final selected = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        return SafeArea(
          child: Padding(
            padding: MediaQuery.of(context).viewInsets,
            child: StatefulBuilder(
              builder: (context, setSheetState) {
                return SizedBox(
                  height: MediaQuery.of(context).size.height * 0.75,
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      Container(
                        width: 46,
                        height: 4,
                        decoration: BoxDecoration(
                          color: scheme.outlineVariant,
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TextField(
                          controller: _categorySearchController,
                          decoration: InputDecoration(
                            hintText: 'ক্যাটাগরি সার্চ করুন',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _categorySearchController.text.isEmpty
                                ? null
                                : IconButton(
                                    onPressed: () {
                                      _categorySearchController.clear();
                                      setSheetState(() {
                                        _filteredCategories = List<Map<String, dynamic>>.from(_categories);
                                      });
                                    },
                                    icon: const Icon(Icons.close),
                                  ),
                          ),
                          onChanged: (value) {
                            final query = value.trim().toLowerCase();
                            setSheetState(() {
                              if (query.isEmpty) {
                                _filteredCategories = List<Map<String, dynamic>>.from(_categories);
                              } else {
                                _filteredCategories = _categories.where((c) {
                                  final name = c['name']?.toString().toLowerCase() ?? '';
                                  return name.contains(query);
                                }).toList();
                              }
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: _filteredCategories.isEmpty
                            ? Center(
                                child: Text('কোনো ক্যাটাগরি পাওয়া যায়নি', style: TextStyle(color: scheme.onSurfaceVariant)),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                itemCount: _filteredCategories.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final category = _filteredCategories[index];
                                  final id = (category['id'] as num?)?.toInt();
                                  final name = category['name']?.toString() ?? '-';
                                  final selected = id != null && id == _selectedCategoryId;
                                  return Material(
                                    color: selected ? scheme.primaryContainer : scheme.surfaceContainerLow,
                                    borderRadius: BorderRadius.circular(16),
                                    child: ListTile(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      title: Text(
                                        name,
                                        style: TextStyle(
                                          color: selected ? scheme.onPrimaryContainer : scheme.onSurface,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      trailing: selected
                                          ? Icon(Icons.check_circle, color: scheme.primary)
                                          : Icon(Icons.arrow_forward_ios, size: 14, color: scheme.outline),
                                      onTap: () => Navigator.of(context).pop(id),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );

    if (!mounted) return;
    if (selected != null) {
      setState(() => _selectedCategoryId = selected);
    }
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
