import 'package:flutter/material.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/theme/migo_colors.dart';
import '../../core/theme/migo_gradients.dart';
import '../../services/demand_service.dart';

class CreateDemandScreen extends StatefulWidget {
  const CreateDemandScreen({super.key});

  @override
  State<CreateDemandScreen> createState() => _CreateDemandScreenState();
}

class _CreateDemandScreenState extends State<CreateDemandScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _requiredCountController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _requiredCountController.dispose();
    super.dispose();
  }

  Future<void> _submitDemand(bool isAr) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    // Since we only have one input, we save it to both 'en' and 'ar' 
    // to support the existing model. Later, if needed, we can add separate fields.
    final title = {
      'en': _titleController.text.trim(),
      'ar': _titleController.text.trim(),
    };
    final description = {
      'en': _descController.text.trim(),
      'ar': _descController.text.trim(),
    };

    final demandId = await DemandService().createDemand(
      title: title,
      description: description,
      targetPrice: double.tryParse(_priceController.text.trim()) ?? 0.0,
      requiredCount: int.tryParse(_requiredCountController.text.trim()) ?? 1,
      currency: 'QAR',
      areaId: 'doha_center', // Hardcoded for now
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (demandId != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isAr ? 'تم إنشاء الطلب بنجاح!' : 'Demand created successfully!'),
          backgroundColor: MigoColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context); 
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isAr ? 'حدث خطأ. حاول مرة أخرى.' : 'Error creating demand. Try again.'),
          backgroundColor: MigoColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocaleProvider.instance,
      builder: (context, _) {
        final isAr = LocaleProvider.instance.locale == 'ar';

        return Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: MigoColors.backgroundLight,
            appBar: AppBar(
              title: Text(isAr ? 'طلب منتج جديد' : 'Create New Demand', style: const TextStyle(fontWeight: FontWeight.w800)),
              backgroundColor: Colors.transparent,
              elevation: 0,
              foregroundColor: MigoColors.primaryDark,
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Gradient Header Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [MigoColors.primary, MigoColors.primaryDark],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: MigoColors.primary.withValues(alpha: 0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isAr ? 'اطلب ما تحتاجه' : 'Request What You Need',
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isAr ? 'سيقوم التجار بالتقدم بعروضهم لأجلك.' : 'Local vendors will bid for your request.',
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Section: Product Info
                    _buildSectionTitle(isAr ? 'معلومات المنتج' : 'Product Information', isAr),
                    const SizedBox(height: 12),
                    
                    // Single Title Field
                    _buildTextField(
                      controller: _titleController,
                      label: isAr ? 'اسم المنتج' : 'Product Name',
                      hint: isAr ? 'مثال: آيفون 17 برو ماكس' : 'e.g., iPhone 17 Pro Max',
                      icon: Icons.shopping_bag_outlined,
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    
                    // Single Description Field
                    _buildTextField(
                      controller: _descController,
                      label: isAr ? 'الوصف (اختياري)' : 'Description (Optional)',
                      hint: isAr ? 'اللون، السعة، إلخ' : 'Color, Storage, etc.',
                      icon: Icons.description_outlined,
                      maxLines: 2,
                    ),

                    const SizedBox(height: 24),
                    _buildSectionTitle(isAr ? 'تفاصيل الطلب' : 'Demand Details', isAr),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _priceController,
                            label: isAr ? 'السعر (QAR)' : 'Price (QAR)',
                            hint: '2500',
                            icon: Icons.attach_money,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (val) {
                              if (val == null || val.isEmpty) return 'Required';
                              if (double.tryParse(val) == null) return 'Invalid';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            controller: _requiredCountController,
                            label: isAr ? 'العدد' : 'People',
                            hint: '50',
                            icon: Icons.people_outline,
                            keyboardType: TextInputType.number,
                            validator: (val) {
                              if (val == null || val.isEmpty) return 'Required';
                              final count = int.tryParse(val);
                              if (count == null || count < 2) return 'Min 2';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Glowing Gradient Button
                    Container(
                      width: double.infinity,
                      height: 55,
                        decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [MigoColors.accent, MigoColors.accentDark],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: MigoColors.accent.withValues(alpha: 0.5),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: _isLoading ? null : () => _submitDemand(isAr),
                          child: Center(
                            child: _isLoading
                                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: MigoColors.primaryDark, strokeWidth: 2))
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.send, color: MigoColors.primaryDark, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        isAr ? 'نشر الطلب' : 'Post Demand',
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: MigoColors.primaryDark),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title, bool isAr) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: MigoColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: MigoColors.primaryDark),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20, color: MigoColors.primary),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: MigoColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: const TextStyle(color: MigoColors.textSecondaryLight, fontSize: 13),
      ),
    );
  }
}