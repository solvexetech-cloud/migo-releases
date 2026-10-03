import 'package:flutter/material.dart';
import '../../core/theme/migo_colors.dart';
import '../../models/business_model.dart';
import '../../models/offer_model.dart';
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

  OfferType _type = OfferType.standard;
  int _durationDays = 7;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _originalPrice.dispose();
    _offerPrice.dispose();
    _terms.dispose();
    _dailyLimit.dispose();
    super.dispose();
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
      setState(() => _error = 'Offer price must be less than original price.');
      return;
    }

    setState(() => _loading = true);
    try {
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
      );
      await FirestoreService.instance.createOffer(offer);
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
    final previewSavings = (double.tryParse(_originalPrice.text) ?? 0) -
        (double.tryParse(_offerPrice.text) ?? 0);

    return Scaffold(
      appBar: AppBar(title: const Text('Create offer')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                  hintText: 'What is included in the offer',
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
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(t.label),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _type = v ?? _type),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _originalPrice,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
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
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
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
                      const Icon(Icons.check_circle,
                          size: 18, color: MigoColors.success),
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
                  hintText: 'Max redemptions per day',
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
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
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
}