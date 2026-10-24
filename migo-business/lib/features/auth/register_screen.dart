import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _businessNameController = TextEditingController();

  String _selectedCountry = 'QA';
  bool _loading = false;
  bool _obscure = true;

  final List<Map<String, String>> _countries = [
    {'code': 'QA', 'name': 'Qatar 🇶🇦'},
    {'code': 'AE', 'name': 'UAE 🇦🇪'},
    {'code': 'SA', 'name': 'Saudi Arabia 🇸🇦'},
    {'code': 'KW', 'name': 'Kuwait 🇰🇼'},
    {'code': 'OM', 'name': 'Oman 🇴🇲'},
    {'code': 'BH', 'name': 'Bahrain 🇧🇭'},
    {'code': 'IN', 'name': 'India 🇮🇳'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _businessNameController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      // 1. Firebase Auth-ൽ യൂസറെ ഉണ്ടാക്കുന്നു
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final uid = userCredential.user?.uid;
      if (uid == null) throw Exception('User creation failed');

      // 2. Firestore-ൽ ബിസിനസ്സ് വിവരങ്ങൾ സേവ് ചെയ്യുന്നു
      final businessRef = FirebaseFirestore.instance.collection('businesses').doc();
      
      await businessRef.set({
        'ownerUid': uid,
        'name': _businessNameController.text.trim(),
        'ownerName': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'countryCode': _selectedCountry,
        'status': 'pending', // അഡ്മിൻ അപ്രൂവ് ചെയ്യേണ്ടതുണ്ട്
        'logoUrl': '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 3. users കളക്ഷനിലും ഇതേ വിവരങ്ങൾ സേവ് ചെയ്യുന്നു (കൺട്രി ഫിൽട്ടറിനായി)
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'uid': uid,
        'email': _emailController.text.trim(),
        'displayName': _nameController.text.trim(),
        'businessName': _businessNameController.text.trim(),
        'country': _selectedCountry,
        'role': 'business_owner',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        // രജിസ്ട്രേഷൻ വിജയിച്ചാൽ ലോഗിൻ സ്ക്രീനിലേക്ക് തിരികെ പോകുന്നു
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful! Please login.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String message = 'Registration failed';
        if (e.code == 'email-already-in-use') {
          message = 'This email is already registered.';
        } else if (e.code == 'weak-password') {
          message = 'Password is too weak.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Register Business'),
        backgroundColor: const Color(0xFF0B2B5B),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Card(
              elevation: isWide ? 8 : 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: EdgeInsets.all(isWide ? 40 : 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Create an Account',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0B2B5B),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // പേര്
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Your Name',
                          prefixIcon: Icon(Icons.person_outline),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Name required' : null,
                      ),
                      const SizedBox(height: 16),

                      // ബിസിനസ്സ് നെയിം
                      TextFormField(
                        controller: _businessNameController,
                        decoration: const InputDecoration(
                          labelText: 'Business Name',
                          prefixIcon: Icon(Icons.store),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Business name required' : null,
                      ),
                      const SizedBox(height: 16),

                      // ഇമെയിൽ
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
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

                      // കൺട്രി
                      DropdownButtonFormField<String>(
                        value: _selectedCountry,
                        decoration: const InputDecoration(
                          labelText: 'Country',
                          prefixIcon: Icon(Icons.public),
                          border: OutlineInputBorder(),
                        ),
                        items: _countries.map((c) {
                          return DropdownMenuItem(
                            value: c['code'],
                            child: Text(c['name']!),
                          );
                        }).toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _selectedCountry = v);
                        },
                      ),
                      const SizedBox(height: 16),

                      // പാസ്‌വേഡ്
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscure,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
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
                      const SizedBox(height: 24),

                      // രജിസ്റ്റർ ബട്ടൺ
                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _handleRegister,
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
                                  'Register',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ലോഗിൻ സ്ക്രീനിലേക്ക് പോകാൻ
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Already have an account? Login',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0B2B5B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}