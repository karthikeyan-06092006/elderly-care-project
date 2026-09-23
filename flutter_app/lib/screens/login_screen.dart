import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/profile_storage_service.dart';
import 'register_screen.dart';
import 'patient_dashboard_screen.dart';
import 'caretaker_dashboard_screen.dart';
import 'healthcare_worker_dashboard_screen.dart';
import 'admin_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  final bool isBengali;

  const LoginScreen({super.key, this.isBengali = false});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final identifier = _identifierController.text.trim();
      final password = _passwordController.text.trim();

      final result = await ApiService.login(email: identifier, password: password);

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (result.success && result.data != null) {
        final session = result.data!;
        await ProfileStorageService.saveSession(session);

        if (session.isAdmin) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => AdminDashboardScreen(session: session),
            ),
          );
        } else if (session.isHealthcareWorker) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HealthcareWorkerDashboardScreen(session: session),
            ),
          );
        } else if (session.isPatient) {
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
                      ? "ফোন নম্বর বা ইমেইল এবং পাসওয়ার্ড দিন"
                      : "Enter your Phone Number (or Email) and password to login",
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),

                // Identifier Input (Phone or Email)
                TextFormField(
                  controller: _identifierController,
                  keyboardType: TextInputType.text,
                  style: const TextStyle(fontSize: 17),
                  decoration: InputDecoration(
                    labelText: isBn ? "ফোন নম্বর অথবা ইমেইল" : "Phone Number or Email",
                    hintText: "9876543210 or admin@cognitivecare.com",
                    prefixIcon: const Icon(Icons.person_outline_rounded),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return isBn ? "ফোন নম্বর বা ইমেইল লিখুন" : "Please enter phone number or email";
                    }
                    if (value.trim().length < 4) {
                      return isBn ? "সঠিক তথ্য লিখুন" : "Please enter a valid credential";
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
                    if (value.length < 4) {
                      return isBn
                          ? "পাসওয়ার্ড কমপক্ষে ৪ অক্ষরের হতে হবে"
                          : "Password must be at least 4 characters";
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
