import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/profile_storage_service.dart';
import 'register_screen.dart';
import 'patient_dashboard_screen.dart';
import 'caretaker_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  final bool isBengali;

  const LoginScreen({super.key, this.isBengali = false});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      final result = await ApiService.login(email: email, password: password);

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (result.success && result.data != null) {
        final session = result.data!;

        if (session.isPatient) {
          final profile = await ProfileStorageService.hydrateProfile(
            PatientProfile.fromSession(session),
          );
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PatientDashboardScreen(
                profile: profile,
                isBengali: widget.isBengali,
              ),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => CaretakerDashboardScreen(
                session: session,
              ),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBn = widget.isBengali;

    return Scaffold(
      appBar: AppBar(
        title: Text(isBn ? "লগ ইন" : "Log In"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10),
                Text(
                  isBn ? "আপনার অ্যাকাউন্টে প্রবেশ করুন" : "Welcome Back",
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isBn
                      ? "ইমেইল এবং পাসওয়ার্ড দিয়ে প্রবেশ করুন"
                      : "Enter your email and password to access your dashboard",
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),

                // Email Input
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(fontSize: 17),
                  decoration: InputDecoration(
                    labelText: isBn ? "ইমেইল ঠিকানা" : "Email Address",
                    hintText: "name@example.com",
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return isBn ? "ইমেইল লিখুন" : "Please enter your email";
                    }
                    if (!value.contains('@') || !value.contains('.')) {
                      return isBn ? "সঠিক ইমেইল লিখুন" : "Please enter a valid email address";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 22),

                // Password Input
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(fontSize: 17),
                  decoration: InputDecoration(
                    labelText: isBn ? "পাসওয়ার্ড" : "Password",
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return isBn ? "পাসওয়ার্ড লিখুন" : "Please enter your password";
                    }
                    if (value.length < 6) {
                      return isBn
                          ? "পাসওয়ার্ড কমপক্ষে ৬ অক্ষরের হতে হবে"
                          : "Password must be at least 6 characters";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 40),

                // Login Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          isBn ? "লগ ইন" : "Log In",
                          style: const TextStyle(fontSize: 18),
                        ),
                ),
                const SizedBox(height: 26),

                // Switch to Register
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isBn ? "অ্যাকাউন্ট নেই? " : "Don't have an account? ",
                      style: const TextStyle(fontSize: 15, color: AppTheme.textSecondary),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RegisterScreen(isBengali: isBn),
                          ),
                        );
                      },
                      child: Text(
                        isBn ? "নিবন্ধন করুন" : "Register Now",
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
