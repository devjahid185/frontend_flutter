import 'package:frontend_flutter/core/widgets/logo_loader.dart';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import '../common/image_upload_preview.dart';

class MarketplaceItemAddScreen extends StatefulWidget {
  const MarketplaceItemAddScreen({super.key});

  @override
  State<MarketplaceItemAddScreen> createState() =>
      _MarketplaceItemAddScreenState();
}

class _MarketplaceItemAddScreenState extends State<MarketplaceItemAddScreen> {
  final _formKey = GlobalKey<FormState>();
  late final ApiClient _api = ApiClient(getToken: SessionStorage().getToken);

  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _deliveryController = TextEditingController();
  final _locationController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final _descriptionController = TextEditingController();

  final _categorySearchController = TextEditingController();

  final List<XFile> _pickedImages = [];
  final ImagePicker _picker = ImagePicker();

  bool _loading = false;
  bool _loadingCategories = true;
  String? _categoryError;
  List<Map<String, dynamic>> _categories = [];
  int? _selectedCategoryId;
  String _condition = 'used';
  bool _negotiable = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _deliveryController.dispose();
    _locationController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _descriptionController.dispose();
    _categorySearchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _loadingCategories = true;
      _categoryError = null;
    });
    try {
      final res = await _api.get('/items/category');
      if (res is List) {
        _categories = res
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ক্যাটাগরি সিলেক্ট করুন')));
      return;
    }

    setState(() => _loading = true);

    try {
      final body = <String, dynamic>{
        'category_id': _selectedCategoryId,
        'title': _titleController.text.trim(),
        'price': num.tryParse(_priceController.text.trim()) ?? 0,
        'condition': _condition,
        'negotiable': _negotiable ? 1 : 0,
      };

      final brand = _brandController.text.trim();
      final model = _modelController.text.trim();
      final delivery = _deliveryController.text.trim();
      final location = _locationController.text.trim();
      final lat = _latController.text.trim();
      final lng = _lngController.text.trim();
      final desc = _descriptionController.text.trim();

      if (brand.isNotEmpty) body['brand'] = brand;
      if (model.isNotEmpty) body['model'] = model;
      if (delivery.isNotEmpty) body['delivery'] = delivery;
      if (location.isNotEmpty) body['location'] = location;
      if (lat.isNotEmpty) body['location_lat'] = double.tryParse(lat);
      if (lng.isNotEmpty) body['location_lng'] = double.tryParse(lng);
      if (desc.isNotEmpty) body['description'] = desc;

      final response = await _api.post('/items/add', body: body);

      if (_pickedImages.isNotEmpty) {
        final targetId = _extractTargetId(response);
        if (targetId != null) {
          await _api.postMultipart(
            '/media/upload',
            fields: {
              'section': 'marketplace',
              'target_type': 'marketplace_item',
              'target_id': '$targetId',
              'set_primary': 'true',
            },
            files: {'images[]': _pickedImages.map((e) => e.path).toList()},
          );
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('আইটেম যোগ হয়েছে')));
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('সাবমিট ব্যর্থ হয়েছে')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  int? _extractTargetId(dynamic response) {
    if (response is! Map<String, dynamic>) return null;
    final item = response['item'];
    if (item is Map<String, dynamic>) {
      return (item['id'] as num?)?.toInt();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xfff4f7f6),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        children: [
          const _AddItemHeader(title: 'আইটেম পোস্ট করুন'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xffe6f1ee),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xffd7e8e2)),
            ),
            child: Text(
              'সঠিক তথ্য দিলে দ্রুত বিক্রি হবে।',
              style: const TextStyle(
                color: Color(0xff006a4e),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Form(
            key: _formKey,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xffe5e7eb)),
              ),
              child: Column(
                children: [
                  _field(
                    controller: _titleController,
                    label: 'শিরোনাম',
                    required: true,
                  ),
                  _categoryDropdown(scheme),
                  _field(
                    controller: _priceController,
                    label: 'মূল্য',
                    required: true,
                    keyboard: TextInputType.number,
                  ),
                  _conditionRow(scheme),
                  _field(
                    controller: _brandController,
                    label: 'ব্র্যান্ড',
                    required: false,
                  ),
                  _field(
                    controller: _modelController,
                    label: 'মডেল',
                    required: false,
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _negotiable,
                    activeThumbColor: const Color(0xff006a4e),
                    onChanged: (v) => setState(() => _negotiable = v),
                    title: const Text(
                      'দাম আলোচনাযোগ্য',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    subtitle: Text(
                      _negotiable ? 'হ্যাঁ' : 'না',
                      style: const TextStyle(color: Color(0xff4b5563)),
                    ),
                  ),
                  _field(
                    controller: _deliveryController,
                    label: 'ডেলিভারি/হ্যান্ডওভার',
                    required: false,
                    hint: 'যেমন: নিজে এসে নিন / কুরিয়ার',
                  ),
                  _field(
                    controller: _locationController,
                    label: 'লোকেশন',
                    required: false,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _field(
                          controller: _latController,
                          label: 'Lat',
                          required: false,
                          keyboard: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _field(
                          controller: _lngController,
                          label: 'Lng',
                          required: false,
                          keyboard: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  _field(
                    controller: _descriptionController,
                    label: 'বিবরণ',
                    required: false,
                    maxLines: 3,
                  ),
                  _imagePickerSection(scheme),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: _loading ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xff006a4e),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: LogoLoader(size: 18),
                            )
                          : const Text('সাবমিট করুন'),
                    ),
                  ),
                ],
              ),
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
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard ?? TextInputType.text,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label, hintText: hint),
        validator: (v) {
          if (required && (v == null || v.trim().isEmpty)) {
            return '$label আবশ্যক';
          }
          return null;
        },
      ),
    );
  }

  Widget _conditionRow(ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: ChoiceChip(
              label: const Text('নতুন'),
              selected: _condition == 'new',
              onSelected: (_) => setState(() => _condition = 'new'),
              selectedColor: const Color(0xffe6f1ee),
              backgroundColor: Colors.white,
              side: const BorderSide(color: Color(0xffe5e7eb)),
              labelStyle: TextStyle(
                color: _condition == 'new'
                    ? const Color(0xff006a4e)
                    : const Color(0xff4b5563),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ChoiceChip(
              label: const Text('ব্যবহৃত'),
              selected: _condition == 'used',
              onSelected: (_) => setState(() => _condition = 'used'),
              selectedColor: const Color(0xffe6f1ee),
              backgroundColor: Colors.white,
              side: const BorderSide(color: Color(0xffe5e7eb)),
              labelStyle: TextStyle(
                color: _condition == 'used'
                    ? const Color(0xff006a4e)
                    : const Color(0xff4b5563),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: _loadingCategories ? null : _openCategoryPicker,
            borderRadius: BorderRadius.circular(16),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'ক্যাটাগরি',
                prefixIcon: const Icon(Icons.category_outlined),
                suffixIcon: _loadingCategories
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: LogoLoader(size: 16),
                        ),
                      )
                    : const Icon(Icons.keyboard_arrow_down_rounded),
              ),
              isEmpty: selectedName == null || selectedName.trim().isEmpty,
              child: Text(
                (selectedName == null || selectedName.trim().isEmpty)
                    ? 'ক্যাটাগরি নির্বাচন করুন'
                    : selectedName,
                style: TextStyle(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          if (_categoryError != null) ...[
            const SizedBox(height: 6),
            Text(
              _categoryError!,
              style: const TextStyle(color: Color(0xffdc2626), fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openCategoryPicker() async {
    _categorySearchController.clear();
    var filtered = List<Map<String, dynamic>>.from(_categories);

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
                                      setSheetState(
                                        () => filtered =
                                            List<Map<String, dynamic>>.from(
                                              _categories,
                                            ),
                                      );
                                    },
                                    icon: const Icon(Icons.close),
                                  ),
                          ),
                          onChanged: (value) {
                            final query = value.trim().toLowerCase();
                            setSheetState(() {
                              if (query.isEmpty) {
                                filtered = List<Map<String, dynamic>>.from(
                                  _categories,
                                );
                              } else {
                                filtered = _categories.where((c) {
                                  final name =
                                      c['name']?.toString().toLowerCase() ?? '';
                                  return name.contains(query);
                                }).toList();
                              }
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: filtered.isEmpty
                            ? Center(
                                child: Text(
                                  'কোনো ক্যাটাগরি পাওয়া যায়নি',
                                  style: TextStyle(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  16,
                                ),
                                itemCount: filtered.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final category = filtered[index];
                                  final id = (category['id'] as num?)?.toInt();
                                  final name =
                                      category['name']?.toString() ?? '-';
                                  final selected =
                                      id != null && id == _selectedCategoryId;
                                  return Material(
                                    color: selected
                                        ? scheme.primaryContainer
                                        : scheme.surfaceContainerLow,
                                    borderRadius: BorderRadius.circular(16),
                                    child: ListTile(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      title: Text(
                                        name,
                                        style: TextStyle(
                                          color: selected
                                              ? scheme.onPrimaryContainer
                                              : scheme.onSurface,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      trailing: selected
                                          ? Icon(
                                              Icons.check_circle,
                                              color: scheme.primary,
                                            )
                                          : Icon(
                                              Icons.arrow_forward_ios,
                                              size: 14,
                                              color: scheme.outline,
                                            ),
                                      onTap: () =>
                                          Navigator.of(context).pop(id),
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
        color: const Color(0xfff8faf9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xffe5e7eb)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ছবি যোগ করুন', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 6),
          Text(
            _pickedImages.isEmpty
                ? 'সর্বোচ্চ ১০টি ছবি'
                : 'সিলেক্টেড: ${_pickedImages.length} টি ছবি',
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
            PickedImagePreviewGrid(
              images: _pickedImages,
              onRemove: (index) =>
                  setState(() => _pickedImages.removeAt(index)),
            ),
          ],
        ],
      ),
    );
  }
}

class _AddItemHeader extends StatelessWidget {
  const _AddItemHeader({required this.title});

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
    );
  }
}
