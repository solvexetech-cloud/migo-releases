import 'package:flutter/material.dart';
import '../core/config/app_config.dart';
import '../core/theme/migo_colors.dart';

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
  // null അല്ലെങ്കിൽ 0 എന്നത് "Any" എന്ന് അർത്ഥം
  int? _budget;
  double? _distanceKm;
  String? _mood;
  bool _showResult = false;

  static const _budgets = [null, 20, 50, 100]; // null = Any
  static const _distances = [null, 1.0, 2.0, 5.0]; // null = Any
  static const _moods = [null, 'Spicy', 'Sweet', 'Comfort', 'Healthy', 'Quick']; // null = Any

  String _budgetLabel(int? b) => b == null ? 'Any Budget' : 'Up to ${AppConfig.fallbackCurrency} $b';
  String _distanceLabel(double? d) => d == null ? 'Any Distance' : 'Within ${d.toStringAsFixed(0)} km';
  String _moodLabel(String? m) => m ?? 'Any Mood';

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
                  const Icon(
                    Icons.auto_awesome,
                    color: MigoColors.accent,
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Pick For Me',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: MigoColors.primary,
                          fontSize: 20, // ചെറുതാക്കി
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Tell MIGO your mood, we will pick the deal.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12), // ചെറുതാക്കി
              ),
              const SizedBox(height: 20),

              // Budget
              _label('Budget'),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: _budgets.map((b) {
                  final selected = _budget == b;
                  return _Pill(
                    label: _budgetLabel(b),
                    selected: selected,
                    onTap: () => setState(() {
                      _budget = b;
                      _showResult = false;
                    }),
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
                  final selected = _distanceKm == d;
                  return _Pill(
                    label: _distanceLabel(d),
                    selected: selected,
                    onTap: () => setState(() {
                      _distanceKm = d;
                      _showResult = false;
                    }),
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
                  final selected = _mood == m;
                  return _Pill(
                    label: _moodLabel(m),
                    selected: selected,
                    onTap: () => setState(() {
                      _mood = m;
                      _showResult = false;
                    }),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // Find button OR result
              if (!_showResult)
                SizedBox(
                  height: 48,
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => setState(() => _showResult = true),
                    icon: const Icon(Icons.auto_awesome, size: 18),
                    label: const Text('Find my deal', style: TextStyle(fontSize: 14)),
                  ),
                )
              else
                _resultCard(context),

              if (_showResult) ...[
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => setState(() => _showResult = false),
                  child: const Text('Pick again', style: TextStyle(fontSize: 13)),
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

  Widget _resultCard(BuildContext context) {
    final budgetText = _budget == null ? 'Any' : '${AppConfig.fallbackCurrency} $_budget';
    final distanceText = _distanceKm == null ? 'Any' : '${_distanceKm!.toStringAsFixed(0)} km';
    final moodText = _mood ?? 'Any';

    return Container(
      padding: const EdgeInsets.all(14),
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
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                'MIGO picked for you',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: MigoColors.primary,
                      fontSize: 12,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Chicken Shawarma Combo',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: MigoColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Shawarma Station · 1.2 km',
            style: TextStyle(
              fontSize: 12,
              color: MigoColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${AppConfig.fallbackCurrency} 25',
                style: const TextStyle(
                  fontSize: 12,
                  decoration: TextDecoration.lineThrough,
                  color: MigoColors.textSecondaryLight,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${AppConfig.fallbackCurrency} 18',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: MigoColors.primary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: MigoColors.accent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Claim',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Matched: $moodText · $distanceText · $budgetText',
            style: const TextStyle(
              fontSize: 10,
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : MigoColors.textPrimaryLight,
          ),
        ),
      ),
    );
  }
}