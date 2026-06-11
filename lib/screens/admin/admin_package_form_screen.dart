// lib/screens/admin/admin_package_form_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/menu_package.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../services/menu_service_supabase.dart';

class AdminPackageFormScreen extends StatefulWidget {
  final MenuPackage? package;

  const AdminPackageFormScreen({super.key, required this.package});

  @override
  State<AdminPackageFormScreen> createState() =>
      _AdminPackageFormScreenState();
}

class _AdminPackageFormScreenState extends State<AdminPackageFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _menuService = MenuService();
  final _supabase = Supabase.instance.client;
  final _picker = ImagePicker();

  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _minCtrl;
  late TextEditingController _maxCtrl;
  late TextEditingController _includeCtrl;

  String _category = 'All';
  bool _isAvailable = true;
  bool _isSaving = false;
  bool _isUploadingImage = false;
  List<String> _imageUrls = [];
  List<String> _includes = [];
  final _categories = ['All', 'Western', 'Asian', 'Fusion', 'Local'];

  bool get _isEditing => widget.package != null;

  @override
  void initState() {
    super.initState();
    final pkg = widget.package;
    _nameCtrl = TextEditingController(text: pkg?.name ?? '');
    _descCtrl = TextEditingController(text: pkg?.description ?? '');
    _priceCtrl = TextEditingController(
        text: pkg?.pricePerGuest.toStringAsFixed(0) ?? '');
    _minCtrl = TextEditingController(text: '${pkg?.minGuests ?? 10}');
    _maxCtrl = TextEditingController(text: '${pkg?.maxGuests ?? 200}');
    _includeCtrl = TextEditingController();
    _category = pkg?.category ?? 'All';
    _isAvailable = pkg?.isAvailable ?? true;
    _imageUrls = List.from(pkg?.imageUrls ?? []);
    _includes = List.from(pkg?.includes ?? []);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _minCtrl.dispose();
    _maxCtrl.dispose();
    _includeCtrl.dispose();
    super.dispose();
  }

  // Pick image from gallery and upload to Supabase Storage
  Future<void> _pickAndUploadImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked == null) return;

    setState(() => _isUploadingImage = true);

    try {
      final file = File(picked.path);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${picked.name}';
      final filePath = 'menu/$fileName';

      // Upload to Supabase Storage
      await _supabase.storage
          .from('Reference')
          .upload(filePath, file);

      // Get public URL
      final publicUrl = _supabase.storage
          .from('Reference')
          .getPublicUrl(filePath);

      setState(() => _imageUrls.add(publicUrl));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Upload failed: $e'),
        backgroundColor: AppColors.error,
      ));
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  // Delete image from Storage and remove from list
  Future<void> _removeImage(int index) async {
    final url = _imageUrls[index];

    // Extract path from URL to delete from storage
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      final bucketIndex = pathSegments.indexOf('Reference');
      if (bucketIndex != -1) {
        final storagePath = pathSegments.sublist(bucketIndex + 1).join('/');
        await _supabase.storage.from('Reference').remove([storagePath]);
      }
    } catch (_) {
      // If delete from storage fails, still remove from list
    }

    setState(() => _imageUrls.removeAt(index));
  }

  void _addInclude() {
    final item = _includeCtrl.text.trim();
    if (item.isNotEmpty) {
      setState(() => _includes.add(item));
      _includeCtrl.clear();
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please add at least one image'),
        backgroundColor: AppColors.error,
      ));
      return;
    }

    setState(() => _isSaving = true);
    try {
      final pkg = MenuPackage(
        id: widget.package?.id ?? '',
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        pricePerGuest: double.parse(_priceCtrl.text),
        imageUrls: _imageUrls,
        includes: _includes,
        category: _category,
        minGuests: int.tryParse(_minCtrl.text) ?? 10,
        maxGuests: int.tryParse(_maxCtrl.text) ?? 200,
        isAvailable: _isAvailable,
        orderCount: widget.package?.orderCount ?? 0,
        createdAt: widget.package?.createdAt ?? DateTime.now(),
      );

      if (_isEditing) {
        await _menuService.updatePackage(pkg);
      } else {
        await _menuService.addPackage(pkg);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_isEditing
            ? 'Package updated successfully'
            : 'Package added successfully'),
        backgroundColor: AppColors.success,
      ));
      context.pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'),
        backgroundColor: AppColors.error,
      ));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Package' : 'Add Package'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Name
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Package Name'),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 14),

            // Category
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: _categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v ?? 'All'),
            ),
            const SizedBox(height: 14),

            // Price
            TextFormField(
              controller: _priceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Price Per Guest (RM)',
                prefixText: 'RM ',
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                if (double.tryParse(v) == null) return 'Invalid price';
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Min/Max guests
            Row(children: [
              Expanded(
                child: TextFormField(
                  controller: _minCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Min Guests'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _maxCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Max Guests'),
                ),
              ),
            ]),
            const SizedBox(height: 14),

            // Description
            TextFormField(
              controller: _descCtrl,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Description'),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 14),

            // Available switch
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                const Text('Available for booking',
                    style: TextStyle(fontSize: 15)),
                const Spacer(),
                Switch(
                  value: _isAvailable,
                  onChanged: (v) => setState(() => _isAvailable = v),
                  activeColor: AppColors.secondary,
                ),
              ]),
            ),
            const SizedBox(height: 20),

            // ── Image Upload Section ──────────────────────────────
            const Text('Package Images',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AppColors.textDark)),
            const SizedBox(height: 8),

            // Image previews
            if (_imageUrls.isNotEmpty) ...[
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _imageUrls.length,
                  itemBuilder: (ctx, i) => Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: NetworkImage(_imageUrls[i]),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 12,
                        child: GestureDetector(
                          onTap: () => _removeImage(i),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close,
                                size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Upload button
            GestureDetector(
              onTap: _isUploadingImage ? null : _pickAndUploadImage,
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.secondary.withOpacity(0.5),
                      style: BorderStyle.solid),
                ),
                child: _isUploadingImage
                    ? const Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.secondary)),
                      SizedBox(width: 10),
                      Text('Uploading...',
                          style:
                          TextStyle(color: AppColors.secondary)),
                    ],
                  ),
                )
                    : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate_outlined,
                        color: AppColors.secondary),
                    SizedBox(width: 8),
                    Text('Pick image from gallery',
                        style: TextStyle(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text("What's Included",
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AppColors.textDark)),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _includeCtrl,
                  decoration:
                  const InputDecoration(hintText: 'e.g. 5-course meal...'),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(onPressed: _addInclude, child: const Text('Add')),
            ]),
            const SizedBox(height: 8),
            ..._includes.asMap().entries.map((e) => ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.check_circle,
                  color: AppColors.success, size: 16),
              title:
              Text(e.value, style: const TextStyle(fontSize: 13)),
              trailing: IconButton(
                icon: const Icon(Icons.remove_circle_outline,
                    color: AppColors.cancelRed, size: 18),
                onPressed: () =>
                    setState(() => _includes.removeAt(e.key)),
              ),
            )),
            const SizedBox(height: 24),

            GoldButton(
              text: _isEditing ? 'UPDATE PACKAGE' : 'ADD PACKAGE',
              onPressed: _save,
              isLoading: _isSaving,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}