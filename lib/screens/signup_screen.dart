import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'main_shell.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _referralController = TextEditingController();
  bool _obscurePassword = true;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _referralController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
      final refCode = _referralController.text.trim();
      final success = await auth.signUp(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        username: _usernameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        password: _passwordController.text,
        referredBy: refCode.isEmpty ? null : refCode,
      );
    if (!mounted) return;
    if (success) {
      await auth.sendVerificationEmail();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created! Check your email for verification link.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 5),
        ),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainShell()),
        (route) => false,
      );
    } else if (auth.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error!), backgroundColor: Colors.red),
      );
      auth.clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A237E), Color(0xFF283593), Color(0xFF3949AB)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person_add, size: 40, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    const Text('Create Account',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        )),
                    const SizedBox(height: 32),
                    Card(
                      elevation: 8,
                      shadowColor: Colors.black.withValues(alpha: 0.3),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _nameController,
                                decoration: const InputDecoration(
                                  labelText: 'Full Name',
                                  prefixIcon: Icon(Icons.person_outlined),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Enter your name';
                                  if (v.trim().length < 2) return 'Name too short';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _emailController,
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: Icon(Icons.email_outlined),
                                ),
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Enter your email';
                                  final regex = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,}$');
                                  if (!regex.hasMatch(v.trim())) return 'Invalid email format';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _usernameController,
                                decoration: const InputDecoration(
                                  labelText: 'Username',
                                  prefixIcon: Icon(Icons.alternate_email),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Choose a username';
                                  if (v.trim().length < 3) return 'At least 3 characters';
                                  if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(v.trim())) return 'Letters, numbers, underscore only';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _phoneController,
                                decoration: const InputDecoration(
                                  labelText: 'Phone Number',
                                  prefixIcon: Icon(Icons.phone_outlined),
                                  hintText: '07XX XXX XXX or 2547XX XXX XXX',
                                ),
                                keyboardType: TextInputType.phone,
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Enter your phone number';
                                  final cleaned = v.replaceAll(RegExp(r'\s+'), '');
                                  if (cleaned.length < 10 || cleaned.length > 13) return 'Invalid phone number';
                                  if (!RegExp(r'^(0|254|\+254)\d{9}$').hasMatch(cleaned)) return 'Enter a valid Kenyan number (e.g. 0712345678)';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _passwordController,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: const Icon(Icons.lock_outlined),
                                  suffixIcon: IconButton(
                                    icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                  ),
                                ),
                                obscureText: _obscurePassword,
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Enter a password';
                                  if (v.length < 8) return 'At least 8 characters';
                                  if (!RegExp(r'[A-Za-z]').hasMatch(v)) return 'Must contain a letter';
                                  if (!RegExp(r'[0-9]').hasMatch(v)) return 'Must contain a number';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _confirmPasswordController,
                                decoration: const InputDecoration(
                                  labelText: 'Confirm Password',
                                  prefixIcon: Icon(Icons.lock_outline),
                                ),
                                obscureText: true,
                                validator: (v) {
                                  if (v != _passwordController.text) return 'Passwords do not match';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _referralController,
                                decoration: InputDecoration(
                                  labelText: 'Referral Code (optional)',
                                  prefixIcon: const Icon(Icons.card_giftcard),
                                  hintText: 'Enter a friend\'s code',
                                ),
                              ),
                              const SizedBox(height: 20),
                              Consumer<AuthProvider>(
                                builder: (_, auth, __) => SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: auth.isLoading ? null : _signUp,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1A237E),
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                    ),
                                    child: auth.isLoading
                                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                        : const Text('Create Account', style: TextStyle(fontSize: 16)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(foregroundColor: Colors.white),
                      child: const Text('Already have an account? Sign In',
                          style: TextStyle(fontSize: 15)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
