import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb, Uint8List;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/migo_gradients.dart';
import '../../core/theme/migo_theme.dart';
import '../../models/offer_model.dart';
import '../../services/cloudinary_service.dart';
import '../../services/offer_service.dart';

/// PHASE I — Advanced Create/Edit Offer
class CreateOfferScreen extends StatefulWidget {
  const CreateOfferScreen({
    super.key,
    required this.businessId,
    required this.businessName,
    required this.areaId,
    this.existingOffer,
  });

  final String businessId;
  final String businessName;
  final String areaId;
  final OfferModel? existingOffer;

  @override
  State<CreateOfferScreen> createState() => _CreateOfferScreenState();
}

class _CreateOfferScreenState extends State<CreateOfferScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _originalPriceCtrl = TextEditingController();
  final _offerPriceCtrl = TextEditingController();
  final _termsCtrl = TextEditingController();
  final _dailyLimitCtrl = TextEditingController();

  String _type = 'standard';
  int _durationDays = 7;
  bool _loading = false;
  bool _uploadingImage = false;
  String? _error;
  String? _imageUrl;

  // Image picking
  File? _pickedFile;
  Uint8List? _pickedBytes;
  String? _pickedFilename;
  final _picker = ImagePicker();

  bool get isEdit => widget.existingOffer != null;

  static const _offerTypes = [
    {'value': 'standard', 'label': 'Standard Deal'},
    {'value': 'flash', 'label': 'Flash Deal'},
    {'value': 'hidden', 'label': 'Hidden Gem'},
    {'value': 'birthday', 'label': 'Birthday Special'},
    {'value': 'group', 'label': 'Group Deal'},
  ];

  @override
  void initState() {
    super.initState();
    final o = widget.existingOffer;
    if (o != null) {
      _titleCtrl.text = o.title;
      _descCtrl.text = o.description;
      _originalPriceCtrl.text = o.originalPrice.toStringAsFixed(0);
      _offerPriceCtrl.text = o.offerPrice.toStringAsFixed(0);
      _imageUrl = o.imageUrl.isNotEmpty ? o.imageUrl : null;
      _type = o.type.isNotEmpty ? o.type : 'standard';
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _originalPriceCtrl.dispose();
    _offerPriceCtrl.dispose();
    _termsCtrl.dispose();
    _dailyLimitCtrl.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════
  // IMAGE PICKER
  // ═══════════════════════════════════════════════════
  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (picked == null) return;

      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _pickedBytes = bytes;
          _pickedFilename = picked.name;
          _pickedFile = null;
        });
      } else {
        setState(() {
          _pickedFile = File(picked.path);
          _pickedBytes = null;
          _pickedFilename = null;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  void _clearImage() {
    setState(() {
      _pickedFile = null;
      _pickedBytes = null;
      _pickedFilename = null;
      _imageUrl = null;
    });
  }

  // ═══════════════════════════════════════════════════
  // SUBMIT
  // ═══════════════════════════════════════════════════
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Upload image if picked
      String? imageUrl = _imageUrl;
      if (_pickedFile != null || _pickedBytes != null) {
        setState(() => _uploadingImage = true);
        final uploaded = await CloudinaryService.instance.upload(
          file: _pickedFile,
          bytes: _pickedBytes,
          filename: _pickedFilename,
          folder: 'migo/offers',
        );
        setState(() => _uploadingImage = false);

        if (uploaded == null) {
          if (!mounted) return;
          setState(() {
            _error = 'Failed to upload image. Try again.';
            _loading = false;
          });
          return;
        }
        imageUrl = uploaded;
      }

      String? err;
      if (isEdit) {
        err = await OfferService.instance.updateOffer(
          offerId: widget.existingOffer!.id,
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          category: _type,
          imageUrl: imageUrl ?? '',
          originalPrice:
              double.tryParse(_originalPriceCtrl.text.trim()) ?? 0,
          offerPrice:
              double.tryParse(_offerPriceCtrl.text.trim()) ?? 0,
          endDate: null,
        );
      } else {
        err = await OfferService.instance.createOffer(
          businessId: widget.businessId,
          businessName: widget.businessName,
          areaId: widget.areaId,
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          category: _type,
          imageUrl: imageUrl ?? '',
          originalPrice:
              double.tryParse(_originalPriceCtrl.text.trim()) ?? 0,
          offerPrice:
              double.tryParse(_offerPriceCtrl.text.trim()) ?? 0,
          currency: 'QAR',
          type: _type,
        );
      }

      if (!mounted) return;

      if (err == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEdit
                  ? 'Offer updated!'
                  : 'Offer created! Waiting for admin approval.',
            ),
            backgroundColor: MigoColors.success,
          ),
        );
        Navigator.pop(context);
      } else {
        setState(() {
          _error = err;
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed: $e';
        _loading = false;
      });
    }
  }

  // ═══════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final previewSavings =
        (double.tryParse(_originalPriceCtrl.text) ?? 0) -
            (double.tryParse(_offerPriceCtrl.text) ?? 0);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Offer' : 'Create Offer'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _imagePickerCard(),
                    const SizedBox(height: 20),

                    // Title
                    TextFormField(
                      controller: _titleCtrl,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Offer title',
                        hintText: 'e.g. Family Meal Deal',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Required'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Required'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // Offer Type
                    DropdownButtonFormField<String>(
                      initialValue: _type,
                      decoration: const InputDecoration(
                        labelText: 'Offer type',
                        border: OutlineInputBorder(),
                      ),
                      items: _offerTypes
                          .map((t) => DropdownMenuItem(
                                value: t['value'],
                                child: Text(t['label']!),
                              ))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _type = v ?? 'standard'),
                    ),
                    const SizedBox(height: 16),

                    // Prices
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _originalPriceCtrl,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            onChanged: (_) => setState(() {}),
                            decoration: const InputDecoration(
                              labelText: 'Original price',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Required';
                              }
                              if (double.tryParse(v) == null) {
                                return 'Invalid';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _offerPriceCtrl,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            onChanged: (_) => setState(() {}),
                            decoration: const InputDecoration(
                              labelText: 'MIGO price',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Required';
                              }
                              final n = double.tryParse(v);
                              if (n == null) return 'Invalid';
                              final orig = double.tryParse(
                                  _originalPriceCtrl.text);
                              if (orig != null && n >= orig) {
                                return 'Must be < original';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),

                    // Savings preview
                    if (previewSavings > 0) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color:
                              MigoColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              size: 18,
                              color: MigoColors.success,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Customer saves QAR ${previewSavings.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: MigoColors.success,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Duration
                    DropdownButtonFormField<int>(
                      initialValue: _durationDays,
                      decoration: const InputDecoration(
                        labelText: 'Duration',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('1 day')),
                        DropdownMenuItem(value: 3, child: Text('3 days')),
                        DropdownMenuItem(value: 7, child: Text('7 days')),
                        DropdownMenuItem(
                            value: 14, child: Text('14 days')),
                        DropdownMenuItem(
                            value: 30, child: Text('30 days')),
                      ],
                      onChanged: (v) =>
                          setState(() => _durationDays = v ?? 7),
                    ),
                    const SizedBox(height: 16),

                    // Daily limit
                    TextFormField(
                      controller: _dailyLimitCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Daily limit (optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Terms
                    TextFormField(
                      controller: _termsCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Terms (optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    // Error
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border:
                              Border.all(color: Colors.red.shade200),
                        ),
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _submit,
                        child: _loading
                            ? Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  ),
                                  if (_uploadingImage) ...[
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Uploading image…',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ],
                              )
                            : Text(
                                isEdit
                                    ? 'Update Offer'
                                    : 'Create Offer',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'New offers start as pending and go live once approved by MIGO.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: MigoColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // IMAGE PICKER CARD
  // ═══════════════════════════════════════════════════
  Widget _imagePickerCard() {
    final hasImage = _pickedFile != null ||
        _pickedBytes != null ||
        (_imageUrl != null && _imageUrl!.isNotEmpty);

    return Container(
      decoration: BoxDecoration(
        color: MigoColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MigoColors.divider),
      ),
      child: Column(
        children: [
          if (hasImage)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: kIsWeb && _pickedBytes != null
                    ? Image.memory(_pickedBytes!, fit: BoxFit.cover)
                    : _pickedFile != null
                        ? Image.file(_pickedFile!, fit: BoxFit.cover)
                        : Image.network(
                            _imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Center(
                              child: Icon(
                                Icons.broken_image_outlined,
                                size: 48,
                                color: MigoColors.textSecondary,
                              ),
                            ),
                          ),
              ),
            )
          else
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                decoration: BoxDecoration(
                  gradient: MigoGradients.softBlue,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image_outlined,
                      size: 48,
                      color: MigoColors.primary,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Add a photo to your offer',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: MigoColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Businesses with photos get 3× more claims',
                      style: TextStyle(
                        fontSize: 11,
                        color: MigoColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        _pickImage(ImageSource.gallery),
                    icon: const Icon(
                      Icons.photo_library_outlined,
                      size: 16,
                    ),
                    label: Text(
                      hasImage ? 'Change' : 'Gallery',
                      style: const TextStyle(fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(
                      Icons.camera_alt_outlined,
                      size: 16,
                    ),
                    label: const Text(
                      'Camera',
                      style: TextStyle(fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ),
                if (hasImage) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: _clearImage,
                    icon: const Icon(
                      Icons.delete_outline,
                      color: MigoColors.error,
                    ),
                    tooltip: 'Remove image',
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}