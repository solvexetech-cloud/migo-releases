import 'package:flutter/material.dart';
import '../../core/localization/locale_provider.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocaleProvider.instance,
      builder: (context, _) {
        final isAr = LocaleProvider.instance.locale == 'ar';

        return Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            appBar: AppBar(
              title: Text(
                isAr ? 'الشروط والأحكام' : 'Terms & Conditions',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              iconTheme: const IconThemeData(color: Colors.white),
              backgroundColor: const Color(0xFF0B2B5B),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isAr ? 'مرحبًا بك في ميجو بزنس' : 'WELCOME TO MIGO BUSINESS',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0B2B5B),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildSection(
                    isAr ? '1. قبول الشروط' : '1. ACCEPTANCE OF TERMS',
                    isAr
                        ? 'باستخدامك لتطبيق ميجو بزنس، فإنك توافق على هذه الشروط والأحكام. إذا كنت لا توافق، يرجى عدم استخدام التطبيق.'
                        : 'By using the MIGO Business app, you agree to these terms and conditions. If you do not agree, please do not use the app.',
                  ),
                  _buildSection(
                    isAr ? '2. الأهلية والتسجيل' : '2. ELIGIBILITY & REGISTRATION',
                    isAr
                        ? 'يجب أن تكون مالكًا قانونيًا للشركة أو ممثلاً معتمدًا لها. يجب تقديم معلومات دقيقة وصحيحة أثناء التسجيل.'
                        : 'You must be the legal owner or an authorized representative of the business. You must provide accurate information during registration.',
                  ),
                  _buildSection(
                    isAr ? '3. التزامات العمل' : '3. BUSINESS OBLIGATIONS',
                    isAr
                        ? 'أنت مسؤول عن دقة جميع العروض والأسعار. يجب عليك احترام جميع المطالبات والحجوزات الصالحة المقدمة من العملاء.'
                        : 'You are responsible for the accuracy of all offers and prices. You must honor all valid claims and reservations presented by customers.',
                  ),
                  _buildSection(
                    isAr ? '4. العروض والتسعير' : '4. OFFERS & PRICING',
                    isAr
                        ? 'يجب أن تكون جميع العروض حقيقية وغير مضللة. يحق لميجو إزالة أي عرض أو تعليق الحساب في حالة الاحتيال.'
                        : 'All offers must be genuine and not misleading. MIGO reserves the right to remove any offer or suspend the account in case of fraud.',
                  ),
                  _buildSection(
                    isAr ? '5. نظام الحجز المضمون (ميجو ريزيرف)' : '5. GUARANTEED RESERVATION (MIGO RESERVE)',
                    isAr
                        ? 'يجب عليك احترام جميع الحجوزات المؤكدة. يتم تتبع عدم حضور العملاء، وقد يؤدي عدم الامتثال المتكرر إلى تعليق حسابك.'
                        : 'You must honor all confirmed reservations. No-shows by customers are tracked, and repeated non-compliance may result in account suspension.',
                  ),
                  _buildSection(
                    isAr ? '6. المدفوعات والعمولات' : '6. PAYMENTS & COMMISSIONS',
                    isAr
                        ? 'ميجو ليست مسؤولة عن المدفوعات المباشرة بينك وبين العملاء. أي رسوم أو اشتراكات مستحقة لميجو سيتم الاتفاق عليها بشكل منفصل.'
                        : 'MIGO is not responsible for direct payments between you and customers. Any fees or subscriptions due to MIGO will be agreed upon separately.',
                  ),
                  _buildSection(
                    isAr ? '7. الملكية الفكرية' : '7. INTELLECTUAL PROPERTY',
                    isAr
                        ? 'جميع الحقوق الفكرية للمنصة (الكود، التصميم، الشعارات) مملوكة لشركة ميجو تكنولوجيز.'
                        : 'All intellectual property rights of the Platform (code, design, logos) are owned by MIGO Technologies.',
                  ),
                  _buildSection(
                    isAr ? '8. الاستخدامات المحظورة' : '8. FORBIDDEN USES',
                    isAr
                        ? 'يُحظر استخدام المنصة للأنشطة غير القانونية، أو محاولة اختراق النظام، أو نشر معلومات مضللة.'
                        : 'Using the platform for illegal activities, attempting to hack the system, or posting misleading information is prohibited.',
                  ),
                  _buildSection(
                    isAr ? '9. إنهاء الحساب' : '9. ACCOUNT TERMINATION',
                    isAr
                        ? 'يحق لميجو تعليق أو إنهاء حسابك في أي وقت بسبب انتهاك هذه الشروط.'
                        : 'MIGO reserves the right to suspend or terminate your account at any time for violating these terms.',
                  ),
                  _buildSection(
                    isAr ? '10. القانون الحاكم' : '10. GOVERNING LAW',
                    isAr
                        ? 'تخضع هذه الشروط لقوانين دولة قطر وجمهورية الهند.'
                        : 'These terms are governed by the laws of the State of Qatar and the Republic of India.',
                  ),
                  _buildSection(
                    isAr ? '11. الدعم والتواصل' : '11. SUPPORT & CONTACT',
                    isAr
                        ? 'للاستفسارات، يرجى الاتصال بنا على support@migoapp.com'
                        : 'For inquiries, please contact us at support@migoapp.com',
                  ),
                  
                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      isAr
                          ? '© 2026 ميجو تكنولوجيز. جميع الحقوق محفوظة.'
                          : '© 2026 MIGO Technologies. All rights reserved.',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSection(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0B2B5B),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: const TextStyle(fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }
}