// mobile/lib/features/demands/new_demand_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/localization/app_localizations.dart';
import '../../services/demand_group_service.dart';
import '../../core/theme/migo_colors.dart';

class NewDemandScreen extends StatefulWidget {
  const NewDemandScreen({super.key});
  @override
  State<NewDemandScreen> createState() => _NewDemandScreenState();
}

class _NewDemandScreenState extends State<NewDemandScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedCategory;
  DateTime? _deliveryDate;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose(); _quantityController.dispose();
    _priceController.dispose(); _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context, initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) setState(() => _deliveryDate = picked);
  }

  Future<void> _submitDemand() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a category')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');
      final demandRef = FirebaseFirestore.instance.collection('demands').doc();
      final demandId = demandRef.id;
      await demandRef.set({
        'customerId': user.uid, 'customerName': user.displayName ?? 'Customer',
        'title': _titleController.text.trim(), 'description': _descriptionController.text.trim(),
        'category': _selectedCategory, 'quantity': int.parse(_quantityController.text.trim()),
        'targetPrice': double.parse(_priceController.text.trim()), 'zoneId': 'doha-central', 'countryCode': 'QA',
        'status': 'collecting', 'createdAt': FieldValue.serverTimestamp(),
      });
      await DemandGroupService().processNewDemand(
        demandId: demandId, title: _titleController.text.trim(), category: _selectedCategory!,
        zoneId: 'doha-central', countryCode: 'QA', quantity: int.parse(_quantityController.text.trim()),
        targetPrice: double.parse(_priceController.text.trim()), deliveryDate: _deliveryDate, customerId: user.uid,
      );
      if (!mounted) return;
      final t = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.get('demand_posted_success')), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(title: Text(t.get('new_demand'), style: const TextStyle(fontWeight: FontWeight.w800)), backgroundColor: Colors.white, elevation: 0, foregroundColor: MigoColors.primaryDark),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF1E3A8A), Color(0xFF0F172A)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: const Color(0xFF1E3A8A).withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))],
                ),
                child: Row(
                  children: [
                    Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle), child: const Icon(Icons.gavel_rounded, color: Colors.white, size: 28)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(isAr ? 'اطلب ما تحتاجه' : 'Request What You Need', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 4),
                          Text(isAr ? 'سيتنافس البائعون المحليون على طلبك.' : 'Local vendors will bid for your request.', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildLabel(isAr ? 'اسم المنتج' : 'Product Name'),
              const SizedBox(height: 8),
              TextFormField(controller: _titleController, decoration: _inputDecoration(hint: isAr ? 'ماذا تريد أن تشتري؟' : 'What do you want to buy?', icon: Icons.shopping_bag_outlined), validator: (val) => val == null || val.isEmpty ? 'Required' : null),
              const SizedBox(height: 20),
              _buildLabel(isAr ? 'الفئة' : 'Category'),
              const SizedBox(height: 8),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('categories').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final categories = snapshot.data!.docs.map((doc) => (doc.data() as Map<String, dynamic>)['name'] ?? 'Unknown').toList();
                  return DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: _inputDecoration(hint: isAr ? 'اختر الفئة' : 'Select Category', icon: Icons.category_outlined),
                    items: categories.map((cat) => DropdownMenuItem<String>(value: cat, child: Text(cat))).toList(),
                    onChanged: (val) => setState(() => _selectedCategory = val),
                  );
                },
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _buildLabel(isAr ? 'الكمية' : 'Quantity'), const SizedBox(height: 8),
                    TextFormField(controller: _quantityController, keyboardType: TextInputType.number, decoration: _inputDecoration(hint: '1', icon: Icons.numbers), validator: (val) => (val == null || int.tryParse(val) == null) ? 'Invalid' : null),
                  ])),
                  const SizedBox(width: 16),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _buildLabel(isAr ? 'السعر المستهدف' : 'Target Price'), const SizedBox(height: 8),
                    TextFormField(controller: _priceController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: _inputDecoration(hint: '0.00', icon: Icons.attach_money), validator: (val) => (val == null || double.tryParse(val) == null) ? 'Invalid' : null),
                  ])),
                ],
              ),
              const SizedBox(height: 20),
              _buildLabel(isAr ? 'تاريخ التسليم المفضل' : 'Preferred Delivery Date'),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade300)),
                  child: Row(children: [
                    Icon(Icons.calendar_today, color: Colors.grey.shade500, size: 20), const SizedBox(width: 12),
                    Text(_deliveryDate == null ? (isAr ? 'اختر التاريخ (اختياري)' : 'Select Date (Optional)') : '${_deliveryDate!.day}/${_deliveryDate!.month}/${_deliveryDate!.year}', style: TextStyle(color: _deliveryDate == null ? Colors.grey.shade400 : Colors.black87, fontSize: 14)),
                  ]),
                ),
              ),
              const SizedBox(height: 20),
              _buildLabel(isAr ? 'الوصف (اختياري)' : 'Description (Optional)'),
              const SizedBox(height: 8),
              TextFormField(controller: _descriptionController, maxLines: 3, decoration: _inputDecoration(hint: isAr ? 'أضف تفاصيل إضافية...' : 'Add more details...', icon: Icons.description_outlined, alignLabelWithHint: true)),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blue.shade100)),
                child: Row(children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20), const SizedBox(width: 12),
                  Expanded(child: Text(isAr ? 'سيتم تجميعك تلقائياً مع العملاء الآخرين الذين لديهم نفس الطلب.' : 'You will be automatically grouped with other customers.', style: TextStyle(fontSize: 12, color: Colors.blue.shade900))),
                ]),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitDemand,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 4, shadowColor: const Color(0xFFF59E0B).withValues(alpha: 0.5)),
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.send_rounded, size: 20), const SizedBox(width: 8), Text(t.get('create_demand'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)));
  InputDecoration _inputDecoration({required String hint, required IconData icon, bool alignLabelWithHint = false}) => InputDecoration(
    hintText: hint, hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
    prefixIcon: Icon(icon, color: Colors.grey.shade500, size: 20), filled: true, fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 2)),
    alignLabelWithHint: alignLabelWithHint,
  );
}