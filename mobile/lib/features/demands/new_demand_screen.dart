// mobile/lib/features/demands/new_demand_screen.dart
// UPDATED - Fixed duplicate avgPrice
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
  final _priceMinController = TextEditingController();
  final _priceMaxController = TextEditingController();
  final _brandController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedCategory;
  String _urgency = 'Flexible';
  String _budgetType = 'Flexible';
  DateTime? _deliveryDate;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _quantityController.dispose();
    _priceMinController.dispose();
    _priceMaxController.dispose();
    _brandController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) {
      setState(() => _deliveryDate = picked);
    }
  }

  Future<void> _submitDemand() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      final demandRef = FirebaseFirestore.instance.collection('demands').doc();
      final demandId = demandRef.id;
      
      final double minPriceVal = double.tryParse(_priceMinController.text.trim()) ?? 0;
      final double maxPriceVal = double.tryParse(_priceMaxController.text.trim()) ?? 0;
      final double avgPriceVal = (minPriceVal + maxPriceVal) / 2;

      await demandRef.set({
        'customerId': user.uid,
        'customerName': user.displayName ?? 'Customer',
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _selectedCategory,
        'quantity': int.parse(_quantityController.text.trim()),
        'targetPrice': avgPriceVal,
        'minPrice': minPriceVal,
        'maxPrice': maxPriceVal,
        'brand': _brandController.text.trim(),
        'urgency': _urgency,
        'budgetType': _budgetType,
        'zoneId': 'doha-central',
        'countryCode': 'QA',
        'status': 'collecting',
        'createdAt': FieldValue.serverTimestamp(),
      });

      final groupService = DemandGroupService();
      await groupService.processNewDemand(
        demandId: demandId,
        title: _titleController.text.trim(),
        category: _selectedCategory!,
        zoneId: 'doha-central',
        countryCode: 'QA',
        quantity: int.parse(_quantityController.text.trim()),
        targetPrice: avgPriceVal,
        deliveryDate: _deliveryDate,
        customerId: user.uid,
        minPrice: minPriceVal,
        maxPrice: maxPriceVal,
        brand: _brandController.text.trim(),
        urgency: _urgency,
        budgetType: _budgetType,
      );

      if (!mounted) return;
      
      final t = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.get('demand_posted_success')),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      
      Navigator.pop(context);
      
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    
    final double minP = double.tryParse(_priceMinController.text) ?? 0;
    final double maxP = double.tryParse(_priceMaxController.text) ?? 0;
    final int qty = int.tryParse(_quantityController.text) ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(t.get('new_demand'), style: const TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: MigoColors.primaryDark,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E3A8A), Color(0xFF0F172A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1E3A8A).withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.gavel_rounded, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isAr ? 'اطلب ما تحتاجه' : 'Request What You Need',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isAr 
                              ? 'سيتنافس البائعون المحليون على طلبك.'
                              : 'Local vendors will bid for your request.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Product Name
              _buildLabel(isAr ? 'اسم المنتج' : 'Product Name'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: _inputDecoration(
                  hint: isAr ? 'ماذا تريد أن تشتري؟' : 'What do you want to buy?',
                  icon: Icons.shopping_bag_outlined,
                ),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 20),

              // Category
              _buildLabel(isAr ? 'الفئة' : 'Category'),
              const SizedBox(height: 8),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('categories').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final categories = snapshot.data!.docs.map((doc) => (doc.data() as Map<String, dynamic>)['name'] ?? 'Unknown').toList();
                  return DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: _inputDecoration(
                      hint: isAr ? 'اختر الفئة' : 'Select Category',
                      icon: Icons.category_outlined,
                    ),
                    items: categories.map((cat) => DropdownMenuItem<String>(value: cat, child: Text(cat))).toList(),
                    onChanged: (val) => setState(() => _selectedCategory = val),
                  );
                },
              ),
              const SizedBox(height: 20),

              // Quantity
              _buildLabel(isAr ? 'الكمية' : 'Quantity'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                decoration: _inputDecoration(hint: '1', icon: Icons.numbers),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Required';
                  if (int.tryParse(val) == null) return 'Invalid';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Price Range
              _buildLabel(isAr ? 'نطاق السعر المستهدف' : 'Target Price Range'),
              const SizedBox(height: 4),
              Text(
                isAr 
                  ? 'هذا هو السعر الذي تتمناه. قد تختلف عروض المتاجر.'
                  : 'This is the price YOU want. Shop offers may differ.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceMinController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setState(() {}),
                      decoration: _inputDecoration(hint: 'Min (e.g. 50)', icon: Icons.arrow_downward),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Required';
                        if (double.tryParse(val) == null) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _priceMaxController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setState(() {}),
                      decoration: _inputDecoration(hint: 'Max (e.g. 60)', icon: Icons.arrow_upward),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Required';
                        if (double.tryParse(val) == null) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Total Price Summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(isAr ? 'نطاق سعر الوحدة:' : 'Unit Price Range:', style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text('QAR ${minP.toStringAsFixed(0)} - ${maxP.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(isAr ? 'الكمية:' : 'Quantity:', style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text('$qty', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(isAr ? 'السعر الإجمالي:' : 'Total Price:', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue)),
                        Text('QAR ${(minP * qty).toStringAsFixed(0)} - ${(maxP * qty).toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.blue)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Preferred Brand
              _buildLabel(isAr ? 'العلامة التجارية المفضلة (اختياري)' : 'Preferred Brand (Optional)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _brandController,
                decoration: _inputDecoration(
                  hint: isAr ? 'مثال: Nike, Apple' : 'e.g. Nike, Apple',
                  icon: Icons.branding_watermark,
                ),
              ),
              const SizedBox(height: 20),

              // Urgency
              _buildLabel(isAr ? 'الاستعجال' : 'Urgency'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _urgency,
                decoration: _inputDecoration(hint: 'Select Urgency', icon: Icons.timer),
                items: [
                  DropdownMenuItem(value: 'ASAP', child: Text(isAr ? 'في أسرع وقت ممكن' : 'Need ASAP')),
                  DropdownMenuItem(value: 'Flexible', child: Text(isAr ? 'مرن' : 'Flexible')),
                ],
                onChanged: (val) => setState(() => _urgency = val ?? 'Flexible'),
              ),
              const SizedBox(height: 20),

              // Budget Type
              _buildLabel(isAr ? 'نوع الميزانية' : 'Budget Type'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _budgetType,
                decoration: _inputDecoration(hint: 'Select Budget Type', icon: Icons.account_balance_wallet),
                items: [
                  DropdownMenuItem(value: 'Strict', child: Text(isAr ? 'صارم (لا يزيد عن السعر)' : 'Strict Budget')),
                  DropdownMenuItem(value: 'Flexible', child: Text(isAr ? 'مرن (قد يزيد قليلاً)' : 'Flexible Budget')),
                ],
                onChanged: (val) => setState(() => _budgetType = val ?? 'Flexible'),
              ),
              const SizedBox(height: 20),

              // Delivery Date
              _buildLabel(isAr ? 'تاريخ التسليم المفضل' : 'Preferred Delivery Date'),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, color: Colors.grey.shade500, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        _deliveryDate == null 
                          ? (isAr ? 'اختر التاريخ (اختياري)' : 'Select Date (Optional)')
                          : '${_deliveryDate!.day}/${_deliveryDate!.month}/${_deliveryDate!.year}',
                        style: TextStyle(color: _deliveryDate == null ? Colors.grey.shade400 : Colors.black87, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Description
              _buildLabel(isAr ? 'الوصف (اختياري)' : 'Description (Optional)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: _inputDecoration(
                  hint: isAr ? 'أضف تفاصيل إضافية...' : 'Add more details...',
                  icon: Icons.description_outlined,
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 32),

              // Info Note
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isAr 
                          ? 'سيتم تجميعك تلقائياً مع العملاء الآخرين الذين لديهم نفس الطلب.'
                          : 'You will be automatically grouped with other customers.',
                        style: TextStyle(fontSize: 12, color: Colors.blue.shade900),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitDemand,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                    shadowColor: const Color(0xFFF59E0B).withValues(alpha: 0.5),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.send_rounded, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              t.get('create_demand'),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    bool alignLabelWithHint = false,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      prefixIcon: Icon(icon, color: Colors.grey.shade500, size: 20),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 2),
      ),
      alignLabelWithHint: alignLabelWithHint,
    );
  }
}