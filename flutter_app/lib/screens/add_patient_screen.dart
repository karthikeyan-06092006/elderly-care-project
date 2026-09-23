import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class AddPatientScreen extends StatefulWidget {
  final UserSession session;

  const AddPatientScreen({
    super.key,
    required this.session,
  });

  @override
  State<AddPatientScreen> createState() => _AddPatientScreenState();
}

class _AddPatientScreenState extends State<AddPatientScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  DateTime? _selectedDob;
  int _calculatedAge = 0;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSubmitting = false;

  String _selectedGender = 'Male';
  String _selectedState = 'Assam';
  String _selectedDistrict = 'Kamrup Metro';
  String _selectedRelation = 'Primary Caregiver';

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

  final List<String> _relations = [
    'Primary Caregiver',
    'Son / Daughter',
    'Spouse / Partner',
    'Family Physician',
    'Assisting Nurse',
    'Relative',
    'Neighbor / Friend',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final initialDate = _selectedDob ?? DateTime(now.year - 70, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isAfter(now) ? now : initialDate,
      firstDate: DateTime(1900),
      lastDate: now,
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

  Future<void> _handleAddPatient() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    String? formattedDob;
    if (_selectedDob != null) {
      formattedDob = "${_selectedDob!.year.toString().padLeft(4, '0')}-${_selectedDob!.month.toString().padLeft(2, '0')}-${_selectedDob!.day.toString().padLeft(2, '0')}";
    }

    final regResult = await ApiService.register(
      email: email,
      password: password,
      name: name,
      phone: phone,
      role: 'PATIENT',
      age: _calculatedAge,
      dateOfBirth: formattedDob,
      gender: _selectedGender,
      state: _selectedState,
      district: _selectedDistrict,
    );

    if (!regResult.success || regResult.data == null) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text("❌ ${regResult.message}"),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    final patientSession = regResult.data!;

    String linkMessage = "";
    String linkStatus = "linked";
    if (patientSession.qrCodeToken.isNotEmpty) {
      final linkResult = await ApiService.linkPatient(
        caretakerId: widget.session.userId,
        patientQrToken: patientSession.qrCodeToken,
        relation: _selectedRelation,
        isPrimary: true,
      );
      if (linkResult.success) {
        linkMessage = linkResult.message;
      } else {
        linkStatus = "registration only (link failed: ${linkResult.message})";
      }
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.green, size: 28),
            SizedBox(width: 8),
            Text("Patient Registered!"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Patient account for $name has been created successfully.",
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primary.withAlpha(80)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoRow("Email", email),
                  const SizedBox(height: 6),
                  _infoRow("Phone", phone.isEmpty ? "-" : phone),
                  const SizedBox(height: 6),
                  _infoRow("Password", password),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "The patient can now log in using their email or phone number and this password.\n\n$linkMessage",
              style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
            ),
            Text(
              "Link status: $linkStatus",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: linkStatus == "linked" ? Colors.green.shade700 : Colors.orange.shade800,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              navigator.pop();
              navigator.pop(true);
            },
            child: const Text("Done"),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$label: ",
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primary),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final districts = _stateDistricts[_selectedState] ?? ['General District'];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Add Patient",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: const Color(0xFF00695C),
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2F1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF80CBC4)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: Color(0xFF00695C), size: 22),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Register a new patient account. The patient can log in using their email or phone number plus the password you set.",
                          style: TextStyle(fontSize: 13, color: Color(0xFF004D40), height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: "Patient Full Name",
                    hintText: "e.g. Ramesh Chandra",
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? "Enter patient full name" : null,
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: "Phone Number",
                    hintText: "9876543210",
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: (v) {
                    final phone = v?.trim() ?? '';
                    if (phone.isEmpty) return "Enter patient phone number";
                    if (phone.replaceAll(RegExp(r'\D'), '').length < 10) return "Enter a valid phone number";
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: "Email Address",
                    hintText: "patient@example.com",
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return "Enter email address";
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim())) return "Enter valid email";
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
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

                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
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
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Patient Details (Optional)",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF00695C)),
                      ),
                      const SizedBox(height: 10),
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
                                      "Enter Date of Birth",
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      _selectedDob != null
                                          ? "${_selectedDob!.day.toString().padLeft(2, '0')}/${_selectedDob!.month.toString().padLeft(2, '0')}/${_selectedDob!.year}"
                                          : "Tap to select Date of Birth",
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_calculatedAge > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryLight,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    "Age: $_calculatedAge yrs",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
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
                      const SizedBox(height: 12),
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

                DropdownButtonFormField<String>(
                  initialValue: _selectedRelation,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: "Your Relationship with Patient",
                    prefixIcon: Icon(Icons.family_restroom_rounded),
                  ),
                  items: _relations.map((r) => DropdownMenuItem(
                    value: r,
                    child: Text(r, style: const TextStyle(fontSize: 14)),
                  )).toList(),
                  onChanged: (v) => setState(() => _selectedRelation = v!),
                ),
                const SizedBox(height: 10),

                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2F1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF80CBC4)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.star_rounded, color: Color(0xFF00695C), size: 22),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "This is a new patient account, so you will be set as their Primary Caretaker automatically.",
                          style: TextStyle(fontSize: 13, color: Color(0xFF004D40), height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _handleAddPatient,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00796B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.person_add_alt_1_rounded),
                  label: Text(
                    _isSubmitting ? "Registering Patient..." : "Register Patient",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}