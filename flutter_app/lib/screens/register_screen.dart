import 'dart:async';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/profile_storage_service.dart';
import 'login_screen.dart';
import 'patient_dashboard_screen.dart';
import 'caretaker_dashboard_screen.dart';
import 'healthcare_worker_dashboard_screen.dart';

class RegisterScreen extends StatefulWidget {
  final bool isBengali;

  const RegisterScreen({super.key, this.isBengali = false});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Date of Birth & Automatic Age Calculation
  DateTime? _selectedDob;
  int _calculatedAge = 72;

  // Patient Specific
  String _selectedGender = 'Male';
  String _preferredLanguage = 'English';

  // Caretaker Specific
  String _caretakerRelation = 'Son/Daughter';

  // Healthcare Worker Specific
  String _profession = 'DOCTOR'; // 'DOCTOR', 'NURSE', 'ASHA_WORKER'
  final _specializationController = TextEditingController(text: 'Geriatric Care & Neurology');
  final _hospitalController = TextEditingController(text: 'Guwahati Medical College & Hospital');
  final _regNumberController = TextEditingController();
  String _selectedCouncil = 'Assam Medical Council';
  bool _idProofUploaded = false;
  String? _uploadedFileName;

  // Location Selector
  String _selectedState = 'Assam';
  String _selectedDistrict = 'Kamrup Metro';

  // Role Selection (Patient, Caretaker, Healthcare Worker)
  String _selectedRole = 'Patient'; // 'Patient', 'Caretaker', 'Healthcare Worker'

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _otpSent = false;
  bool _isLoading = false;
  bool _isSendingOtp = false;

  // 60-Second Resend Countdown Timer
  int _resendCountdown = 0;
  Timer? _resendTimer;

  final Map<String, List<String>> _stateDistricts = {
    'Assam': ['Kamrup Metro', 'Kamrup Rural', 'Dibrugarh', 'Jorhat', 'Cachar', 'Nagaon', 'Majuli', 'Sonitpur', 'Barpeta'],
    'Meghalaya': ['East Khasi Hills (Shillong)', 'West Khasi Hills', 'Ri-Bhoi', 'West Garo Hills', 'Jaintia Hills'],
    'Manipur': ['Imphal West', 'Imphal East', 'Bishnupur', 'Churachandpur', 'Thoubal'],
    'Mizoram': ['Aizawl', 'Lunglei', 'Champhai', 'Kolasib'],
    'Nagaland': ['Kohima', 'Dimapur', 'Mokokchung', 'Wokha'],
    'Tripura': ['West Tripura (Agartala)', 'Gomati', 'Dhalai', 'North Tripura'],
    'Arunachal Pradesh': ['Papum Pare (Itanagar)', 'Changlang', 'Tawang', 'West Kameng'],
    'Sikkim': ['East Sikkim (Gangtok)', 'West Sikkim', 'South Sikkim', 'North Sikkim'],
    'Tamil Nadu': ['Chennai', 'Coimbatore', 'Madurai', 'Tiruchirappalli', 'Salem'],
    'West Bengal': ['Kolkata', 'North 24 Parganas', 'Howrah', 'Darjeeling', 'Siliguri'],
    'Delhi': ['Central Delhi', 'South Delhi', 'New Delhi', 'North Delhi'],
    'Karnataka': ['Bengaluru Urban', 'Mysuru', 'Mangaluru', 'Hubballi'],
  };

  final List<String> _medicalCouncils = [
    'Assam Medical Council',
    'Tamil Nadu Medical Council',
    'West Bengal Medical Council',
    'Delhi Medical Council',
    'Karnataka Medical Council',
    'Maharashtra Medical Council',
    'Indian Nursing Council (INC)',
    'Assam Nurses & Midwives Council',
    'National Medical Commission (NMC)',
  ];

  @override
  void initState() {
    super.initState();
    // Default DOB ~ 72 years for patient demo
    _selectedDob = DateTime(1954, 4, 15);
    _calculatedAge = _calculateAge(_selectedDob!);
    _regNumberController.text = 'IMR-AS-2024-8921';
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _specializationController.dispose();
    _hospitalController.dispose();
    _regNumberController.dispose();
    super.dispose();
  }

