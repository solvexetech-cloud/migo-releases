import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/theme/migo_colors.dart';
import '../../models/business_model.dart';
import '../../services/firestore_service.dart';

class RegisterBusinessScreen extends StatefulWidget {
  const RegisterBusinessScreen({super.key});

  @override
  State<RegisterBusinessScreen> createState() => _RegisterBusinessScreenState();
}

class _RegisterBusinessScreenState extends State<RegisterBusinessScreen> {
  final _name = TextEditingController();
  final _address = TextEditingController();
  final _description = TextEditingController();
  final _phone = TextEditingController();
  final _whatsapp = TextEditingController();

  String _category = 'Food';
  bool _loading = false;
  String? _error;

  static const _categories = [
    'Food',
    'Beauty',
    'Auto',
    'Events',
    'Photography',
    'Fitness',
    'Shopping',
    'Education',
    'Home Services',
  ];

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _description.dispose();
    _phone.dispose();
    _whatsapp.dispose();
    super.dispose();
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
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _error = 'You are not signed in.');
      return;
    }

    setState(() => _loading = true);
    try {
      final business = BusinessModel.newDraft(
        ownerUid: uid,
        name: _name.text.trim(),
        category: _category,
        addressLine: _address.text.trim(),
        description: _description.text.trim().isEmpty
            ? null
            : _description.text.trim(),
        phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        whatsapp: _whatsapp.text.trim().isEmpty ? null : _whatsapp.text.trim(),
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
              TextField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'Business name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v ?? _category),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _address,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  hintText: 'Street, area, Doha',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _description,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _whatsapp,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'WhatsApp (optional)',
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
            ],
          ),
        ),
      ),
    );
  }
}