import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/theme/migo_colors.dart';
import '../../models/area_model.dart';
import '../../models/business_model.dart';
import '../../models/category_model.dart';
import '../../models/country_model.dart';
import '../../models/zone_model.dart';
import '../../services/firestore_service.dart';

class RegisterBusinessScreen extends StatefulWidget {
  const RegisterBusinessScreen({super.key});

  @override
  State<RegisterBusinessScreen> createState() =>
      _RegisterBusinessScreenState();
}

class _RegisterBusinessScreenState extends State<RegisterBusinessScreen> {
  final _name = TextEditingController();
  final _address = TextEditingController();
  final _description = TextEditingController();
  final _phone = TextEditingController();
  final _whatsapp = TextEditingController();
  final _mapUrl = TextEditingController();

  String? _category;
  String? _countryCode;
  String? _zoneSlug;
  String? _areaSlug;

  TimeOfDay _openTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _closeTime = const TimeOfDay(hour: 23, minute: 0);
  bool _loading = false;
  String? _error;

  // Dynamic data from Firestore
  List<CategoryModel> _categories = [];
  List<CountryModel> _countries = [];
  List<ZoneModel> _zones = [];
  List<AreaModel> _areas = [];

  // Loading flags for each dropdown
  bool _loadingCategories = true;
  bool _loadingCountries = true;
  bool _loadingZones = false;
  bool _loadingAreas = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadCountries();
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _description.dispose();
    _phone.dispose();
    _whatsapp.dispose();
    _mapUrl.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await FirestoreService.instance.getCategories();
      if (!mounted) return;
      setState(() {
        _categories = cats;
        _loadingCategories = false;
        if (cats.isNotEmpty && _category == null) {
          _category = cats.first.name;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingCategories = false);
    }
  }

