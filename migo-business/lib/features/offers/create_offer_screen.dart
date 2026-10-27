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

/// PHASE I — Advanced Create/Edit Offer with Reserve & Country
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

  // Dynamic Categories
  List<Map<String, String>> _dynamicCategories = [];
  bool _loadingCategories = true;

  String _type = 'standard';
  String _category = 'food'; 
  int _durationDays = 7;
  bool _isReservable = false;
  String _countryCode = 'QA';

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
    {'value': 'group', 'label': 'Group Deal'},
  ];

  static const _countries = [
    {'code': 'QA', 'name': 'Qatar 🇶🇦'},
    {'code': 'AE', 'name': 'UAE 🇦🇪'},
    {'code': 'SA', 'name': 'Saudi Arabia 🇸🇦'},
    {'code': 'KW', 'name': 'Kuwait 🇰🇼'},
    {'code': 'OM', 'name': 'Oman 🇴🇲'},
    {'code': 'BH', 'name': 'Bahrain 🇧🇭'},
    {'code': 'IN', 'name': 'India 🇮🇳'},
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
      _imageUrl = o.imageUrl.isNotEmpty ? o.imageUrl : null;
      _type = o.type.isNotEmpty ? o.type : 'standard';
      if (o.category.isNotEmpty) _category = o.category;
    }
  }

    Future<void> _loadCategories() async {
    try {
      // 🆕 orderBy ഒഴിവാക്കി, ലഭിച്ചതിനെ ആപ്പിൽ വെച്ച് സോർട്ട് ചെയ്യുന്നു
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

        // പേരിന്റെ അക്ഷരമാല ക്രമത്തിൽ സോർട്ട് ചെയ്യുന്നു (Order ഫീൽഡ് ഇല്ലെങ്കിൽ പോലും വർക്ക് ചെയ്യും)
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
      debugPrint('Error loading categories: $e'); // 🆕 എറർ കൺസോളിൽ കാണാൻ
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
                ? 'فشل تحميل الصورة. حاول مرة أخرى.'
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
        );

        // 🆕 പുതിയ ഗ്രൂപ്പ് ഡീൽ ഉണ്ടാക്കാനുള്ള കോഡ്
        if (err == null && _type == 'group') {
          try {
            final snap = await FirebaseFirestore.instance
                .collection('offers')
                .where('businessId', isEqualTo: widget.businessId)
                .where('title', isEqualTo: titleEn)
                .limit(1)
                .get();

            if (snap.docs.isNotEmpty) {
              final newOfferId = snap.docs.first.id;
              
              await FirebaseFirestore.instance.collection('group_deals').doc(newOfferId).set({
                'offerId': newOfferId,
                'minParticipants': int.tryParse(_minGroupCtrl.text.trim()) ?? 5,
                'maxParticipants': _maxGroupCtrl.text.trim().isEmpty 
                    ? null 
                    : int.tryParse(_maxGroupCtrl.text.trim()),
                'participantUids': [],
                'status': 'open',
                'deadline': DateTime.now().add(Duration(days: _durationDays)),
                'createdAt': FieldValue.serverTimestamp(),
                'updatedAt': FieldValue.serverTimestamp(),
              });
            }
          } catch (e) {
            debugPrint('Failed to create group deal: $e');
          }
        }
      }

      if (!mounted) return;

      if (err == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEdit
                  ? (LocaleProvider.instance.locale == 'ar' ? 'تم تحديث العرض!' : 'Offer updated!')
                  : (LocaleProvider.instance.locale == 'ar'
                      ? 'تم إنشاء العرض! في انتظار موافقة المسؤول.'
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
                    ? (isAr ? 'تعديل العرض' : 'Edit Offer')
                    : (isAr ? 'إنشاء عرض' : 'Create Offer'),
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
                              labelText: isAr ? 'عنوان العرض' : 'Offer title',
                              hintText: isAr ? 'مثال: عرض وجبة العائلة' : 'e.g. Family Meal Deal',
                              border: const OutlineInputBorder(),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? (isAr ? 'مطلوب' : 'Required')
                                : null,
                          ),
                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _descCtrl,
                            maxLines: 3,
                            decoration: InputDecoration(
                              labelText: isAr ? 'الوصف' : 'Description',
                              border: const OutlineInputBorder(),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? (isAr ? 'مطلوب' : 'Required')
                                : null,
                          ),
                          const SizedBox(height: 16),

                          // 🆕 Dynamic Category Dropdown
                          _loadingCategories
                              ? const Center(child: CircularProgressIndicator())
                              : DropdownButtonFormField<String>(
                                  initialValue: _category,
                                  isExpanded: true, // Overflow ഫിക്സ്
                                  decoration: InputDecoration(
                                    labelText: isAr ? 'الفئة' : 'Category',
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
                            isExpanded: true, // Overflow ഫിക്സ്
                            decoration: InputDecoration(
                              labelText: isAr ? 'الدولة' : 'Country',
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
                            isExpanded: true, // Overflow ഫിക്സ്
                            decoration: InputDecoration(
                              labelText: isAr ? 'نوع العرض' : 'Offer type',
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
                          
                          // Group Deal Fields
                          if (_type == 'group') ...[
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _minGroupCtrl,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Min people',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _maxGroupCtrl,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Max people (opt)',
                                      border: OutlineInputBorder(),
                                      isDense: true,
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
                                child: TextFormField(
                                  controller: _originalPriceCtrl,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  onChanged: (_) => setState(() {}),
                                  decoration: InputDecoration(
                                    labelText: isAr ? 'السعر الأصلي' : 'Original price',
                                    border: const OutlineInputBorder(),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return isAr ? 'مطلوب' : 'Required';
                                    if (double.tryParse(v) == null) return isAr ? 'غير صالح' : 'Invalid';
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
                                    labelText: isAr ? 'سعر ميجو' : 'MIGO price',
                                    border: const OutlineInputBorder(),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return isAr ? 'مطلوب' : 'Required';
                                    final n = double.tryParse(v);
                                    if (n == null) return isAr ? 'غير صالح' : 'Invalid';
                                    final orig = double.tryParse(_originalPriceCtrl.text);
                                    if (orig != null && n >= orig) {
                                      return isAr ? 'يجب أن يكون أقل من الأصلي' : 'Must be < original';
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
                                          ? 'وفر العميل QAR ${previewSavings.toStringAsFixed(0)}'
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
                              labelText: isAr ? 'المدة' : 'Duration',
                              border: const OutlineInputBorder(),
                            ),
                            items: [
                              DropdownMenuItem(value: 1, child: Text(isAr ? 'يوم واحد' : '1 day')),
                              DropdownMenuItem(value: 3, child: Text(isAr ? '3 أيام' : '3 days')),
                              DropdownMenuItem(value: 7, child: Text(isAr ? '7 أيام' : '7 days')),
                              DropdownMenuItem(value: 14, child: Text(isAr ? '14 يومًا' : '14 days')),
                              DropdownMenuItem(value: 30, child: Text(isAr ? '30 يومًا' : '30 days')),
                            ],
                            onChanged: (v) => setState(() => _durationDays = v ?? 7),
                          ),
                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _dailyLimitCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: isAr ? 'الحد اليومي (اختياري)' : 'Daily limit (optional)',
                              border: const OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _termsCtrl,
                            maxLines: 2,
                            decoration: InputDecoration(
                              labelText: isAr ? 'الشروط (اختياري)' : 'Terms (optional)',
                              border: const OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _whatsappCtrl,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: isAr ? 'رقم الواتساب (اختياري)' : 'WhatsApp Number (Optional)',
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
                              labelText: isAr ? 'رابط الطلب عبر الإنترنت (اختياري)' : 'Online Order Link (Optional)',
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
                                      isAr ? 'السماح بالحجوزات؟' : 'Allow Reservations?',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                    Switch(
                                      value: _isReservable,
                                      onChanged: (v) => setState(() => _isReservable = v),
                                      activeColor: MigoColors.primary,
                                    ),
                                  ],
                                ),
                                Text(
                                  isAr
                                      ? 'يمكن للعملاء حجز هذا العرض مسبقًا.'
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
                                            labelText: isAr ? 'إجمالي الفتحات' : 'Total Slots',
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
                                            labelText: isAr ? 'الحد الأقصى للعميل' : 'Max per Customer',
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
                                            isAr ? 'جارٍ تحميل الصورة…' : 'Uploading image…',
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
                                          ? (isAr ? 'تحديث العرض' : 'Update Offer')
                                          : (isAr ? 'إنشاء عرض' : 'Create Offer'),
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
                                ? 'تبدأ العروض الجديدة قيد الانتظار وتصبح نشطة بعد موافقة ميجو.'
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
                      isAr ? 'أضف صورة لعرضك' : 'Add a photo to your offer',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: MigoColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isAr
                          ? 'الشركات التي لديها صور تحصل على مطالبات أكثر بـ 3 مرات'
                          : 'Businesses with photos get 3× more claims',
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
                          ? (isAr ? 'تغيير' : 'Change')
                          : (isAr ? 'المعرض' : 'Gallery'),
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
                      isAr ? 'الكاميرا' : 'Camera',
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
                    tooltip: isAr ? 'إزالة الصورة' : 'Remove image',
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