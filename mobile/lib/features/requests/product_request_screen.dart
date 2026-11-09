import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/theme/migo_colors.dart';

class ProductRequestScreen extends StatefulWidget {
  const ProductRequestScreen({super.key});

  @override
  State<ProductRequestScreen> createState() => _ProductRequestScreenState();
}

class _ProductRequestScreenState extends State<ProductRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _productController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _productController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      await FirebaseFirestore.instance.collection('product_requests').add({
        'productName': _productController.text.trim(),
        'description': _descriptionController.text.trim(),
        'targetPrice': double.tryParse(_priceController.text) ?? 0.0,
        'userId': user.uid,
        'userName': user.displayName ?? 'User',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Request submitted successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocaleProvider.instance,
      builder: (context, _) {
        final isAr = LocaleProvider.instance.locale == 'ar';

        return Scaffold(
          appBar: AppBar(
            title: Text(isAr ? 'طلب منتج' : 'Request a Product'),
            backgroundColor: MigoColors.primary,
            foregroundColor: Colors.white,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    isAr ? 'لم تجد ما تبحث عنه؟' : 'Can\'t find what you\'re looking for?',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: MigoColors.textPrimaryLight),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isAr ? 'أخبرنا عن المنتج الذي تريده وسنبحث عنه لك.' : 'Tell us what product you want and we\'ll find it for you.',
                    style: const TextStyle(fontSize: 14, color: MigoColors.textSecondaryLight),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _productController,
                    decoration: InputDecoration(
                      labelText: isAr ? 'اسم المنتج' : 'Product Name',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.shopping_bag),
                    ),
                    validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: isAr ? 'الوصف (اختياري)' : 'Description (Optional)',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.description),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _priceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: isAr ? 'السعر المستهدف (QAR)' : 'Target Price (QAR)',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.attach_money),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitRequest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MigoColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              isAr ? 'إرسال الطلب' : 'Submit Request',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}