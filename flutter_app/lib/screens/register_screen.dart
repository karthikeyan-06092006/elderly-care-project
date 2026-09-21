import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'patient_dashboard_screen.dart';
import 'caretaker_dashboard_screen.dart';

class RegisterScreen extends StatefulWidget {
  final bool isBengali;

  const RegisterScreen({super.key, this.isBengali = false});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _selectedRole = 'Patient'; // 'Patient' or 'Caretaker'
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _otpSent = false;
  bool _isLoading = false;
  bool _isSendingOtp = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isBengali ? "অনুগ্রহ করে সঠিক ইমেইল দিন" : "Please enter a valid email to get OTP",
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    setState(() => _isSendingOtp = true);

    final result = await ApiService.sendOtp(email);

    if (!mounted) return;
    setState(() => _isSendingOtp = false);

    if (result.success) {
      setState(() => _otpSent = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isBengali
                ? "ওটিপি কোড পাঠানো হয়েছে: $email"
                : result.message,
          ),
          backgroundColor: Colors.green.shade700,
          duration: const Duration(seconds: 4),
        ),
      );
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

  Future<void> _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      if (!_otpSent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isBengali ? "প্রথমে ওটিপি নিন এবং যাচাই করুন" : "Please request and enter the OTP code first",
            ),
            backgroundColor: Colors.orange.shade800,
          ),
        );
        return;
      }

      setState(() => _isLoading = true);

      final email = _emailController.text.trim();
      final otp = _otpController.text.trim();
      final password = _passwordController.text.trim();
      final name = _nameController.text.trim();
      final phone = _phoneController.text.trim();
      final role = _selectedRole.toUpperCase(); // 'PATIENT' or 'CARETAKER'

      // Step 1: Verify OTP with backend
      final otpResult = await ApiService.verifyOtp(email, otp);
      if (!otpResult.success) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(otpResult.message),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }

      // Step 2: Register user in Oracle DB
      final regResult = await ApiService.register(
        email: email,
        password: password,
        name: name,
        phone: phone,
        role: role,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (!regResult.success || regResult.data == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(regResult.message),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }

      final session = regResult.data!;

      // Step 3: Success Dialog & Role-based Routing
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.green, size: 28),
              const SizedBox(width: 8),
              Text(widget.isBengali ? "সফল নিবন্ধন!" : "Account Created!"),
            ],
          ),
          content: Text(
            widget.isBengali
                ? "আপনার ${_selectedRole == 'Patient' ? 'রোগী' : 'যত্নশীল'} অ্যাকাউন্ট ডাটাবেসে সফলভাবে তৈরি হয়েছে।"
                : "Your $_selectedRole account for $name has been saved to Oracle DB.",
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                if (session.isPatient) {
                  final profile = PatientProfile.fromSession(session);
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
              },
              child: Text(widget.isBengali ? "ড্যাশবোর্ডে যান" : "Go to Dashboard"),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBn = widget.isBengali;

    return Scaffold(
      appBar: AppBar(
        title: Text(isBn ? "নতুন অ্যাকাউন্ট" : "Create Account"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  isBn ? "নিবন্ধন সম্পন্ন করুন" : "Register New Account",
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isBn
                      ? "আপনার তথ্য দিয়ে অ্যাকাউন্ট তৈরি করুন"
                      : "Fill in the details below to set up your profile",
                  style: const TextStyle(fontSize: 15, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 24),

                // 1. Role Selection (Patient / Caretaker)
                Text(
                  isBn ? "ভূমিকা নির্বাচন করুন (Role):" : "Select Role:",
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildRoleSelectable(
                        role: 'Patient',
                        icon: Icons.elderly_rounded,
                        label: isBn ? "রোগী\n(Patient)" : "Patient\n(Old Person)",
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildRoleSelectable(
                        role: 'Caretaker',
                        icon: Icons.health_and_safety_rounded,
                        label: isBn ? "যত্নশীল\n(Caretaker)" : "Caretaker\n(Family/Nurse)",
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 2. Full Name
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(fontSize: 17),
                  decoration: InputDecoration(
                    labelText: isBn ? "পুরো নাম" : "Full Name",
                    hintText: isBn ? "উদা: সুবীর সেন" : "e.g. John Doe",
                    prefixIcon: const Icon(Icons.person_outline_rounded),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return isBn ? "নাম লিখুন" : "Please enter your full name";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // 3. Phone Number
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(fontSize: 17),
                  decoration: InputDecoration(
                    labelText: isBn ? "ফোন নম্বর" : "Phone Number",
                    hintText: "+91 98765 43210",
                    prefixIcon: const Icon(Icons.phone_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return isBn ? "ফোন নম্বর লিখুন" : "Please enter your phone number";
                    }
                    if (value.trim().length < 8) {
                      return isBn ? "সঠিক ফোন নম্বর লিখুন" : "Please enter a valid phone number";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // 4. Email Input + Get OTP Button
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(fontSize: 17),
                        decoration: InputDecoration(
                          labelText: isBn ? "ইমেইল" : "Email Address",
                          hintText: "user@example.com",
                          prefixIcon: const Icon(Icons.email_outlined),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return isBn ? "ইমেইল দিন" : "Email required";
                          }
                          if (!value.contains('@')) {
                            return isBn ? "সঠিক ইমেইল দিন" : "Invalid email";
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _isSendingOtp ? null : _sendOtp,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                        backgroundColor: _otpSent ? Colors.green : AppTheme.primary,
                      ),
                      child: _isSendingOtp
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              _otpSent ? (isBn ? "পাঠানো হয়েছে" : "Sent ✓") : (isBn ? "OTP নিন" : "Get OTP"),
                              style: const TextStyle(fontSize: 14),
                            ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // 5. OTP Code Input
                if (_otpSent) ...[
                  TextFormField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    style: const TextStyle(fontSize: 18, letterSpacing: 2),
                    decoration: InputDecoration(
                      labelText: isBn ? "৬ সংখ্যার ওটিপি (OTP)" : "6-Digit Email OTP",
                      prefixIcon: const Icon(Icons.pin_outlined),
                      helperText: isBn
                          ? "আপনার ইমেইলে পাঠানো ৬ সংখ্যার কোড লিখুন"
                          : "Enter 6-digit code received in email",
                    ),
                    validator: (value) {
                      if (value == null || value.trim().length != 6) {
                        return isBn ? "৬ সংখ্যার ওটিপি লিখুন" : "Enter 6-digit OTP code";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                ],

                // 6. Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(fontSize: 17),
                  decoration: InputDecoration(
                    labelText: isBn ? "পাসওয়ার্ড সেট করুন" : "Set Password",
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
                      return isBn ? "পাসওয়ার্ড দিন" : "Please set a password";
                    }
                    if (value.length < 6) {
                      return isBn
                          ? "কমপক্ষে ৬ অক্ষর প্রয়োজন"
                          : "Password must be at least 6 chars";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // 7. Confirm Password
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  style: const TextStyle(fontSize: 17),
                  decoration: InputDecoration(
                    labelText: isBn ? "পাসওয়ার্ড নিশ্চিত করুন" : "Confirm Password",
                    prefixIcon: const Icon(Icons.lock_reset_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(
                          () => _obscureConfirmPassword = !_obscureConfirmPassword,
                        );
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return isBn ? "পাসওয়ার্ড মিলছে না" : "Passwords do not match";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Register Submit Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
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
                          isBn ? "অ্যাকাউন্ট তৈরি করুন" : "Create Account",
                          style: const TextStyle(fontSize: 18),
                        ),
                ),
                const SizedBox(height: 20),

                // Switch to Login
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isBn ? "ইতিমধ্যে অ্যাকাউন্ট আছে? " : "Already have an account? ",
                      style: const TextStyle(fontSize: 15, color: AppTheme.textSecondary),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LoginScreen(isBengali: isBn),
                          ),
                        );
                      },
                      child: Text(
                        isBn ? "লগ ইন করুন" : "Log In",
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

  Widget _buildRoleSelectable({
    required String role,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryLight : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primary : const Color(0xFFCFD8DC),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
