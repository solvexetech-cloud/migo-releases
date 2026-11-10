import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb, Uint8List;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/localization/locale_provider.dart';
import '../../core/theme/migo_gradients.dart';
import '../../core/theme/migo_theme.dart';
import '../../models/offer_model.dart';
import '../../services/cloudinary_service.dart';
import '../../services/offer_service.dart';
import '../../services/translation_service.dart';

/// PHASE I â€” Advanced Create/Edit Offer with Reserve & Country
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
  
  final _whatsappCtrl = TextEditingController();
  final _orderLinkCtrl = TextEditingController();
  final _totalSlotsCtrl = TextEditingController(text: '10');
  final _maxPerCustomerCtrl = TextEditingController(text: '1');

  // Group Deal Controllers
  final _minGroupCtrl = TextEditingController(text: '5');
  final _maxGroupCtrl = TextEditingController();
  // ðŸ†• Plan A & Plan B controllers
  final _requiredClaimsCtrl = TextEditingController(text: '10');
  final _maxSlotsCtrl = TextEditingController(text: '13');
  final _groupTimerCtrl = TextEditingController(text: '48');
  final _redemptionWindowCtrl = TextEditingController(text: '24');
  final _floorPriceCtrl = TextEditingController();
  final _stepPriceCtrl = TextEditingController();

  // Dynamic Categories
  List<Map<String, String>> _dynamicCategories = [];
  bool _loadingCategories = true;

  String _type = 'standard';
  String _category = 'food'; 
  int _durationDays = 7;
  bool _isReservable = false;
  String _countryCode = 'QA';
  bool _lockOnSlotsFull = false; // ðŸ†• Plan B

  bool _loading = false;
  bool _uploadingImage = false;
  String? _error;
  String? _imageUrl;

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
    {'value': 'group_all_or_nothing', 'label': 'Group Deal (All-or-Nothing)'},
    {'value': 'group_progressive', 'label': 'Group Deal (Progressive)'},
  ];

  static const _countries = [
    {'code': 'QA', 'name': 'Qatar ðŸ‡¶ðŸ‡¦'},
    {'code': 'AE', 'name': 'UAE ðŸ‡¦ðŸ‡ª'},
    {'code': 'SA', 'name': 'Saudi Arabia ðŸ‡¸ðŸ‡¦'},
    {'code': 'KW', 'name': 'Kuwait ðŸ‡°ðŸ‡¼'},
    {'code': 'OM', 'name': 'Oman ðŸ‡´ðŸ‡²'},
    {'code': 'BH', 'name': 'Bahrain ðŸ‡§ðŸ‡­'},
    {'code': 'IN', 'name': 'India ðŸ‡®ðŸ‡³'},
  ];

  @override
  void initState() {
    super.initState();
    _loadBusinessCountry();
    _loadCategories();
    final o = widget.existingOffer;
        if (o != null) {
      _titleCtrl.text = o.title;
      _descCtrl.text = o.description;
      _originalPriceCtrl.text = o.originalPrice.toStringAsFixed(0);
      _offerPriceCtrl.text = o.offerPrice.toStringAsFixed(0);
            _imageUrl = (o.imageUrl != null && o.imageUrl!.isNotEmpty)
          ? o.imageUrl
          : null;
      _type = o.type.id;
      if (o.category.isNotEmpty) _category = o.category;
      // ðŸ†• Plan A/B fields load
      if (o.requiredClaims != null) {
        _requiredClaimsCtrl.text = o.requiredClaims.toString();
      }
      if (o.maxSlots != null) _maxSlotsCtrl.text = o.maxSlots.toString();
      if (o.groupTimerHours != null) {
        _groupTimerCtrl.text = o.groupTimerHours.toString();
      }
      if (o.redemptionWindowHours != null) {
        _redemptionWindowCtrl.text = o.redemptionWindowHours.toString();
      }
      if (o.floorPrice != null) _floorPriceCtrl.text = o.floorPrice.toString();
      if (o.stepPrice != null) _stepPriceCtrl.text = o.stepPrice.toString();
      _lockOnSlotsFull = o.lockOnSlotsFull;
    }
  }

    Future<void> _loadCategories() async {
    try {
      // ðŸ†• orderBy à´’à´´à´¿à´µà´¾à´•àµà´•à´¿, à´²à´­à´¿à´šàµà´šà´¤à´¿à´¨àµ† à´†à´ªàµà´ªà´¿àµ½ à´µàµ†à´šàµà´šàµ à´¸àµ‹àµ¼à´Ÿàµà´Ÿàµ à´šàµ†à´¯àµà´¯àµà´¨àµà´¨àµ
      final snap = await FirebaseFirestore.instance
          .collection('categories')
          .where('active', isEqualTo: true)
          .get();

      if (mounted) {
        final loadedCats = snap.docs.map((doc) {
          final data = doc.data();
          return <String, String>{
            'value': doc.id,
            'label': (data['name'] as String?) ?? doc.id,
          };
        }).toList();

        // à´ªàµ‡à´°à´¿à´¨àµà´±àµ† à´…à´•àµà´·à´°à´®à´¾à´² à´•àµà´°à´®à´¤àµà´¤à´¿àµ½ à´¸àµ‹àµ¼à´Ÿàµà´Ÿàµ à´šàµ†à´¯àµà´¯àµà´¨àµà´¨àµ (Order à´«àµ€àµ½à´¡àµ à´‡à´²àµà´²àµ†à´™àµà´•à´¿àµ½ à´ªàµ‹à´²àµà´‚ à´µàµ¼à´•àµà´•àµ à´šàµ†à´¯àµà´¯àµà´‚)
        loadedCats.sort((a, b) => (a['label'] ?? '').compareTo(b['label'] ?? ''));

        setState(() {
          _dynamicCategories = loadedCats;
          
          if (_dynamicCategories.isNotEmpty && !_dynamicCategories.any((c) => c['value'] == _category)) {
            _category = _dynamicCategories.first['value']!;
          }
          _loadingCategories = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading categories: $e'); // ðŸ†• à´Žà´±àµ¼ à´•àµºà´¸àµ‹à´³à´¿àµ½ à´•à´¾à´£à´¾àµ»
      if (mounted) setState(() => _loadingCategories = false);
    }
  }

  Future<void> _loadBusinessCountry() async {
    final bizSnap = await FirebaseFirestore.instance
        .collection('businesses')
        .doc(widget.businessId)
        .get();
    if (bizSnap.exists && mounted) {
      setState(() {
        _countryCode = bizSnap.data()?['countryCode'] as String? ?? 'QA';
      });
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
    _whatsappCtrl.dispose();
    _orderLinkCtrl.dispose();
    _totalSlotsCtrl.dispose();
    _maxPerCustomerCtrl.dispose();
    _minGroupCtrl.dispose();
    _maxGroupCtrl.dispose();
    _requiredClaimsCtrl.dispose();
    _maxSlotsCtrl.dispose();
    _groupTimerCtrl.dispose();
    _redemptionWindowCtrl.dispose();
    _floorPriceCtrl.dispose();
    _stepPriceCtrl.dispose();
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
      _imageUrl = null;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
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
            _error = LocaleProvider.instance.locale == 'ar'
                ? 'ÙØ´Ù„ ØªØ­Ù…ÙŠÙ„ Ø§Ù„ØµÙˆØ±Ø©. Ø­Ø§ÙˆÙ„ Ù…Ø±Ø© Ø£Ø®Ø±Ù‰.'
                : 'Failed to upload image. Try again.';
            _loading = false;
          });
          return;
        }
        imageUrl = uploaded;
      }

      final titleEn = _titleCtrl.text.trim();
      final descEn = _descCtrl.text.trim();
      
      String titleAr = titleEn;
      String descAr = descEn;
      
      if (titleEn.isNotEmpty) {
        titleAr = await TranslationService.instance.translate(titleEn, 'ar');
      }
      if (descEn.isNotEmpty) {
        descAr = await TranslationService.instance.translate(descEn, 'ar');
      }

      String? err;

      if (isEdit) {
                err = await OfferService.instance.updateOffer(
          offerId: widget.existingOffer!.id,
          title: titleEn,
          titleEn: titleEn,
          titleAr: titleAr,
          description: descEn,
          descriptionEn: descEn,
          descriptionAr: descAr,
          category: _category,
          type: _type,
          imageUrl: imageUrl ?? '',
          originalPrice: double.tryParse(_originalPriceCtrl.text.trim()) ?? 0,
          offerPrice: double.tryParse(_offerPriceCtrl.text.trim()) ?? 0,
          endDate: DateTime.now().add(Duration(days: _durationDays)),
          // ðŸ†• Plan A/B fields
          requiredClaims: _type == 'group_all_or_nothing'
              ? int.tryParse(_requiredClaimsCtrl.text)
              : null,
          maxSlots: _type == 'group_all_or_nothing'
              ? int.tryParse(_maxSlotsCtrl.text)
              : null,
          groupTimerHours: (_type == 'group_all_or_nothing' ||
                  _type == 'group_progressive')
              ? int.tryParse(_groupTimerCtrl.text)
              : null,
          redemptionWindowHours: (_type == 'group_all_or_nothing' ||
                  _type == 'group_progressive')
              ? int.tryParse(_redemptionWindowCtrl.text)
              : null,
          floorPrice: _type == 'group_progressive'
              ? double.tryParse(_floorPriceCtrl.text)
              : null,
          stepPrice: _type == 'group_progressive'
              ? double.tryParse(_stepPriceCtrl.text)
              : null,
          lockOnSlotsFull:
              _type == 'group_progressive' ? _lockOnSlotsFull : null,
        );
      } else {
                err = await OfferService.instance.createOffer(
          businessId: widget.businessId,
          businessName: widget.businessName,
          areaId: widget.areaId,
          title: titleEn,
          titleEn: titleEn,
          titleAr: titleAr,
          description: descEn,
          descriptionEn: descEn,
          descriptionAr: descAr,
          category: _category,
          imageUrl: imageUrl ?? '',
          originalPrice: double.tryParse(_originalPriceCtrl.text.trim()) ?? 0,
          offerPrice: double.tryParse(_offerPriceCtrl.text.trim()) ?? 0,
          currency: 'QAR',
          type: _type,
          countryCode: _countryCode,
          whatsappNumber: _whatsappCtrl.text.trim(),
          orderLink: _orderLinkCtrl.text.trim(),
          // ðŸ†• Plan A/B fields
          requiredClaims: _type == 'group_all_or_nothing'
              ? int.tryParse(_requiredClaimsCtrl.text)
              : null,
          maxSlots: _type == 'group_all_or_nothing'
              ? int.tryParse(_maxSlotsCtrl.text)
              : null,
          groupTimerHours: (_type == 'group_all_or_nothing' ||
                  _type == 'group_progressive')
              ? int.tryParse(_groupTimerCtrl.text)
              : null,
          redemptionWindowHours: (_type == 'group_all_or_nothing' ||
                  _type == 'group_progressive')
              ? int.tryParse(_redemptionWindowCtrl.text)
              : null,
          floorPrice: _type == 'group_progressive'
              ? double.tryParse(_floorPriceCtrl.text)
              : null,
          stepPrice: _type == 'group_progressive'
              ? double.tryParse(_stepPriceCtrl.text)
              : null,
          lockOnSlotsFull:
              _type == 'group_progressive' ? _lockOnSlotsFull : null,
        );

        // ðŸ†• Plan A / Plan B à´«àµ€àµ½à´¡àµà´•àµ¾
        // (OfferService-àµ½ createOffer-à´²àµ‡à´•àµà´•àµ à´¨àµ‡à´°à´¿à´Ÿàµà´Ÿàµ à´ªàµ‹à´•àµà´¨àµà´¨àµ,
        //  group_deals collection à´†à´µà´¶àµà´¯à´®à´¿à´²àµà´²)
      }

      if (!mounted) return;

      if (err == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEdit
                  ? (LocaleProvider.instance.locale == 'ar' ? 'ØªÙ… ØªØ­Ø¯ÙŠØ« Ø§Ù„Ø¹Ø±Ø¶!' : 'Offer updated!')
                  : (LocaleProvider.instance.locale == 'ar'
                      ? 'ØªÙ… Ø¥Ù†Ø´Ø§Ø¡ Ø§Ù„Ø¹Ø±Ø¶! ÙÙŠ Ø§Ù†ØªØ¸Ø§Ø± Ù…ÙˆØ§ÙÙ‚Ø© Ø§Ù„Ù…Ø³Ø¤ÙˆÙ„.'
                      : 'Offer created! Waiting for admin approval.'),
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

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocaleProvider.instance,
      builder: (context, _) {
        final isAr = LocaleProvider.instance.locale == 'ar';
        final previewSavings = (double.tryParse(_originalPriceCtrl.text) ?? 0) -
            (double.tryParse(_offerPriceCtrl.text) ?? 0);

        return Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            appBar: AppBar(
              title: Text(
                isEdit
                    ? (isAr ? 'ØªØ¹Ø¯ÙŠÙ„ Ø§Ù„Ø¹Ø±Ø¶' : 'Edit Offer')
                    : (isAr ? 'Ø¥Ù†Ø´Ø§Ø¡ Ø¹Ø±Ø¶' : 'Create Offer'),
              ),
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
                          _imagePickerCard(isAr),
                          const SizedBox(height: 20),

                          TextFormField(
                            controller: _titleCtrl,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              labelText: isAr ? 'Ø¹Ù†ÙˆØ§Ù† Ø§Ù„Ø¹Ø±Ø¶' : 'Offer title',
                              hintText: isAr ? 'Ù…Ø«Ø§Ù„: Ø¹Ø±Ø¶ ÙˆØ¬Ø¨Ø© Ø§Ù„Ø¹Ø§Ø¦Ù„Ø©' : 'e.g. Family Meal Deal',
                              border: const OutlineInputBorder(),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? (isAr ? 'Ù…Ø·Ù„ÙˆØ¨' : 'Required')
                                : null,
                          ),
                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _descCtrl,
                            maxLines: 3,
                            decoration: InputDecoration(
                              labelText: isAr ? 'Ø§Ù„ÙˆØµÙ' : 'Description',
                              border: const OutlineInputBorder(),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? (isAr ? 'Ù…Ø·Ù„ÙˆØ¨' : 'Required')
                                : null,
                          ),
                          const SizedBox(height: 16),

                          // ðŸ†• Dynamic Category Dropdown
                          _loadingCategories
                              ? const Center(child: CircularProgressIndicator())
                              : DropdownButtonFormField<String>(
                                  initialValue: _category,
                                  isExpanded: true, // Overflow à´«à´¿à´•àµà´¸àµ
                                  decoration: InputDecoration(
                                    labelText: isAr ? 'Ø§Ù„ÙØ¦Ø©' : 'Category',
                                    border: const OutlineInputBorder(),
                                  ),
                                  items: _dynamicCategories
                                      .map((t) => DropdownMenuItem(
                                            value: t['value'],
                                            child: Text(
                                              t['label']!,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ))
                                      .toList(),
                                  onChanged: (v) => setState(() => _category = v ?? ''),
                                ),
                          const SizedBox(height: 16),

                          DropdownButtonFormField<String>(
                            initialValue: _countryCode,
                            isExpanded: true, // Overflow à´«à´¿à´•àµà´¸àµ
                            decoration: InputDecoration(
                              labelText: isAr ? 'Ø§Ù„Ø¯ÙˆÙ„Ø©' : 'Country',
                              border: const OutlineInputBorder(),
                            ),
                            items: _countries
                                .map((c) => DropdownMenuItem(
                                      value: c['code'],
                                      child: Text(c['name']!),
                                    ))
                                .toList(),
                            onChanged: (v) => setState(() => _countryCode = v ?? 'QA'),
                          ),
                          const SizedBox(height: 16),

                          DropdownButtonFormField<String>(
                            initialValue: _type,
                            isExpanded: true, // Overflow à´«à´¿à´•àµà´¸àµ
                            decoration: InputDecoration(
                              labelText: isAr ? 'Ù†ÙˆØ¹ Ø§Ù„Ø¹Ø±Ø¶' : 'Offer type',
                              border: const OutlineInputBorder(),
                            ),
                            items: _offerTypes
                                .map((t) => DropdownMenuItem(
                                      value: t['value'],
                                      child: Text(t['label']!),
                                    ))
                                .toList(),
                            onChanged: (v) => setState(() => _type = v ?? 'standard'),
                          ),
                          
                                                    // ðŸ†• PLAN A â€” All-or-Nothing
                          if (_type == 'group_all_or_nothing') ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isAr
                                        ? 'Ø§Ù„Ø®Ø·Ø© Ø£: ÙƒÙ„ Ø´ÙŠØ¡ Ø£Ùˆ Ù„Ø§ Ø´ÙŠØ¡'
                                        : 'Plan A: All-or-Nothing Setup',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller: _requiredClaimsCtrl,
                                          keyboardType: TextInputType.number,
                                          decoration: InputDecoration(
                                            labelText: isAr
                                                ? 'Ø§Ù„Ù…Ø·Ø§Ù„Ø¨Ø§Øª Ø§Ù„Ù…Ø·Ù„ÙˆØ¨Ø© (N)'
                                                : 'Required Claims (N)',
                                            border:
                                                const OutlineInputBorder(),
                                            isDense: true,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: TextFormField(
                                          controller: _maxSlotsCtrl,
                                          keyboardType: TextInputType.number,
                                          decoration: InputDecoration(
                                            labelText: isAr
                                                ? 'Ø§Ù„Ø­Ø¯ Ø§Ù„Ø£Ù‚ØµÙ‰ Ù„Ù„ÙØªØ­Ø§Øª'
                                                : 'Max Slots',
                                            border:
                                                const OutlineInputBorder(),
                                            isDense: true,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller: _groupTimerCtrl,
                                          keyboardType: TextInputType.number,
                                          decoration: InputDecoration(
                                            labelText: isAr
                                                ? 'Ù…Ø¤Ù‚Øª Ø§Ù„Ø¹Ø±Ø¶ (Ø³Ø§Ø¹Ø§Øª)'
                                                : 'Deal Timer (hours)',
                                            border:
                                                const OutlineInputBorder(),
                                            isDense: true,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: TextFormField(
                                          controller: _redemptionWindowCtrl,
                                          keyboardType: TextInputType.number,
                                          decoration: InputDecoration(
                                            labelText: isAr
                                                ? 'Ù†Ø§ÙØ°Ø© Ø§Ù„Ø§Ø³ØªØ±Ø¯Ø§Ø¯ (Ø³Ø§Ø¹Ø§Øª)'
                                                : 'Redemption (hours)',
                                            border:
                                                const OutlineInputBorder(),
                                            isDense: true,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // ðŸ†• PLAN B â€” Progressive
                          if (_type == 'group_progressive') ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.purple.shade50,
                                borderRadius: BorderRadius.circular(10),
                                border:
                                    Border.all(color: Colors.purple.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isAr
                                        ? 'Ø§Ù„Ø®Ø·Ø© Ø¨: Ø§Ù„ØªØ³Ø¹ÙŠØ± Ø§Ù„ØªØ¯Ø±ÙŠØ¬ÙŠ'
                                        : 'Plan B: Progressive Setup',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller: _floorPriceCtrl,
                                          keyboardType: const TextInputType
                                              .numberWithOptions(decimal: true),
                                          decoration: InputDecoration(
                                            labelText: isAr
                                                ? 'Ø§Ù„Ø³Ø¹Ø± Ø§Ù„Ø£Ø¯Ù†Ù‰'
                                                : 'Floor Price',
                                            border:
                                                const OutlineInputBorder(),
                                            isDense: true,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: TextFormField(
                                          controller: _stepPriceCtrl,
                                          keyboardType: const TextInputType
                                              .numberWithOptions(decimal: true),
                                          decoration: InputDecoration(
                                            labelText: isAr
                                                ? 'Ø®Ø·ÙˆØ© Ø§Ù†Ø®ÙØ§Ø¶ Ø§Ù„Ø³Ø¹Ø±'
                                                : 'Price Drop Step',
                                            border:
                                                const OutlineInputBorder(),
                                            isDense: true,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller: _groupTimerCtrl,
                                          keyboardType: TextInputType.number,
                                          decoration: InputDecoration(
                                            labelText: isAr
                                                ? 'Ù…Ø¤Ù‚Øª Ø§Ù„Ù…Ø¬Ù…ÙˆØ¹Ø© (Ø³Ø§Ø¹Ø§Øª)'
                                                : 'Group Timer (hours)',
                                            border:
                                                const OutlineInputBorder(),
                                            isDense: true,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: TextFormField(
                                          controller: _redemptionWindowCtrl,
                                          keyboardType: TextInputType.number,
                                          decoration: InputDecoration(
                                            labelText: isAr
                                                ? 'Ù†Ø§ÙØ°Ø© Ø§Ù„Ø§Ø³ØªØ±Ø¯Ø§Ø¯ (Ø³Ø§Ø¹Ø§Øª)'
                                                : 'Redemption (hours)',
                                            border:
                                                const OutlineInputBorder(),
                                            isDense: true,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          isAr
                                              ? 'Ù‚ÙÙ„ Ø¹Ù†Ø¯ Ø§Ù…ØªÙ„Ø§Ø¡ Ø§Ù„ÙØªØ­Ø§ØªØŸ'
                                              : 'Lock when slots full?',
                                        ),
                                      ),
                                      Switch(
                                        value: _lockOnSlotsFull,
                                        onChanged: (v) => setState(
                                            () => _lockOnSlotsFull = v),
                                        activeThumbColor: MigoColors.primary,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),

                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _originalPriceCtrl,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  onChanged: (_) => setState(() {}),
                                  decoration: InputDecoration(
                                    labelText: isAr ? 'Ø§Ù„Ø³Ø¹Ø± Ø§Ù„Ø£ØµÙ„ÙŠ' : 'Original price',
                                    border: const OutlineInputBorder(),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return isAr ? 'Ù…Ø·Ù„ÙˆØ¨' : 'Required';
                                    if (double.tryParse(v) == null) return isAr ? 'ØºÙŠØ± ØµØ§Ù„Ø­' : 'Invalid';
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _offerPriceCtrl,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  onChanged: (_) => setState(() {}),
                                  decoration: InputDecoration(
                                    labelText: isAr ? 'Ø³Ø¹Ø± Ù…ÙŠØ¬Ùˆ' : 'MIGO price',
                                    border: const OutlineInputBorder(),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return isAr ? 'Ù…Ø·Ù„ÙˆØ¨' : 'Required';
                                    final n = double.tryParse(v);
                                    if (n == null) return isAr ? 'ØºÙŠØ± ØµØ§Ù„Ø­' : 'Invalid';
                                    final orig = double.tryParse(_originalPriceCtrl.text);
                                    if (orig != null && n >= orig) {
                                      return isAr ? 'ÙŠØ¬Ø¨ Ø£Ù† ÙŠÙƒÙˆÙ† Ø£Ù‚Ù„ Ù…Ù† Ø§Ù„Ø£ØµÙ„ÙŠ' : 'Must be < original';
                                    }
                                    return null;
                                  },
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
                                  const Icon(Icons.check_circle, size: 18, color: MigoColors.success),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      isAr
                                          ? 'ÙˆÙØ± Ø§Ù„Ø¹Ù…ÙŠÙ„ QAR ${previewSavings.toStringAsFixed(0)}'
                                          : 'Customer saves QAR ${previewSavings.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: MigoColors.success,
                                        fontSize: 13,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),

                          DropdownButtonFormField<int>(
                            initialValue: _durationDays,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: isAr ? 'Ø§Ù„Ù…Ø¯Ø©' : 'Duration',
                              border: const OutlineInputBorder(),
                            ),
                            items: [
                              DropdownMenuItem(value: 1, child: Text(isAr ? 'ÙŠÙˆÙ… ÙˆØ§Ø­Ø¯' : '1 day')),
                              DropdownMenuItem(value: 3, child: Text(isAr ? '3 Ø£ÙŠØ§Ù…' : '3 days')),
                              DropdownMenuItem(value: 7, child: Text(isAr ? '7 Ø£ÙŠØ§Ù…' : '7 days')),
                              DropdownMenuItem(value: 14, child: Text(isAr ? '14 ÙŠÙˆÙ…Ù‹Ø§' : '14 days')),
                              DropdownMenuItem(value: 30, child: Text(isAr ? '30 ÙŠÙˆÙ…Ù‹Ø§' : '30 days')),
                            ],
                            onChanged: (v) => setState(() => _durationDays = v ?? 7),
                          ),
                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _dailyLimitCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: isAr ? 'Ø§Ù„Ø­Ø¯ Ø§Ù„ÙŠÙˆÙ…ÙŠ (Ø§Ø®ØªÙŠØ§Ø±ÙŠ)' : 'Daily limit (optional)',
                              border: const OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _termsCtrl,
                            maxLines: 2,
                            decoration: InputDecoration(
                              labelText: isAr ? 'Ø§Ù„Ø´Ø±ÙˆØ· (Ø§Ø®ØªÙŠØ§Ø±ÙŠ)' : 'Terms (optional)',
                              border: const OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _whatsappCtrl,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: isAr ? 'Ø±Ù‚Ù… Ø§Ù„ÙˆØ§ØªØ³Ø§Ø¨ (Ø§Ø®ØªÙŠØ§Ø±ÙŠ)' : 'WhatsApp Number (Optional)',
                              hintText: '+974 XXXX XXXX',
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.chat, color: Colors.green),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _orderLinkCtrl,
                            keyboardType: TextInputType.url,
                            decoration: InputDecoration(
                              labelText: isAr ? 'Ø±Ø§Ø¨Ø· Ø§Ù„Ø·Ù„Ø¨ Ø¹Ø¨Ø± Ø§Ù„Ø¥Ù†ØªØ±Ù†Øª (Ø§Ø®ØªÙŠØ§Ø±ÙŠ)' : 'Online Order Link (Optional)',
                              hintText: 'https://yourwebsite.com',
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.shopping_cart, color: Colors.orange),
                            ),
                          ),
                          const SizedBox(height: 24),

                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: MigoColors.primary.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: MigoColors.primary.withValues(alpha: 0.2)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      isAr ? 'Ø§Ù„Ø³Ù…Ø§Ø­ Ø¨Ø§Ù„Ø­Ø¬ÙˆØ²Ø§ØªØŸ' : 'Allow Reservations?',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                    Switch(
                                      value: _isReservable,
                                      onChanged: (v) => setState(() => _isReservable = v),
                                      activeThumbColor: MigoColors.primary,
                                    ),
                                  ],
                                ),
                                Text(
                                  isAr
                                      ? 'ÙŠÙ…ÙƒÙ† Ù„Ù„Ø¹Ù…Ù„Ø§Ø¡ Ø­Ø¬Ø² Ù‡Ø°Ø§ Ø§Ù„Ø¹Ø±Ø¶ Ù…Ø³Ø¨Ù‚Ù‹Ø§.'
                                      : 'Customers can book this offer in advance.',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                                if (_isReservable) ...[
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller: _totalSlotsCtrl,
                                          keyboardType: TextInputType.number,
                                          decoration: InputDecoration(
                                            labelText: isAr ? 'Ø¥Ø¬Ù…Ø§Ù„ÙŠ Ø§Ù„ÙØªØ­Ø§Øª' : 'Total Slots',
                                            border: const OutlineInputBorder(),
                                            isDense: true,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: TextFormField(
                                          controller: _maxPerCustomerCtrl,
                                          keyboardType: TextInputType.number,
                                          decoration: InputDecoration(
                                            labelText: isAr ? 'Ø§Ù„Ø­Ø¯ Ø§Ù„Ø£Ù‚ØµÙ‰ Ù„Ù„Ø¹Ù…ÙŠÙ„' : 'Max per Customer',
                                            border: const OutlineInputBorder(),
                                            isDense: true,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          if (_error != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Text(
                                _error!,
                                style: const TextStyle(color: Colors.red, fontSize: 13),
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
                                          Text(
                                            isAr ? 'Ø¬Ø§Ø±Ù ØªØ­Ù…ÙŠÙ„ Ø§Ù„ØµÙˆØ±Ø©â€¦' : 'Uploading imageâ€¦',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ],
                                    )
                                  : Text(
                                      isEdit
                                          ? (isAr ? 'ØªØ­Ø¯ÙŠØ« Ø§Ù„Ø¹Ø±Ø¶' : 'Update Offer')
                                          : (isAr ? 'Ø¥Ù†Ø´Ø§Ø¡ Ø¹Ø±Ø¶' : 'Create Offer'),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isAr
                                ? 'ØªØ¨Ø¯Ø£ Ø§Ù„Ø¹Ø±ÙˆØ¶ Ø§Ù„Ø¬Ø¯ÙŠØ¯Ø© Ù‚ÙŠØ¯ Ø§Ù„Ø§Ù†ØªØ¸Ø§Ø± ÙˆØªØµØ¨Ø­ Ù†Ø´Ø·Ø© Ø¨Ø¹Ø¯ Ù…ÙˆØ§ÙÙ‚Ø© Ù…ÙŠØ¬Ùˆ.'
                                : 'New offers start as pending and go live once approved by MIGO.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12, color: MigoColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _imagePickerCard(bool isAr) {
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.image_outlined,
                      size: 48,
                      color: MigoColors.primary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isAr ? 'Ø£Ø¶Ù ØµÙˆØ±Ø© Ù„Ø¹Ø±Ø¶Ùƒ' : 'Add a photo to your offer',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: MigoColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isAr
                          ? 'Ø§Ù„Ø´Ø±ÙƒØ§Øª Ø§Ù„ØªÙŠ Ù„Ø¯ÙŠÙ‡Ø§ ØµÙˆØ± ØªØ­ØµÙ„ Ø¹Ù„Ù‰ Ù…Ø·Ø§Ù„Ø¨Ø§Øª Ø£ÙƒØ«Ø± Ø¨Ù€ 3 Ù…Ø±Ø§Øª'
                          : 'Businesses with photos get 3Ã— more claims',
                      style: const TextStyle(
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
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined, size: 16),
                    label: Text(
                      hasImage
                          ? (isAr ? 'ØªØºÙŠÙŠØ±' : 'Change')
                          : (isAr ? 'Ø§Ù„Ù…Ø¹Ø±Ø¶' : 'Gallery'),
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
                    icon: const Icon(Icons.camera_alt_outlined, size: 16),
                    label: Text(
                      isAr ? 'Ø§Ù„ÙƒØ§Ù…ÙŠØ±Ø§' : 'Camera',
                      style: const TextStyle(fontSize: 13),
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
                    tooltip: isAr ? 'Ø¥Ø²Ø§Ù„Ø© Ø§Ù„ØµÙˆØ±Ø©' : 'Remove image',
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