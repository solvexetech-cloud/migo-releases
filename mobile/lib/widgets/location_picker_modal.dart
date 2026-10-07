import 'package:flutter/material.dart';
import '../core/theme/migo_colors.dart';
import '../models/area_model.dart';
import '../models/country_model.dart';
import '../models/zone_model.dart';
import '../services/firestore_service.dart';

/// Location picker modal — cascading Country → Zone → Area.
///
/// Returns selected AreaModel (or null if cancelled).
class LocationPickerModal {
  static Future<AreaModel?> show(BuildContext context) async {
    return showModalBottomSheet<AreaModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _LocationPickerSheet(),
    );
  }
}

class _LocationPickerSheet extends StatefulWidget {
  const _LocationPickerSheet();

  @override
  State<_LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<_LocationPickerSheet> {
  List<CountryModel> _countries = [];
  List<ZoneModel> _zones = [];
  List<AreaModel> _areas = [];

  String? _countryCode;
  String? _zoneSlug;
  String? _areaSlug;

  bool _loadingCountries = true;
  bool _loadingZones = false;
  bool _loadingAreas = false;

  @override
  void initState() {
    super.initState();
    _loadCountries();
  }

  Future<void> _loadCountries() async {
    setState(() => _loadingCountries = true);
    try {
      final list = await FirestoreService.instance.getCountries();
      if (!mounted) return;
      setState(() {
        _countries = list;
        _loadingCountries = false;
      });
      // Auto-select first country
      if (list.isNotEmpty) {
        _selectCountry(list.first.code);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingCountries = false);
    }
  }

  Future<void> _selectCountry(String code) async {
    setState(() {
      _countryCode = code;
      _zones = [];
      _areas = [];
      _zoneSlug = null;
      _areaSlug = null;
    });
    setState(() => _loadingZones = true);
    try {
      final list =
          await FirestoreService.instance.getZonesByCountry(code);
      if (!mounted) return;
      setState(() {
        _zones = list;
        _loadingZones = false;
      });
      if (list.isNotEmpty) {
        _selectZone(list.first.id);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingZones = false);
    }
  }

  Future<void> _selectZone(String slug) async {
    setState(() {
      _zoneSlug = slug;
      _areas = [];
      _areaSlug = null;
    });
    setState(() => _loadingAreas = true);
    try {
      final list = await FirestoreService.instance.getAreasByZone(slug);
      if (!mounted) return;
      setState(() {
        _areas = list;
        _loadingAreas = false;
      });
      if (list.isNotEmpty) {
        setState(() => _areaSlug = list.first.id);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingAreas = false);
    }
  }

  void _confirm() {
    if (_areaSlug == null) return;
    final area = _areas.firstWhere(
      (a) => a.id == _areaSlug,
      orElse: () => _areas.first,
    );
    Navigator.of(context).pop(area);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: MigoColors.dividerLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Change Location',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: MigoColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Choose your country, zone, and area to see nearby deals.',
                style: TextStyle(
                  fontSize: 13,
                  color: MigoColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 20),

              // Country
              if (_loadingCountries)
                _loadingField('Loading countries…')
              else
                DropdownButtonFormField<String>(
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
                    _selectCountry(v);
                  },
                ),
              const SizedBox(height: 12),

              // Zone
              if (_loadingZones)
                _loadingField('Loading zones…')
              else
                DropdownButtonFormField<String>(
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
                    _selectZone(v);
                  },
                ),
              const SizedBox(height: 12),

              // Area
              if (_loadingAreas)
                _loadingField('Loading areas…')
              else
                DropdownButtonFormField<String>(
                  initialValue: _areaSlug,
                  decoration: const InputDecoration(
                    labelText: 'Area / Neighborhood',
                    border: OutlineInputBorder(),
                  ),
                  items: _areas
                      .map(
                        (a) => DropdownMenuItem(
                          value: a.id,
                          child: Text(a.name),
                        ),
                      )
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _areaSlug = v ?? _areaSlug),
                ),
              const SizedBox(height: 24),

              // Confirm
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _areaSlug == null ? null : _confirm,
                  child: const Text('Confirm Location'),
                ),
              ),
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