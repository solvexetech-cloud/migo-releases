import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/migo_colors.dart';
import '../../models/country_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../main/main_shell.dart';
import 'login_screen.dart';

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
  String? _error;
  bool _referralFromUrl = false;

  // Country selection (D6-A)
  List<CountryModel> _countries = [];
  CountryModel? _selectedCountry;
  bool _countriesLoading = true;

      @override
  void initState() {
    super.initState();
    _checkUrlForReferralCode();      // Web URL
    _checkPendingReferral();          // Mobile deep link
    _loadCountries();
  }

  Future<void> _loadCountries() async {
    try {
      final countries = await FirestoreService.instance.getCountries();
      if (!mounted) return;
      setState(() {
        _countries = countries;
        _countriesLoading = false;
        // Auto-select default country
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

  /// Web-only: parse URL for referral code.
  /// Supports:
  ///   ?ref=CODE  (query param)
  ///   /r/CODE    (path)
  void _checkUrlForReferralCode() {
    if (!kIsWeb) return;

    try {
      final uri = Uri.base;

      // Query param: ?ref=CODE
      final refParam = uri.queryParameters['ref'];
      if (refParam != null && refParam.isNotEmpty) {
        _referralController.text = refParam.toUpperCase();
        _referralFromUrl = true;
        return;
      }

      // Path: /r/CODE
      final segments = uri.pathSegments;
      if (segments.length >= 2 && segments[0] == 'r') {
        final code = segments[1];
        if (code.isNotEmpty) {
          _referralController.text = code.toUpperCase();
          _referralFromUrl = true;
        }
      }
    } catch (_) {
      // Silent fail — URL parsing may fail in some environments
    }
  }

  /// PHASE E — E3: Check for pending referral code from deep link.
  /// Called on init — reads code stored by deep link handler.
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
        // Clear after applying
        await prefs.remove('pending_referral_code');
      }
    } catch (e) {
      // Ignore errors
    }
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
      setState(() => _error = 'Please fill in all fields.');
      return;
    }
    if (password.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters.');
      return;
    }
    if (password != confirm) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }

    setState(() => _loading = true);
    try {
            // D6-A: Require country selection
      if (_selectedCountry == null) {
        setState(() {
          _error = 'Please select your country.';
          _loading = false;
        });
        return;
      }

      // PHASE E — Auth FIRST, then referral lookup
      final cred = await AuthService.instance.signUp(
        email: email,
        password: password,
        countryCode: _selectedCountry!.code,
        countryName: _selectedCountry!.name,
        currency: _selectedCountry!.currency,
        locale: _selectedCountry!.locale,
      );

      // PHASE E — Now with auth, lookup referral code
      String? referrerUid;
      if (referralCode.isNotEmpty) {
        debugPrint('🔵 Looking up referral: $referralCode');
        referrerUid = await FirestoreService.instance
            .findUidByReferralCode(referralCode);
        debugPrint('🔵 referrerUid = $referrerUid');
        
        if (referrerUid == null) {
          // Referral code invalid — but signup already succeeded
          if (!mounted) return;
          debugPrint('⚠️ Referral code not found — continuing signup');
        }
      }
      debugPrint('✅ Step 1 done: Auth + user doc created. uid=${cred.user?.uid}');

              final newUid = cred.user?.uid;
        if (newUid != null && referrerUid != null && referrerUid.isNotEmpty) {
          // PHASE E — Wait + retry for auth token propagation
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
              debugPrint('✅ recordReferral success (attempt ${attempt + 1})');
            } catch (e) {
              debugPrint('⚠️ recordReferral attempt ${attempt + 1} failed: $e');
              if (attempt == 4) {
                // Last attempt — don't fail signup, just log
                debugPrint('❌ recordReferral failed after 5 attempts');
              }
            }
          }
        }

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainShell()),
        (route) => false,
      );
    } catch (e, stackTrace) {
  debugPrint('🔴 SIGNUP ERROR: $e');
  debugPrint('🔴 STACK TRACE: $stackTrace');
  if (!mounted) return;
  setState(() => _error = AuthService.instance.describeError(e));
} finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              Text(
                AppConfig.appName,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: MigoColors.primary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
              ),
              const SizedBox(height: 8),
                            Text(
                'Create your account',
                style: Theme.of(context).textTheme.titleLarge,
              ),

              // D6-A: Country selector
              const SizedBox(height: 20),
              _countriesLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
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
                          hint: const Text('Select your country'),
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

              // Referral welcome banner (from URL)
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
                            const Text(
                              'Welcome! You\'re invited 🎉',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: MigoColors.success,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Sign up to get +30 MIGO Coins after your first claim.',
                              style: TextStyle(
                                fontSize: 11,
                                color: MigoColors.success
                                    .withValues(alpha: 0.9),
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

              const SizedBox(height: 32),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmController,
                obscureText: _obscure,
                decoration: const InputDecoration(
                  labelText: 'Confirm password',
                  prefixIcon: Icon(Icons.lock_outline),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _referralController,
                textCapitalization: TextCapitalization.characters,
                onChanged: (_) {
                  // If user manually edits, remove the URL flag
                  if (_referralFromUrl) {
                    setState(() => _referralFromUrl = false);
                  }
                },
                decoration: InputDecoration(
                  labelText: 'Referral code (optional)',
                  prefixIcon: const Icon(Icons.card_giftcard),
                  border: const OutlineInputBorder(),
                  suffixIcon: _referralController.text.isNotEmpty
                      ? const Icon(
                          Icons.check_circle,
                          color: MigoColors.success,
                        )
                      : null,
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
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Create account'),
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
                child: const Text('Already have an account? Log in'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
