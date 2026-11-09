import 'package:flutter/material.dart';
import '../core/theme/migo_colors.dart';
import '../models/area_model.dart';
import '../models/country_model.dart';
import '../models/zone_model.dart';
import '../services/firestore_service.dart';

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  List<CountryModel> _countries = [];
  List<ZoneModel> _zones = [];
  
  String? _selectedCountryCode;
  String? _selectedZoneId;
  ZoneModel? _selectedZone;

  bool _loadingCountries = true;
  bool _loadingZones = false;

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
      _selectedCountryCode = code;
      _zones = [];
      _selectedZoneId = null;
      _selectedZone = null;
    });
    setState(() => _loadingZones = true);
    try {
      final list = await FirestoreService.instance.getZonesByCountry(code);
      if (!mounted) return;
      setState(() {
        _zones = list;
        _loadingZones = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingZones = false);
    }
  }

  void _confirm() {
    if (_selectedZone == null) return;
    final selectedArea = AreaModel(
      id: _selectedZone!.id,
      zoneSlug: _selectedZone!.id,
      name: _selectedZone!.name,
      slug: _selectedZone!.id,
    );
    Navigator.of(context).pop(selectedArea);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Select your country'),
        backgroundColor: Colors.white,
        foregroundColor: MigoColors.textPrimaryLight,
        elevation: 0,
      ),
      body: _loadingCountries
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Container(
                    color: MigoColors.backgroundLight,
                    child: ListView.builder(
                      itemCount: _countries.length,
                      itemBuilder: (context, index) {
                        final country = _countries[index];
                        final isSelected = _selectedCountryCode == country.code;
                        return ListTile(
                          leading: Text(country.flag, style: const TextStyle(fontSize: 20)),
                          title: Text(
                            country.name,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          selected: isSelected,
                          selectedTileColor: MigoColors.primary.withValues(alpha: 0.1),
                          onTap: () => _selectCountry(country.code),
                        );
                      },
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: _loadingZones
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          itemCount: _zones.length,
                          itemBuilder: (context, index) {
                            final zone = _zones[index];
                            final isSelected = _selectedZoneId == zone.id;
                            return ListTile(
                              title: Text(zone.name),
                              trailing: isSelected ? const Icon(Icons.check, color: MigoColors.primary) : null,
                              selected: isSelected,
                              onTap: () {
                                setState(() {
                                  _selectedZoneId = zone.id;
                                  _selectedZone = zone;
                                });
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _selectedZone == null ? null : _confirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: MigoColors.primary,
            minimumSize: const Size(double.infinity, 50),
          ),
          child: const Text('Confirm Location', style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }
}