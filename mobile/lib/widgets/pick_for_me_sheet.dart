import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/config/app_config.dart';
import '../core/theme/migo_colors.dart';
import '../models/offer_model.dart';
import '../services/firestore_service.dart';

class PickForMeSheet extends StatefulWidget {
  const PickForMeSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: MigoColors.surfaceLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const PickForMeSheet(),
    );
  }

  @override
  State<PickForMeSheet> createState() => _PickForMeSheetState();
}

class _PickForMeSheetState extends State<PickForMeSheet> {
  int? _budget;
  double? _distanceKm;
  String? _mood;
  bool _showResult = false;
  bool _isLoading = false;
  OfferModel? _pickedOffer;

  static const _budgets = [null, 20, 50, 100]; 
  static const _distances = [null, 1.0, 2.0, 5.0]; 
  static const _moods = [null, 'Spicy', 'Sweet', 'Comfort', 'Healthy', 'Quick'];

  String _budgetLabel(int? b) => b == null ? 'Any Budget' : 'Up to ${AppConfig.fallbackCurrency} $b';
  String _distanceLabel(double? d) => d == null ? 'Any Distance' : 'Within ${d.toStringAsFixed(0)} km';
  String _moodLabel(String? m) => m ?? 'Any Mood';

  Future<void> _findDeal() async {
    setState(() {
      _isLoading = true;
      _showResult = true;
    });

    try {
      // ഡാറ്റാബേസിൽ നിന്ന് ലൈവ് ഓഫറുകൾ എടുക്കുന്നു
      final snapshot = await FirebaseFirestore.instance
          .collection('offers')
          .where('status', isEqualTo: 'live')
          .get();

      var offers = snapshot.docs
          .map((doc) => OfferModel.fromMap(doc.id, doc.data()))
          .toList();

      // 1. ബജറ്റ് അനുസരിച്ച് ഫിൽട്ടർ ചെയ്യുന്നു
      if (_budget != null) {
        offers = offers.where((o) => o.offerPrice <= _budget!).toList();
      }

      // 2. മൂഡ് അനുസരിച്ച് ഫിൽട്ടർ ചെയ്യുന്നു (Title-ൽ ഉണ്ടോ എന്ന് നോക്കുന്നു)
      if (_mood != null) {
        final moodLower = _mood!.toLowerCase();
        offers = offers.where((o) => 
          o.title.toLowerCase().contains(moodLower) || 
          o.category.toLowerCase().contains(moodLower) ||
          o.description.toLowerCase().contains(moodLower)
        ).toList();
      }

      // 3. ഫിൽട്ടർ ചെയ്തതിൽ നിന്ന് റാൻഡം ഒരെണ്ണം എടുക്കുന്നു
      if (offers.isNotEmpty) {
        offers.shuffle();
        _pickedOffer = offers.first;
      } else {
        _pickedOffer = null;
      }
    } catch (e) {
      _pickedOffer = null;
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
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
              Row(
                children: [
                  const Icon(Icons.auto_awesome, color: MigoColors.accent, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    'Pick For Me',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: MigoColors.primary,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Tell MIGO your mood, we will pick the best deal.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12),
              ),
              const SizedBox(height: 20),

              // Budget
              _label('Budget'),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: _budgets.map((b) {
                  return _Pill(
                    label: _budgetLabel(b),
                    selected: _budget == b,
                    onTap: () => setState(() { _budget = b; _showResult = false; }),
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),

              // Distance
              _label('Distance'),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: _distances.map((d) {
                  return _Pill(
                    label: _distanceLabel(d),
                    selected: _distanceKm == d,
                    onTap: () => setState(() { _distanceKm = d; _showResult = false; }),
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),

              // Mood
              _label('Mood'),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: _moods.map((m) {
                  return _Pill(
                    label: _moodLabel(m),
                    selected: _mood == m,
                    onTap: () => setState(() { _mood = m; _showResult = false; }),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              if (!_showResult)
                SizedBox(
                  height: 48,
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _findDeal,
                    icon: const Icon(Icons.auto_awesome, size: 18),
                    label: const Text('Find my deal', style: TextStyle(fontSize: 14)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MigoColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                )
              else if (_isLoading)
                const Center(child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: CircularProgressIndicator(),
                ))
              else if (_pickedOffer != null)
                _resultCard(context, _pickedOffer!)
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange),
                      SizedBox(width: 10),
                      Expanded(child: Text('No deals matched your selection. Try different options!', style: TextStyle(fontSize: 13))),
                    ],
                  ),
                ),

              if (_showResult && !_isLoading) ...[
                const SizedBox(height: 10),
                Center(
                  child: TextButton(
                    onPressed: () => setState(() => _showResult = false),
                    child: const Text('Pick again', style: TextStyle(fontSize: 13)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: MigoColors.textPrimaryLight,
      ),
    );
  }

  // 🆕 യഥാർത്ഥ ഓഫർ കാണിക്കുന്ന കാർഡ്
  Widget _resultCard(BuildContext context, OfferModel offer) {
    final budgetText = _budget == null ? 'Any' : '${AppConfig.fallbackCurrency} $_budget';
    final distanceText = _distanceKm == null ? 'Any' : '${_distanceKm!.toStringAsFixed(0)} km';
    final moodText = _mood ?? 'Any';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MigoColors.primary.withValues(alpha: 0.3), width: 2),
        boxShadow: [
          BoxShadow(color: MigoColors.primary.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.amber, size: 16),
              const SizedBox(width: 6),
              Text(
                'MIGO picked for you!',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: MigoColors.primary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            offer.title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 2),
          Text(
            '${offer.businessName} · ${offer.category}',
            style: const TextStyle(fontSize: 12, color: MigoColors.textSecondaryLight),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (offer.originalPrice > offer.offerPrice)
                Text(
                  '${AppConfig.fallbackCurrency} ${offer.originalPrice.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 12, decoration: TextDecoration.lineThrough, color: MigoColors.textSecondaryLight),
                ),
              const SizedBox(width: 8),
              Text(
                '${AppConfig.fallbackCurrency} ${offer.offerPrice.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: MigoColors.primary),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: MigoColors.accent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'View Deal',
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Matched: $moodText · $distanceText · $budgetText',
            style: const TextStyle(fontSize: 10, color: MigoColors.textSecondaryLight, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? MigoColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: selected ? MigoColors.primary : MigoColors.dividerLight),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : MigoColors.textPrimaryLight,
          ),
        ),
      ),
    );
  }
}