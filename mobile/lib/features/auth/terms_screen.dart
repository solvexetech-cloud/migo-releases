import 'package:flutter/material.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/theme/migo_colors.dart';

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
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              iconTheme: const IconThemeData(color: Colors.white),
              backgroundColor: MigoColors.primary,
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    isAr ? 'مرحبًا بك في ميجو' : 'WELCOME TO MIGO',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: MigoColors.primary, // ഇത് ചേർക്കുക
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSection(
                    isAr ? '1. قبول الشروط' : '1. ACCEPTANCE OF TERMS',
                    isAr
                        ? 'باستخدامك لتطبيق ميجو، فإنك توافق على هذه الشروط والأحكام. إذا كنت لا توافق، يرجى عدم استخدام التطبيق.'
                        : 'By using the MIGO app, you agree to these terms and conditions. If you do not agree, please do not use the app.',
                  ),
                  _buildSection(
                    isAr ? '2. التعريفات' : '2. DEFINITIONS',
                    isAr
                        ? 'يشمل مصطلح "المنصة" تطبيق العملاء وتطبيق الأعمال وبوابة الإدارة.'
                        : 'The term "Platform" includes the Customer App, Business App, and Admin Web Portal.',
                  ),
                  _buildSection(
                    isAr ? '3. استخدام التطبيق' : '3. USE OF THE PLATFORM',
                    isAr
                        ? 'يجب استخدام التطبيق فقط للأغراض القانونية. أنت مسؤول عن سرية حسابك.'
                        : 'The app must be used only for lawful purposes. You are responsible for the confidentiality of your account.',
                  ),
                  _buildSection(
                    isAr ? '4. الأهلية' : '4. ELIGIBILITY',
                    isAr
                        ? 'يجب أن يكون عمرك 18 عامًا على الأقل لاستخدام التطبيق.'
                        : 'You must be at least 18 years old to use the app.',
                  ),
                  _buildSection(
                    isAr ? '5. التسجيل وأمن الحساب' : '5. REGISTRATION & ACCOUNT SECURITY',
                    isAr
                        ? 'يجب تقديم معلومات دقيقة. لا يجوز انتحال شخصية الآخرين.'
                        : 'You must provide accurate information. You may not impersonate others.',
                  ),
                  _buildSection(
                    isAr ? '6. ميجو ريزيرف — نظام الحجز المضمون' : '6. MIGO RESERVE — GUARANTEED RESERVATION',
                    isAr
                        ? 'يتيح لك الحجز الاحتفاظ بالعروض لفترة محددة. عدم الحضور 3 مرات في 30 يومًا يؤدي إلى تعليق 7 أيام. 5 مرات يؤدي إلى تعليق 30 يومًا.'
                        : 'Reserve allows you to hold offers for a specified period. 3 no-shows in 30 days results in a 7-day suspension. 5 no-shows results in a 30-day suspension.',
                  ),
                  _buildSection(
                    isAr ? '7. عملات ميجو — برنامج المكافآت' : '7. MIGO COINS — REWARD PROGRAM',
                    isAr
                        ? 'العملات افتراضية وليس لها قيمة نقدية. قد تنتهي صلاحيتها بعد 60 يومًا. أي محاولة للتلاعب ستؤدي إلى إنهاء الحساب.'
                        : 'Coins are virtual and have no cash value. They may expire after 60 days. Any manipulation will result in account termination.',
                  ),
                  _buildSection(
                    isAr ? '8. التزامات البائع' : '8. VENDOR OBLIGATIONS',
                    isAr
                        ? 'البائع مسؤول عن جودة المنتجات. يجب عليه احترام العروض والحجوزات الصالحة.'
                        : 'Vendors are responsible for product quality. They must honor valid offers and reservations.',
                  ),
                  _buildSection(
                    isAr ? '9. حقوق الملكية الفكرية' : '9. INTELLECTUAL PROPERTY',
                    isAr
                        ? 'جميع حقوق الملكية الفكرية مملوكة لشركة ميجو تكنولوجيز.'
                        : 'All intellectual property rights are owned by MIGO Technologies.',
                  ),
                  _buildSection(
                    isAr ? '10. الاستخدامات المحظورة' : '10. FORBIDDEN USES',
                    isAr
                        ? 'يُحظر إعادة بيع الخدمات، أو انتحال الهوية، أو محاولة اختراق النظام.'
                        : 'Reselling services, identity fraud, and system hacking are prohibited.',
                  ),
                  _buildSection(
                    isAr ? '11. الاتصالات والخصوصية' : '11. COMMUNICATION & PRIVACY',
                    isAr
                        ? 'بإنشاء حساب، فإنك توافق على تلقي الإشعارات عبر الرسائل النصية والبريد الإلكتروني والواتساب.'
                        : 'By creating an account, you consent to receive notifications via SMS, email, and WhatsApp.',
                  ),
                  _buildSection(
                    isAr ? '12. القانون الحاكم وتسوية النزاعات' : '12. GOVERNING LAW & DISPUTE RESOLUTION',
                    isAr
                        ? 'تخضع هذه الشروط لقوانين دولة قطر وجمهورية الهند. المحاكم المختصة في الدوحة أو تاميل نادو.'
                        : 'These terms are governed by the laws of Qatar and India. Competent courts in Doha or Tamil Nadu.',
                  ),
                  _buildSection(
                    isAr ? '13. سياسة الإلغاء والاسترداد' : '13. CANCELLATION & REFUND POLICY',
                    isAr
                        ? 'يمكن إلغاء الحجوزات قبل انتهاء فترة الحجز. لا توجد استردادات نقدية.'
                        : 'Reservations can be cancelled before the hold period ends. No cash refunds.',
                  ),
                  _buildSection(
                    isAr ? '14. حدود المسؤولية' : '14. LIMITATION OF LIABILITY',
                    isAr
                        ? 'ميجو ليست مسؤولة عن أي نزاعات بين المستخدم والبائع.'
                        : 'MIGO is not responsible for any disputes between the user and the vendor.',
                  ),
                  _buildSection(
                    isAr ? '15. التعويض' : '15. INDEMNIFICATION',
                    isAr
                        ? 'أنت توافق على تعويض ميجو عن أي خسائر ناتجة عن انتهاك هذه الشروط.'
                        : 'You agree to indemnify MIGO for any losses resulting from a breach of these terms.',
                  ),
                  _buildSection(
                    isAr ? '16. الإنهاء' : '16. TERMINATION',
                    isAr
                        ? 'يحق لميجو إنهاء حسابك في أي وقت بسبب انتهاك الشروط.'
                        : 'MIGO may terminate your account at any time for a breach of these terms.',
                  ),
                  _buildSection(
                    isAr ? '17. التعديلات' : '17. MODIFICATIONS',
                    isAr
                        ? 'نحتفظ بالحق في تعديل هذه الشروط في أي وقت. سيتم إخطارك بأي تغييرات.'
                        : 'We reserve the right to modify these terms at any time. You will be notified of any changes.',
                  ),
                  _buildSection(
                    isAr ? '18. الدعم والتواصل' : '18. CUSTOMER SUPPORT',
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
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
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
              color: MigoColors.primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: MigoColors.textPrimaryLight, // ഇത് ഇരുണ്ട നിറമാക്കി മാറ്റുക
            ),
          ),
        ],
      ),
    );
  }
}