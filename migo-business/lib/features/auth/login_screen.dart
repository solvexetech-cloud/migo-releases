import 'package:flutter/material.dart';

import '../../services/auth_service.dart';

/// PHASE I — Business Login Screen
/// Responsive: PC (wide) + Mobile
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await AuthService.instance.signIn(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;

        if (result['success'] == true) {
      // AuthGate will auto-navigate to Dashboard
      // No manual navigation needed
    } else {
      setState(() {
        _error = result['error'] as String? ?? 'Login failed';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Card(
              elevation: isWide ? 8 : 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: EdgeInsets.all(isWide ? 40 : 24),
                child: _buildForm(isWide),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(bool isWide) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Logo
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: isWide ? 60 : 50,
                height: isWide ? 60 : 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF0C566), Color(0xFFD4A13A)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(
                  '🎁',
                  style: TextStyle(fontSize: isWide ? 32 : 26),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MIGO',
                    style: TextStyle(
                      fontSize: isWide ? 28 : 24,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF0B2B5B),
                      letterSpacing: 3,
                    ),
                  ),
                  Text(
                    'BUSINESS',
                    style: TextStyle(
                      fontSize: isWide ? 12 : 10,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF6B7280),
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),

          Text(
            'Welcome back',
            style: TextStyle(
              fontSize: isWide ? 24 : 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Sign in to manage your business',
            style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 28),

          // Email
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            enabled: !_loading,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
              border: OutlineInputBorder(),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email required';
              if (!v.contains('@')) return 'Invalid email';
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Password
          TextFormField(
            controller: _passwordController,
            obscureText: _obscure,
            enabled: !_loading,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline),
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Password required';
              if (v.length < 6) return 'Minimum 6 characters';
              return null;
            },
          ),

          // Error
          if (_error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Sign in button
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _loading ? null : _handleLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0B2B5B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Sign In',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 20),

          Text(
            'Business accounts only.\nContact MIGO to register.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}