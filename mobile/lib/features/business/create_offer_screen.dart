import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, Uint8List;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/migo_colors.dart';
import '../../core/theme/migo_gradients.dart';
import '../../models/business_model.dart';
import '../../models/group_deal_model.dart';
import '../../models/offer_model.dart';
import '../../services/cloudinary_service.dart';
import '../../services/firestore_service.dart';

class CreateOfferScreen extends StatefulWidget {
  const CreateOfferScreen({super.key, required this.business});
  final BusinessModel business;

  @override
  State<CreateOfferScreen> createState() => _CreateOfferScreenState();
}

class _CreateOfferScreenState extends State<CreateOfferScreen> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _originalPrice = TextEditingController();
  final _offerPrice = TextEditingController();
  final _terms = TextEditingController();
  final _dailyLimit = TextEditingController();
  final _minGroup = TextEditingController(text: '5');
  final _maxGroup = TextEditingController();

  OfferType _type = OfferType.standard;
  int _durationDays = 7;
  bool _loading = false;
  String? _error;

  // Image handling
  File? _pickedFile;
  Uint8List? _pickedBytes;
  String? _pickedFilename;
  String? _uploadedImageUrl;
  bool _uploadingImage = false;

  final _picker = ImagePicker();

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _originalPrice.dispose();
    _offerPrice.dispose();
    _terms.dispose();
    _dailyLimit.dispose();
    _minGroup.dispose();
    _maxGroup.dispose();
    super.dispose();
  }

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
      _uploadedImageUrl = null;
    });
  }

  Future<void> _submit() async {
    setState(() => _error = null);

    final title = _title.text.trim();
    final desc = _description.text.trim();
    final origPrice = double.tryParse(_originalPrice.text.trim()) ?? 0;
    final offPrice = double.tryParse(_offerPrice.text.trim()) ?? 0;

    if (title.isEmpty || desc.isEmpty) {
      setState(() => _error = 'Please fill in title and description.');
      return;
    }
    if (origPrice <= 0 || offPrice <= 0) {
      setState(() => _error = 'Please enter valid prices.');
      return;
    }
    if (offPrice >= origPrice) {
      setState(
        () => _error = 'Offer price must be less than original price.',
      );
      return;
    }

    final minGroup = int.tryParse(_minGroup.text.trim()) ?? 5;
    final maxGroup = int.tryParse(_maxGroup.text.trim());
    if (_type == OfferType.group && minGroup < 2) {
      setState(() => _error = 'Minimum group size must be at least 2.');
      return;
    }

    setState(() => _loading = true);
    try {
      String? imageUrl = _uploadedImageUrl;
      if (_pickedFile != null || _pickedBytes != null) {
        setState(() => _uploadingImage = true);
        final uploaded = await CloudinaryService.instance.upload(
          file: _pickedFile,
          bytes: _pickedBytes,
          filename: _pickedFilename,
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

      final now = DateTime.now();
      final offer = OfferModel.newDraft(
        businessId: widget.business.id,
        businessName: widget.business.name,
        title: title,
        description: desc,
        originalPrice: origPrice,
        offerPrice: offPrice,
        currency: widget.business.currency,
        type: _type,
        startAt: now,
        endAt: now.add(Duration(days: _durationDays)),
        category: widget.business.category,
        terms: _terms.text.trim().isEmpty ? null : _terms.text.trim(),
        dailyLimit: int.tryParse(_dailyLimit.text.trim()),
      ).copyWith(imageUrl: imageUrl);

      final offerId = await FirestoreService.instance.createOffer(offer);

      if (_type == OfferType.group) {
        await FirestoreService.instance.createGroupDeal(
          GroupDealModel.newDraft(
            offerId: offerId,
            minParticipants: minGroup,
            maxParticipants: maxGroup,
            deadline: now.add(Duration(days: _durationDays)),
          ),
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Failed to create offer: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final previewSavings =
        (double.tryParse(_originalPrice.text) ?? 0) -
            (double.tryParse(_offerPrice.text) ?? 0);

    return Scaffold(
      appBar: AppBar(title: const Text('Create offer')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _imagePickerCard(),
              const SizedBox(height: 20),

              TextField(
                controller: _title,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Offer title',
                  hintText: 'Family Meal Deal',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _description,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<OfferType>(
                initialValue: _type,
                decoration: const InputDecoration(
                  labelText: 'Offer type',
                  border: OutlineInputBorder(),
                ),
                items: OfferType.values
                    .map(
                      (t) => DropdownMenuItem(
                        value: t,
                        child: Text(t.label),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _type = v ?? _type),
              ),
              if (_type == OfferType.group) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _minGroup,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Min people',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _maxGroup,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Max people (opt)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _originalPrice,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Original price',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _offerPrice,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'MIGO price',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              if (previewSavings > 0) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: MigoColors.success.withValues(alpha: 0.1),
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
                        'Customer saves ${widget.business.currency} '
                        '${previewSavings.toStringAsFixed(0)}',
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
                  DropdownMenuItem(value: 14, child: Text('14 days')),
                  DropdownMenuItem(value: 30, child: Text('30 days')),
                ],
                onChanged: (v) => setState(() => _durationDays = v ?? 7),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _dailyLimit,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Daily limit (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _terms,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Terms (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: const TextStyle(color: MigoColors.error),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
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
                      : const Text('Create offer'),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'New offers start as pending and go live once approved by MIGO.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: MigoColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imagePickerCard() {
    final hasImage = _pickedFile != null || _pickedBytes != null;

    return Container(
      decoration: BoxDecoration(
        color: MigoColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MigoColors.divider(context)),
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
                        : const SizedBox(),
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
                        color: MigoColors.textPrimaryLight,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Businesses with photos get 3× more claims',
                      style: TextStyle(
                        fontSize: 11,
                        color: MigoColors.textSecondaryLight,
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
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(
                      Icons.photo_library_outlined,
                      size: 16,
                    ),
                    label: Text(
                      hasImage ? 'Change' : 'Gallery',
                      style: const TextStyle(fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
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
                      padding: const EdgeInsets.symmetric(horizontal: 8),
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