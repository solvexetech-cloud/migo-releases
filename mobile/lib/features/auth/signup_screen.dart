import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/config/app_config.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/theme/migo_colors.dart';
import '../../core/theme/migo_gradients.dart';
import '../../models/country_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../main/main_shell.dart';
import 'login_screen.dart';
import 'terms_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _referralController = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  bool _termsAccepted = false;
  String? _error;
  bool _referralFromUrl = false;

  List<CountryModel> _countries = [];
  CountryModel? _selectedCountry;
  bool _countriesLoading = true;

  @override
  void initState() {
    super.initState();
    _checkUrlForReferralCode();
    _checkPendingReferral();
    _loadCountries();
  }

  Future<void> _loadCountries() async {
    try {
      final countries = await FirestoreService.instance.getCountries();
      if (!mounted) return;
      setState(() {
        _countries = countries;
        _countriesLoading = false;
        if (countries.isNotEmpty) {
          _selectedCountry = countries.firstWhere(
            (c) => c.code == AppConfig.defaultCountryCode,
            orElse: () => countries.first,
          );
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _countriesLoading = false);
    }
  }

  void _checkUrlForReferralCode() {
    if (!kIsWeb) return;
    try {
      final uri = Uri.base;
      final refParam = uri.queryParameters['ref'];
      if (refParam != null && refParam.isNotEmpty) {
        _referralController.text = refParam.toUpperCase();
        _referralFromUrl = true;
        return;
      }
      final segments = uri.pathSegments;
      if (segments.length >= 2 && segments[0] == 'r') {
        final code = segments[1];
        if (code.isNotEmpty) {
          _referralController.text = code.toUpperCase();
          _referralFromUrl = true;
        }
      }
    } catch (_) {}
  }

  Future<void> _checkPendingReferral() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString('pending_referral_code');
      if (code != null && code.isNotEmpty) {
        if (!mounted) return;
        setState(() {
          _referralController.text = code.toUpperCase();
          _referralFromUrl = true;
        });
        await prefs.remove('pending_referral_code');
      }
    } catch (e) {}
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _referralController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;
    final referralCode = _referralController.text.trim().toUpperCase();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = LocaleProvider.instance.locale == 'ar'
          ? 'يرجى ملء جميع الحقول.'
          : 'Please fill in all fields.');
      return;
    }
    if (password.length < 6) {
      setState(() => _error = LocaleProvider.instance.locale == 'ar'
          ? 'يجب أن تكون كلمة المرور 6 أحرف على الأقل.'
          : 'Password must be at least 6 characters.');
      return;
    }
    if (password != confirm) {
      setState(() => _error = LocaleProvider.instance.locale == 'ar'
          ? 'كلمات المرور غير متطابقة.'
          : 'Passwords do not match.');
      return;
    }
    if (!_termsAccepted) {
      setState(() => _error = LocaleProvider.instance.locale == 'ar'
          ? 'يرجى الموافقة على الشروط والأحكام.'
          : 'Please accept the Terms & Conditions.');
      return;
    }

    setState(() => _loading = true);
    try {
      if (_selectedCountry == null) {
        setState(() {
          _error = LocaleProvider.instance.locale == 'ar'
              ? 'يرجى اختيار دولتك.'
              : 'Please select your country.';
          _loading = false;
        });
        return;
      }

      final cred = await AuthService.instance.signUp(
        email: email,
        password: password,
        countryCode: _selectedCountry!.code,
        countryName: _selectedCountry!.name,
        currency: _selectedCountry!.currency,
        locale: _selectedCountry!.locale,
      );

      String? referrerUid;
      if (referralCode.isNotEmpty) {
        referrerUid = await FirestoreService.instance
            .findUidByReferralCode(referralCode);
      }

      final newUid = cred.user?.uid;
      if (newUid != null && referrerUid != null && referrerUid.isNotEmpty) {
        bool referralSuccess = false;
        for (int attempt = 0; attempt < 5 && !referralSuccess; attempt++) {
          try {
            await Future.delayed(Duration(milliseconds: 500 + (attempt * 500)));
            await FirestoreService.instance.recordReferral(
              referrerUid: referrerUid,
              referredUid: newUid,
              referredEmail: email,
              referralCode: referralCode,
            );
            referralSuccess = true;
          } catch (e) {}
        }
      }

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainShell()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = AuthService.instance.describeError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
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
            backgroundColor: Colors.white,
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
              // ഭാഷാ ഐക്കൺ
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.language, color: MigoColors.primary),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (ctx) {
                        final isAr = LocaleProvider.instance.locale == 'ar';
                        return SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 40,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade300,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  isAr ? 'اختر لغتك' : 'Choose your language',
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ListTile(
                                  leading: const Text('🇸🇦', style: TextStyle(fontSize: 26)),
                                  title: const Text('العربية (Arabic)', style: TextStyle(fontWeight: FontWeight.w800)),
                                  trailing: isAr ? const Icon(Icons.check_circle, color: Colors.green) : null,
                                  onTap: () async {
                                    Navigator.pop(ctx);
                                    await LocaleProvider.instance.setLocale('ar');
                                  },
                                ),
                                ListTile(
                                  leading: const Text('🇬🇧', style: TextStyle(fontSize: 26)),
                                  title: const Text('English', style: TextStyle(fontWeight: FontWeight.w800)),
                                  trailing: !isAr ? const Icon(Icons.check_circle, color: Colors.green) : null,
                                  onTap: () async {
                                    Navigator.pop(ctx);
                                    await LocaleProvider.instance.setLocale('en');
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
                    const SizedBox(height: 32),
                    // Logo
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFF0C566), Color(0xFFD4A13A)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          alignment: Alignment.center,
                          child: const Text('🎁', style: TextStyle(fontSize: 26)),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          isAr ? 'ميجو' : AppConfig.appName,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: MigoColors.primary,
                            letterSpacing: isAr ? 0 : 3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Text(
                      isAr ? 'أنشئ حسابك' : 'Create your account',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isAr
                          ? 'انضم إلى ميجو واكتشف أفضل العروض'
                          : 'Join MIGO and discover the best deals',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // Country selector
                    _countriesLoading
                        ? const Center(child: CircularProgressIndicator())
                        : Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: MigoColors.primary.withValues(alpha: 0.15),
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<CountryModel>(
                                value: _selectedCountry,
                                isExpanded: true,
                                icon: const Icon(Icons.keyboard_arrow_down),
                                hint: Text(isAr ? 'اختر دولتك' : 'Select your country'),
                                items: _countries
                                    .map(
                                      (c) => DropdownMenuItem<CountryModel>(
                                        value: c,
                                        child: Row(
                                          children: [
                                            Text(
                                              c.flag.isNotEmpty ? c.flag : '🌐',
                                              style: const TextStyle(fontSize: 22),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                '${c.name} · ${c.currency}',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) {
                                  setState(() {
                                    _selectedCountry = val;
                                    _error = null;
                                  });
                                },
                              ),
                            ),
                          ),

                    // Referral banner
                    if (_referralFromUrl) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: MigoColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: MigoColors.success.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.card_giftcard,
                              color: MigoColors.success,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isAr ? 'مرحبًا! أنت مدعو 🎉' : 'Welcome! You\'re invited 🎉',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: MigoColors.success,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isAr
                                        ? 'سجل للحصول على +30 عملة ميجو بعد أول مطالبة.'
                                        : 'Sign up to get +30 MIGO Coins after your first claim.',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: MigoColors.success.withValues(alpha: 0.9),
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Email
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: InputDecoration(
                        labelText: isAr ? 'البريد الإلكتروني' : 'Email',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Password
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText: isAr ? 'كلمة المرور' : 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Confirm password
                    TextField(
                      controller: _confirmController,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText: isAr ? 'تأكيد كلمة المرور' : 'Confirm password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Referral code
                    TextField(
                      controller: _referralController,
                      textCapitalization: TextCapitalization.characters,
                      onChanged: (_) {
                        if (_referralFromUrl) {
                          setState(() => _referralFromUrl = false);
                        }
                      },
                      decoration: InputDecoration(
                        labelText: isAr ? 'رمز الإحالة (اختياري)' : 'Referral code (optional)',
                        prefixIcon: const Icon(Icons.card_giftcard),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        suffixIcon: _referralController.text.isNotEmpty
                            ? const Icon(Icons.check_circle, color: MigoColors.success)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Terms & Conditions checkbox
                    Row(
                      children: [
                        Checkbox(
                          value: _termsAccepted,
                          onChanged: (v) => setState(() => _termsAccepted = v ?? false),
                          activeColor: MigoColors.primary,
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const TermsScreen(),
                                ),
                              );
                            },
                            child: RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black87,
                                ),
                                children: [
                                  TextSpan(
                                    text: isAr ? 'أوافق على ' : 'I agree to the ',
                                  ),
                                  TextSpan(
                                    text: isAr ? 'الشروط والأحكام' : 'Terms & Conditions',
                                    style: const TextStyle(
                                      color: MigoColors.primary,
                                      fontWeight: FontWeight.w700,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red, fontSize: 13),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MigoColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                isAr ? 'إنشاء حساب' : 'Create account',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _loading
                          ? null
                          : () {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (_) => const LoginScreen(),
                                ),
                              );
                            },
                      child: Text(
                        isAr
                            ? 'لديك حساب بالفعل؟ تسجيل الدخول'
                            : 'Already have an account? Log in',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}