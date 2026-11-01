import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 🆕 ഫയർബേസ് ഓത് ഇമ്പോർട്ട്
import '../../core/config/app_config.dart';
import '../../core/localization/locale_provider.dart'; // 🆕 ഭാഷ മനസ്സിലാക്കാൻ
import '../../core/theme/migo_colors.dart';
import '../../services/auth_service.dart';
import '../main/main_shell.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please enter email and password.');
      return;
    }

    setState(() => _loading = true);
    try {
      await AuthService.instance.signIn(email: email, password: password);
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

  // 🆕 പാസ്‌വേഡ് റീസെറ്റ് ഡയലോഗ് (അറബി + ഇംഗ്ലീഷ്)
  Future<void> _showForgotPasswordDialog() async {
    final resetEmailController = TextEditingController();
    if (_emailController.text.trim().isNotEmpty) {
      resetEmailController.text = _emailController.text.trim();
    }

    return showDialog(
      context: context,
      builder: (ctx) {
        bool isSending = false;
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            // 🆕 ഭാഷ ചെക്ക് ചെയ്യുന്നു
            final isAr = LocaleProvider.instance.locale == 'ar';

            return Directionality(
              textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
              child: AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: Text(isAr ? 'إعادة تعيين كلمة المرور' : 'Reset Password'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isAr
                          ? 'أدخل بريدك الإلكتروني المسجل. سنرسل لك رابطًا لإعادة تعيين كلمة المرور.'
                          : 'Enter your registered email address. We will send you a link to reset your password.',
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                      textAlign: isAr ? TextAlign.right : TextAlign.left,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: resetEmailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: isAr ? 'البريد الإلكتروني' : 'Email',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: isSending ? null : () => Navigator.pop(ctx),
                    child: Text(isAr ? 'إلغاء' : 'Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: isSending
                        ? null
                        : () async {
                            final email = resetEmailController.text.trim();
                            if (email.isEmpty) return;

                            setStateDialog(() => isSending = true);
                            try {
                              await FirebaseAuth.instance
                                  .sendPasswordResetEmail(email: email);
                              if (!ctx.mounted) return;
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isAr
                                        ? 'تم إرسال رابط إعادة التعيين إلى بريدك الإلكتروني!'
                                        : 'Password reset link sent to your email!',
                                  ),
                                  backgroundColor: MigoColors.success,
                                ),
                              );
                            } catch (e) {
                              if (!ctx.mounted) return;
                              setStateDialog(() => isSending = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isAr ? 'خطأ: ${e.toString()}' : 'Error: ${e.toString()}',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                    child: isSending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(isAr ? 'إرسال الرابط' : 'Send Link'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // 🆕 ListenableBuilder ഉപയോഗിച്ച് ഭാഷ മാറുമ്പോൾ UI അപ്ഡേറ്റ് ചെയ്യുന്നു
    return ListenableBuilder(
      listenable: LocaleProvider.instance,
      builder: (context, _) {
        final isAr = LocaleProvider.instance.locale == 'ar';

        return Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
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
                            letterSpacing: isAr ? 0 : 2,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isAr ? 'مرحبًا بعودتك' : 'Welcome back',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 32),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: InputDecoration(
                        labelText: isAr ? 'البريد الإلكتروني' : 'Email',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText: isAr ? 'كلمة المرور' : 'Password',
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
                    
                    // 🆕 ഫോർഗെറ്റ് പാസ്‌വേഡ് ബട്ടൺ
                    Align(
                      alignment: isAr ? Alignment.centerLeft : Alignment.centerRight,
                      child: TextButton(
                        onPressed: _loading ? null : _showForgotPasswordDialog,
                        child: Text(
                          isAr ? 'هل نسيت كلمة المرور؟' : 'Forgot Password?',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
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
                            : Text(isAr ? 'تسجيل الدخول' : 'Log in'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _loading
                          ? null
                          : () {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (_) => const SignupScreen(),
                                ),
                              );
                            },
                      child: Text(
                        isAr ? 'جديد في ميجو؟ إنشاء حساب' : 'New to MIGO? Create account',
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
}