  Future<void> _loadCountries() async {
    try {
      final list = await FirestoreService.instance.getCountries();
      if (!mounted) return;
      setState(() {
        _countries = list;
        _loadingCountries = false;
        // Auto-select Qatar (or first country)
        if (list.isNotEmpty && _countryCode == null) {
          _countryCode = list.first.code;
          _loadZones(list.first.code);
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingCountries = false);
    }
  }

  Future<void> _loadZones(String countryCode) async {
    setState(() {
      _loadingZones = true;
      _zones = [];
      _areas = [];
      _zoneSlug = null;
      _areaSlug = null;
    });
    try {
      final list = await FirestoreService.instance.getZonesByCountry(
        countryCode,
      );
      if (!mounted) return;
      setState(() {
        _zones = list;
        _loadingZones = false;
        if (list.isNotEmpty) {
          _zoneSlug = list.first.id;
          _loadAreas(list.first.id);
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingZones = false);
    }
  }

  Future<void> _loadAreas(String zoneSlug) async {
    setState(() {
      _loadingAreas = true;
      _areas = [];
      _areaSlug = null;
    });
    try {
      final list = await FirestoreService.instance.getAreasByZone(zoneSlug);
      if (!mounted) return;
      setState(() {
        _areas = list;
        _loadingAreas = false;
        if (list.isNotEmpty) {
          _areaSlug = list.first.id;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingAreas = false);
    }
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickTime(bool isOpen) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isOpen ? _openTime : _closeTime,
    );
    if (picked != null) {
      setState(() {
        if (isOpen) {
          _openTime = picked;
        } else {
          _closeTime = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    setState(() => _error = null);

    if (_name.text.trim().isEmpty) {
      setState(() => _error = 'Please enter your business name.');
      return;
    }
    if (_address.text.trim().isEmpty) {
      setState(() => _error = 'Please enter your address.');
      return;
    }
    if (_category == null || _category!.isEmpty) {
      setState(() => _error = 'Please select a category.');
      return;
    }
    if (_countryCode == null) {
      setState(() => _error = 'Please select a country.');
      return;
    }
    if (_zoneSlug == null) {
      setState(() => _error = 'Please select a zone.');
      return;
    }
    if (_areaSlug == null) {
      setState(() => _error = 'Please select an area.');
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _error = 'You are not signed in.');
      return;
    }

    setState(() => _loading = true);
    try {
      // Find selected area → get its agencyUid (if assigned)
      final selectedArea = _areas.firstWhere(
        (a) => a.id == _areaSlug,
        orElse: () => _areas.first,
      );

      final business = BusinessModel.newDraft(
        ownerUid: uid,
        name: _name.text.trim(),
        category: _category!,
        addressLine: _address.text.trim(),
        description: _description.text.trim().isEmpty
            ? null
            : _description.text.trim(),
        phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        whatsapp:
            _whatsapp.text.trim().isEmpty ? null : _whatsapp.text.trim(),
        openTime: _formatTime(_openTime),
        closeTime: _formatTime(_closeTime),
        mapUrl:
            _mapUrl.text.trim().isEmpty ? null : _mapUrl.text.trim(),
        countryCode: _countryCode!,
        zoneId: _zoneSlug!,
        areaId: _areaSlug!,
        agencyUid: selectedArea.agencyUid,
      );
      await FirestoreService.instance.createBusiness(business);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Failed to register: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register your business')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Tell us about your business',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              const Text(
                'Your listing will be reviewed by the MIGO team before going live.',
                style: TextStyle(
                  fontSize: 13,
                  color: MigoColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 24),

              // ---------- BASIC INFO ----------
              TextField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'Business name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Category (dynamic from Firestore)
              _loadingCategories
                  ? _loadingField('Loading categories…')
                  : DropdownButtonFormField<String>(
                      initialValue: _category,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items: _categories
                          .map(
                            (c) => DropdownMenuItem(
                              value: c.name,
                              child: Row(
                                children: [
                                  Icon(c.iconData, size: 16),
                                  const SizedBox(width: 8),
                                  Text(c.name),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _category = v ?? _category),
                    ),

              const SizedBox(height: 16),
              TextField(
                controller: _address,
                decoration: const InputDecoration(
                  labelText: 'Street address',
                  hintText: 'Building, street',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 20),

              // ---------- LOCATION ----------
              const Text(
                'Location',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: MigoColors.textPrimaryLight,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 8),

              // Country
              _loadingCountries
                  ? _loadingField('Loading countries…')
                  : DropdownButtonFormField<String>(
                      initialValue: _countryCode,
                      decoration: const InputDecoration(
                        labelText: 'Country',
                        border: OutlineInputBorder(),
                      ),
                      items: _countries
                          .map(
                            (c) => DropdownMenuItem(
                              value: c.code,
                              child: Text('${c.flag}  ${c.name}'),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => _countryCode = v);
                        _loadZones(v);
                      },
                    ),
              const SizedBox(height: 12),

              // Zone
              _loadingZones
                  ? _loadingField('Loading zones…')
                  : DropdownButtonFormField<String>(
                      initialValue: _zoneSlug,
                      decoration: const InputDecoration(
                        labelText: 'Zone / District',
                        border: OutlineInputBorder(),
                      ),
                      items: _zones
                          .map(
                            (z) => DropdownMenuItem(
                              value: z.id,
                              child: Text(z.name),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => _zoneSlug = v);
                        _loadAreas(v);
                      },
                    ),
              const SizedBox(height: 12),

              // Area
              _loadingAreas
                  ? _loadingField('Loading areas…')
                  : DropdownButtonFormField<String>(
                      initialValue: _areaSlug,
                      decoration: const InputDecoration(
                        labelText: 'Area / Neighborhood',
                        border: OutlineInputBorder(),
                      ),
                      items: _areas
                          .map(
                            (a) => DropdownMenuItem(
                              value: a.id,
                              child: Row(
                                children: [
                                  Expanded(child: Text(a.name)),
                                  if (a.hasAgency)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: MigoColors.success
                                            .withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'AGENCY',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          color: MigoColors.success,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _areaSlug = v ?? _areaSlug),
                    ),

              const SizedBox(height: 20),

              // ---------- HOURS ----------
              const Text(
                'Business hours',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: MigoColors.textPrimaryLight,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _TimeField(
                      label: 'Opens at',
                      time: _openTime,
                      onTap: () => _pickTime(true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TimeField(
                      label: 'Closes at',
                      time: _closeTime,
                      onTap: () => _pickTime(false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ---------- CONTACT ----------
              const Text(
                'Contact (optional)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: MigoColors.textPrimaryLight,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _description,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _whatsapp,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'WhatsApp',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _mapUrl,
                decoration: const InputDecoration(
                  labelText: 'Google Maps link',
                  hintText: 'https://maps.google.com/...',
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
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Submit for review'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _loadingField(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: MigoColors.backgroundLight,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: MigoColors.dividerLight),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: MigoColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.label,
    required this.time,
    required this.onTap,
  });

  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: MigoColors.dividerLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: MigoColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: MigoColors.textPrimaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}