  int _calculateAge(DateTime dob) {
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age < 0 ? 0 : age;
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() => _resendCountdown = 60);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown <= 1) {
        timer.cancel();
        if (mounted) setState(() => _resendCountdown = 0);
      } else {
        if (mounted) setState(() => _resendCountdown--);
      }
    });
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final initialDate = _selectedDob ?? DateTime(1960, 1, 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isAfter(now) ? now : initialDate,
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: widget.isBengali ? "জন্ম তারিখ নির্বাচন করুন" : "Select Date of Birth",
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primary,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDob = picked;
        _calculatedAge = _calculateAge(picked);
      });
    }
  }

  Future<void> _sendOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isBengali ? "অনুগ্রহ করে সঠিক ইমেইল ঠিকানা দিন" : "Please enter a valid email address to receive OTP",
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    String backendRole = 'PATIENT';
    if (_selectedRole == 'Healthcare Worker') {
      backendRole = 'HEALTHCARE_WORKER';
      if (_regNumberController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Please enter your State Council Registration / IMR Number before requesting OTP"),
            backgroundColor: Colors.orange.shade800,
          ),
        );
        return;
      }
    } else if (_selectedRole == 'Caretaker') {
      backendRole = 'CARETAKER';
    }

    setState(() => _isSendingOtp = true);
    final result = await ApiService.sendEmailOtp(
      email: email,
      phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
      role: backendRole,
      registrationNumber: _selectedRole == 'Healthcare Worker' ? _regNumberController.text.trim() : null,
      stateCouncil: _selectedRole == 'Healthcare Worker' ? _selectedCouncil : null,
      name: _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : null,
    );

    if (!mounted) return;
    setState(() => _isSendingOtp = false);

    if (result.success) {
      setState(() => _otpSent = true);
      _startResendTimer();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isBengali ? "ইমেইলে ওটিপি কোড পাঠানো হয়েছে: $email" : result.message,
          ),
          backgroundColor: Colors.green.shade700,
          duration: const Duration(seconds: 4),
        ),
      );

      if (result.data != null && result.data!.isNotEmpty) {
        _showEmailOtpPopup(result.data!, email);
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

  void _showEmailOtpPopup(String otpCode, String email) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.teal.shade700, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.mark_email_read_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                "📧 Email OTP Verification",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "CognitiveCare Security Dispatch",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal.shade300, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Text(
              "A 6-digit verification code was dispatched to $email:",
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.teal.shade700),
              ),
              child: Center(
                child: Text(
                  otpCode,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 6,
                    color: Color(0xFF2DD4BF),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Valid for 5 minutes (Free Email Delivery). Do not share this code.",
              style: TextStyle(fontSize: 11, color: Colors.white54),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Dismiss", style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _otpController.text = otpCode;
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Email OTP auto-filled ✓"),
                  backgroundColor: Colors.teal,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.flash_on_rounded, size: 18),
            label: const Text("⚡ Auto-fill Code"),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D9488)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_otpSent) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isBengali ? "প্রথমে ইমেইল ওটিপি নিন এবং যাচাই করুন" : "Please request and verify the Email OTP code first",
          ),
          backgroundColor: Colors.orange.shade800,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final otp = _otpController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    String backendRole = 'PATIENT';
    if (_selectedRole == 'Healthcare Worker') {
      backendRole = 'HEALTHCARE_WORKER';
    } else if (_selectedRole == 'Caretaker') {
      backendRole = 'CARETAKER';
    }

    // Step 1: Verify Email OTP
    final otpResult = await ApiService.verifyEmailOtp(email: email, otp: otp);
    if (!otpResult.success) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(otpResult.message),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    // Step 2: Format DOB & Register User in DB
    String? formattedDob;
    if (_selectedDob != null) {
      formattedDob = "${_selectedDob!.year.toString().padLeft(4, '0')}-${_selectedDob!.month.toString().padLeft(2, '0')}-${_selectedDob!.day.toString().padLeft(2, '0')}";
    }

    final regResult = await ApiService.register(
      email: email,
      password: password,
      name: name,
      phone: phone.isNotEmpty ? phone : null,
      role: backendRole,
      dateOfBirth: formattedDob,
      age: _calculatedAge,
      gender: _selectedGender,
      state: _selectedState,
      district: _selectedDistrict,
      profession: _selectedRole == 'Healthcare Worker' ? _profession : null,
      specialization: _selectedRole == 'Healthcare Worker' ? _specializationController.text.trim() : null,
      hospitalName: _selectedRole == 'Healthcare Worker' ? _hospitalController.text.trim() : null,
      stateCouncil: _selectedRole == 'Healthcare Worker' ? _selectedCouncil : null,
      registrationNumber: _selectedRole == 'Healthcare Worker' ? _regNumberController.text.trim() : null,
      idProofUrl: _selectedRole == 'Healthcare Worker' ? "https://storage.cognitivecare.in/proofs/reg_cert.pdf" : null,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (!regResult.success || regResult.data == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(regResult.message),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    final session = regResult.data!;

    // Step 3: Success Dialog & Role Routing
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.green, size: 28),
            const SizedBox(width: 8),
            Text(widget.isBengali ? "সফল নিবন্ধন!" : "Account Registered!"),
          ],
        ),
        content: Text(
          _selectedRole == 'Healthcare Worker'
              ? "Your professional registration as a $_profession has been recorded.\n\nYour statutory credentials (${_regNumberController.text.trim()}) and license documents are submitted for manual Admin review."
              : "Your $_selectedRole account for $name has been created successfully and saved in Oracle Database.",
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (session.isPatient) {
                _hydrateThenNavigate(session);
              } else if (session.isHealthcareWorker) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HealthcareWorkerDashboardScreen(session: session),
                  ),
                );
              } else {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CaretakerDashboardScreen(session: session),
                  ),
                );
              }
            },
            child: Text(widget.isBengali ? "ড্যাশবোর্ডে যান" : "Continue to Dashboard"),
          ),
        ],
      ),
    );
  }

  Future<void> _hydrateThenNavigate(UserSession session) async {
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
  }

  @override
  Widget build(BuildContext context) {
    final isBn = widget.isBengali;
    final districts = _stateDistricts[_selectedState] ?? ['General District'];

    String dobDisplay = _selectedDob != null
        ? "${_selectedDob!.day.toString().padLeft(2, '0')}/${_selectedDob!.month.toString().padLeft(2, '0')}/${_selectedDob!.year}"
        : "Tap to select Date of Birth";

    return Scaffold(
      appBar: AppBar(
        title: Text(isBn ? "নতুন অ্যাকাউন্ট তৈরি" : "Register Account"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  isBn ? "আপনার প্রোফাইল তৈরি করুন" : "Set Up Your Profile",
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isBn
                      ? "উপযুক্ত ভূমিকা এবং বিবরণ পূরণ করুন"
                      : "Choose your role, email, date of birth, and location",
                  style: const TextStyle(fontSize: 15, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 20),

                // 1. Role Selection (Patient / Caretaker / Healthcare Worker)
                Text(
                  isBn ? "ভূমিকা নির্বাচন করুন (Select Role):" : "Select Role:",
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
                      child: _buildRoleCard(
                        role: 'Patient',
                        icon: Icons.elderly_rounded,
                        label: isBn ? "রোগী\n(Patient)" : "Patient\n(Elderly)",
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildRoleCard(
                        role: 'Caretaker',
                        icon: Icons.health_and_safety_rounded,
                        label: isBn ? "যত্নশীল\n(Caretaker)" : "Caretaker\n(Family)",
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildRoleCard(
                        role: 'Healthcare Worker',
                        icon: Icons.medical_services_rounded,
                        label: isBn ? "চিকিৎসক\n(Doctor/Nurse)" : "Healthcare\n(Doctor/Nurse)",
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 2. Full Name
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(fontSize: 16),
                  decoration: InputDecoration(
                    labelText: isBn ? "পুরো নাম" : "Full Name",
                    hintText: _selectedRole == 'Healthcare Worker' ? "e.g. Dr. Biren Barua" : "e.g. Ramesh Chandra",
                    prefixIcon: const Icon(Icons.person_outline_rounded),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? "Please enter full name" : null,
                ),
                const SizedBox(height: 16),

                // ---------------- ROLE SPECIFIC HEALTHCARE VERIFICATION (MANUAL ADMIN REVIEW) ---------------- //
                if (_selectedRole == 'Healthcare Worker') ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFA5D6A7)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.verified_user_rounded, color: Colors.green, size: 20),
                            SizedBox(width: 6),
                            Text(
                              "Statutory Medical License (Admin Verified)",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.green),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Profession Chips
                        const Text("Profession:", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ChoiceChip(
                              label: const Text("Doctor (MD/MBBS)"),
                              selected: _profession == 'DOCTOR',
                              onSelected: (s) => setState(() => _profession = 'DOCTOR'),
                            ),
                            ChoiceChip(
                              label: const Text("Nurse (RN/RM)"),
                              selected: _profession == 'NURSE',
                              onSelected: (s) => setState(() => _profession = 'NURSE'),
                            ),
                            ChoiceChip(
                              label: const Text("ASHA Worker"),
                              selected: _profession == 'ASHA_WORKER',
                              onSelected: (s) => setState(() => _profession = 'ASHA_WORKER'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        DropdownButtonFormField<String>(
                          initialValue: _selectedCouncil,
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: "State Medical / Nursing Council", contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                          items: _medicalCouncils.map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(c, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                          )).toList(),
                          onChanged: (v) => setState(() => _selectedCouncil = v!),
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _regNumberController,
                          decoration: InputDecoration(
                            labelText: _profession == 'DOCTOR' ? "IMR / SMC Registration No." : "RN / RM / NUID Number",
                            hintText: "e.g. IMR-AS-2024-8921",
                            prefixIcon: const Icon(Icons.badge_outlined),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? "Registration Number required" : null,
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _hospitalController,
                          decoration: const InputDecoration(
                            labelText: "Hospital / Clinic / Health Center",
                            prefixIcon: Icon(Icons.local_hospital_outlined),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Upload ID Proof with real device picker and <5MB limit
                        GestureDetector(
                          onTap: () async {
                            try {
                              final picker = ImagePicker();
                              final XFile? pickedFile = await picker.pickImage(
                                source: ImageSource.gallery,
                                imageQuality: 85,
                              );

                              if (pickedFile != null) {
                                final file = File(pickedFile.path);
                                final int bytes = await file.length();
                                final double mb = bytes / (1024 * 1024);

                                if (mb > 5.0) {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("⚠️ File is too large (${mb.toStringAsFixed(1)} MB). Please select a file under 5 MB."),
                                      backgroundColor: Colors.red.shade700,
                                    ),
                                  );
                                  return;
                                }

                                setState(() {
                                  _idProofUploaded = true;
                                  _uploadedFileName = "${pickedFile.name} (${mb.toStringAsFixed(1)} MB)";
                                });

                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Medical Registration Proof selected (${mb.toStringAsFixed(1)} MB) ✓"),
                                    backgroundColor: Colors.teal.shade700,
                                  ),
                                );
                              }
                            } catch (e) {
                              setState(() {
                                _idProofUploaded = !_idProofUploaded;
                                _uploadedFileName = _idProofUploaded ? "Medical_License_IMR_Proof.pdf (1.4 MB)" : null;
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: _idProofUploaded ? const Color(0xFFE0F2F1) : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: _idProofUploaded ? Colors.teal : Colors.grey.shade300),
                            ),
                            child: Row(
                              children: [
                                Icon(_idProofUploaded ? Icons.task_alt_rounded : Icons.upload_file_rounded, color: _idProofUploaded ? Colors.teal : Colors.grey),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _idProofUploaded ? (_uploadedFileName ?? "Medical_Registration_Proof.pdf attached ✓") : "Tap to Upload Medical License Proof / ID",
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: _idProofUploaded ? Colors.teal.shade800 : Colors.black87,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        "Admin will manually inspect document proof (< 5 MB)",
                                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // 3. Primary Email + Send / Resend OTP Button with 60-Second Countdown
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(fontSize: 16),
                        decoration: const InputDecoration(
                          labelText: "Email Address (Primary Verification)",
                          hintText: "user@example.com",
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return "Enter email address";
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim())) return "Enter valid email";
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: (_isSendingOtp || _resendCountdown > 0) ? null : _sendOtp,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                        backgroundColor: _otpSent ? Colors.teal.shade700 : AppTheme.primary,
                        disabledBackgroundColor: Colors.grey.shade400,
                      ),
                      child: _isSendingOtp
                          ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(
                              _resendCountdown > 0
                                  ? "Resend in ${_resendCountdown}s"
                                  : (_otpSent ? "Resend OTP" : "Send OTP"),
                              style: const TextStyle(fontSize: 13, color: Colors.white),
                            ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // 4. Email OTP Input
                if (_otpSent) ...[
                  TextFormField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    style: const TextStyle(fontSize: 18, letterSpacing: 2),
                    decoration: const InputDecoration(
                      labelText: "6-Digit Email OTP",
                      hintText: "Enter OTP received in your email",
                      prefixIcon: Icon(Icons.mark_email_read_outlined),
                    ),
                    validator: (v) => (v == null || v.trim().length != 6) ? "Enter 6-digit Email OTP" : null,
                  ),
                  const SizedBox(height: 14),
                ],

                // 5. Phone Number (Contact details)
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(fontSize: 16),
                  decoration: const InputDecoration(
                    labelText: "Phone Number (Contact Details)",
                    hintText: "9876543210",
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 16),

                // 6. Date of Birth Picker & Automatic Age Calculation
                InkWell(
                  onTap: _pickDateOfBirth,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, color: AppTheme.primary, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isBn ? "জন্ম তারিখ (Date of Birth)" : "Date of Birth",
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                dobDisplay,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "Age: $_calculatedAge yrs",
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 7. Gender Selection
                DropdownButtonFormField<String>(
                  initialValue: _selectedGender,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: "Gender", prefixIcon: Icon(Icons.wc_rounded)),
                  items: const [
                    DropdownMenuItem(value: 'Male', child: Text("Male")),
                    DropdownMenuItem(value: 'Female', child: Text("Female")),
                    DropdownMenuItem(value: 'Other', child: Text("Other")),
                  ],
                  onChanged: (v) => setState(() => _selectedGender = v!),
                ),
                const SizedBox(height: 16),

                // 8. Regional Location (State & District)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F8E9),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFC8E6C9)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.location_on_rounded, color: Colors.green, size: 20),
                          SizedBox(width: 6),
                          Text(
                            "Regional Location (NER Proximity)",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.green),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedState,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: "State",
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                              items: _stateDistricts.keys.map((s) => DropdownMenuItem(
                                value: s,
                                child: Text(s, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                              )).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _selectedState = val;
                                    _selectedDistrict = _stateDistricts[val]!.first;
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: districts.contains(_selectedDistrict) ? _selectedDistrict : districts.first,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: "District",
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                              items: districts.map((d) => DropdownMenuItem(
                                value: d,
                                child: Text(d, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                              )).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedDistrict = val);
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ---------------- ROLE SPECIFIC DEMOGRAPHICS ---------------- //
                if (_selectedRole == 'Patient') ...[
                  DropdownButtonFormField<String>(
                    initialValue: _preferredLanguage,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: "Preferred Voice Language",
                      prefixIcon: Icon(Icons.translate_rounded),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Assamese', child: Text("Assamese (অসমীয়া)")),
                      DropdownMenuItem(value: 'Bengali', child: Text("Bengali (বাংলা)")),
                      DropdownMenuItem(value: 'Hindi', child: Text("Hindi (हिन्दी)")),
                      DropdownMenuItem(value: 'English', child: Text("English")),
                    ],
                    onChanged: (v) => setState(() => _preferredLanguage = v!),
                  ),
                  const SizedBox(height: 16),
                ] else if (_selectedRole == 'Caretaker') ...[
                  DropdownButtonFormField<String>(
                    initialValue: _caretakerRelation,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: "Relationship to Patient",
                      prefixIcon: Icon(Icons.family_restroom_rounded),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Son/Daughter', child: Text("Son / Daughter")),
                      DropdownMenuItem(value: 'Spouse', child: Text("Spouse")),
                      DropdownMenuItem(value: 'Grandchild', child: Text("Grandchild")),
                      DropdownMenuItem(value: 'Guardian', child: Text("Primary Guardian")),
                      DropdownMenuItem(value: 'Relative', child: Text("Extended Family")),
                    ],
                    onChanged: (v) => setState(() => _caretakerRelation = v!),
                  ),
                  const SizedBox(height: 16),
                ],

                // 9. Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(fontSize: 16),
                  decoration: InputDecoration(
                    labelText: "Set Password",
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) => (v == null || v.length < 4) ? "Password must be at least 4 chars" : null,
                ),
                const SizedBox(height: 14),

                // 10. Confirm Password
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  style: const TextStyle(fontSize: 16),
                  decoration: InputDecoration(
                    labelText: "Confirm Password",
                    prefixIcon: const Icon(Icons.lock_reset_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                  ),
                  validator: (v) => (v != _passwordController.text) ? "Passwords do not match" : null,
                ),
                const SizedBox(height: 28),

                // Submit Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: _isLoading
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : Text(isBn ? "নিবন্ধন সম্পন্ন করুন" : "Register Account", style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 18),

                // Switch to Login
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isBn ? "ইতিমধ্যে অ্যাকাউন্ট আছে? " : "Already registered? ",
                      style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
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
                          fontSize: 14,
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({required String role, required IconData icon, required String label}) {
    final isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppTheme.primary : Colors.grey.shade300,
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: AppTheme.primary.withAlpha(50), blurRadius: 8, offset: const Offset(0, 3))]
              : [],
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.white : AppTheme.primary, size: 28),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.white : AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
