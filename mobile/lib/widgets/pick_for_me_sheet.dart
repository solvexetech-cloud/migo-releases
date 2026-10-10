import 'package:flutter/material.dart';
import '../core/config/app_config.dart';
import '../core/theme/migo_colors.dart';

/// Signature MIGO feature.
/// User picks Budget + Distance + Mood. MIGO suggests matching deals.
class PickForMeSheet extends StatefulWidget {
  const PickForMeSheet({super.key});

  /// Helper to show this sheet from anywhere.
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
  int _budget = 50;
  double _distanceKm = 2;
  String _mood = 'Comfort';
  bool _showResult = false;

  static const _budgets = [20, 50, 100];
  static const _distances = [1.0, 2.0, 5.0];
  static const _moods = ['Spicy', 'Sweet', 'Comfort', 'Healthy', 'Quick'];

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
              const SizedBox(height: 20),
              Row(
                children: [
                  const Icon(
                    Icons.auto_awesome,
                    color: MigoColors.accent,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Pick For Me',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: MigoColors.primary,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Tell MIGO your mood, we will pick the deal.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),

              // Budget
              _label('Budget'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _budgets.map((b) {
                  final selected = _budget == b;
                  return _Pill(
                    label: 'Up to ${AppConfig.fallbackCurrency} $b',
                    selected: selected,
                    onTap: () => setState(() {
                      _budget = b;
                      _showResult = false;
                    }),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // Distance
              _label('Distance'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _distances.map((d) {
                  final selected = _distanceKm == d;
                  return _Pill(
                    label: 'Within ${d.toStringAsFixed(0)} km',
                    selected: selected,
                    onTap: () => setState(() {
                      _distanceKm = d;
                      _showResult = false;
                    }),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // Mood
              _label('Mood'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _moods.map((m) {
                  final selected = _mood == m;
                  return _Pill(
                    label: m,
                    selected: selected,
                    onTap: () => setState(() {
                      _mood = m;
                      _showResult = false;
                    }),
                  );
                }).toList(),
              ),

              const SizedBox(height: 28),

              // Find button OR result
              if (!_showResult)
                SizedBox(
                  height: 52,
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => setState(() => _showResult = true),
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Find my deal'),
                  ),
                )
              else
                _resultCard(context),

              if (_showResult) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => setState(() => _showResult = false),
                  child: const Text('Pick again'),
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
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: MigoColors.textPrimaryLight,
      ),
    );
  }

  Widget _resultCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MigoColors.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MigoColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome,
                color: MigoColors.accent,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                'MIGO picked for you',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: MigoColors.primary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Chicken Shawarma Combo',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: MigoColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Shawarma Station · 1.2 km',
            style: TextStyle(
              fontSize: 13,
              color: MigoColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${AppConfig.fallbackCurrency} 25',
                style: const TextStyle(
                  fontSize: 13,
                  decoration: TextDecoration.lineThrough,
                  color: MigoColors.textSecondaryLight,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${AppConfig.fallbackCurrency} 18',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: MigoColors.primary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: MigoColors.accent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Claim',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Matched: $_mood · Within ${_distanceKm.toStringAsFixed(0)} km · Under ${AppConfig.fallbackCurrency} $_budget',
            style: const TextStyle(
              fontSize: 11,
              color: MigoColors.textSecondaryLight,
              fontStyle: FontStyle.italic,
            ),
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? MigoColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? MigoColors.primary : MigoColors.dividerLight,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : MigoColors.textPrimaryLight,
          ),
        ),
      ),
    );
  }
}