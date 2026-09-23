import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'caretaker_analytics_dashboard_screen.dart';

class HealthcareWorkerDashboardScreen extends StatefulWidget {
  final UserSession session;

  const HealthcareWorkerDashboardScreen({super.key, required this.session});

  @override
  State<HealthcareWorkerDashboardScreen> createState() => _HealthcareWorkerDashboardScreenState();
}

class _HealthcareWorkerDashboardScreenState extends State<HealthcareWorkerDashboardScreen> {
  late UserSession _session;
  List<AssignedPatientModel> _assignedPatients = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _session = widget.session;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    if (_session.isVerified) {
      final list = await ApiService.getAssignedPatients(_session.userId);
      if (mounted) {
        setState(() {
          _assignedPatients = list.isNotEmpty
              ? list
              : [
                  const AssignedPatientModel(
                    assignmentId: 1,
                    patientId: "DEMO-P1",
                    fullName: "Biren Saikia",
                    age: 74,
                    gender: "Male",
                    phoneNumber: "+91 98640 11223",
                    state: "Assam",
                    district: "Kamrup Metro",
                    status: "ACCEPTED",
                    qrCodeToken: "PATIENT-NER-01",
                    notes: "Early stage memory decline. Recommended daily NER recall game.",
                  ),
                  const AssignedPatientModel(
                    assignmentId: 2,
                    patientId: "DEMO-P2",
                    fullName: "Anjali Devi",
                    age: 68,
                    gender: "Female",
                    phoneNumber: "+91 94350 44556",
                    state: "Assam",
                    district: "Jorhat",
                    status: "PENDING",
                    qrCodeToken: "PATIENT-NER-02",
                    notes: "Request sent by Caregiver Rahul (Son) for neurological assessment.",
                  ),
                ];
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _respondAssignment(AssignedPatientModel patient, String action) async {
    final res = await ApiService.respondHealthcareAssignment(
      assignmentId: patient.assignmentId,
      action: action,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(res.message),
        backgroundColor: action == 'ACCEPT' ? Colors.green.shade700 : Colors.orange.shade800,
      ),
    );
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final isVerified = _session.isVerified;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("Clinical Care Portal"),
        backgroundColor: Colors.teal.shade800,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Doctor Profile Card
                    _buildDoctorProfileCard(),
                    const SizedBox(height: 16),

                    // Verification Banner if Pending
                    if (!isVerified) ...[
                      _buildPendingVerificationBanner(),
                    ] else ...[
                      // KPI Stats
                      _buildKpiRow(),
                      const SizedBox(height: 20),

                      // Assigned & Pending Patients
                      const Text(
                        "Assigned Patients & Care Requests",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                      const SizedBox(height: 10),

                      if (_assignedPatients.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                          child: const Center(
                            child: Text("No patients assigned yet. Patients in your district can request care linkage."),
                          ),
                        )
                      else
                        ..._assignedPatients.map((p) => _buildPatientCard(p)),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildDoctorProfileCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade800, Colors.teal.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.teal.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white,
                child: Icon(Icons.medical_services_rounded, color: Colors.teal.shade800, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _session.name.isNotEmpty ? _session.name : "Healthcare Professional",
                      style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _session.specialization.isNotEmpty ? _session.specialization : "Geriatric Care & Cognitive Health",
                      style: const TextStyle(fontSize: 13, color: Colors.white70),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "📍 ${_session.district.isNotEmpty ? _session.district : 'Kamrup Metro'}, ${_session.state.isNotEmpty ? _session.state : 'Assam'}",
                      style: const TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: Colors.white24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Reg: ${_session.registrationNumber.isNotEmpty ? _session.registrationNumber : 'IMR-NER-2024'}",
                style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _session.isVerified ? Colors.green.shade600 : Colors.amber.shade700,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _session.isVerified ? "VERIFIED PRACTITIONER" : "VERIFICATION PENDING",
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPendingVerificationBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFE082), width: 1.5),
      ),
      child: Column(
        children: [
          const Icon(Icons.hourglass_top_rounded, color: Color(0xFFF57F17), size: 48),
          const SizedBox(height: 12),
          const Text(
            "Account Under Review",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFE65100)),
          ),
          const SizedBox(height: 8),
          const Text(
            "Your professional medical credentials (IMR / State Council Registration) have been submitted to the Hospital Administrator for verification.\n\nOnce approved, you will gain full access to patient cognitive trajectories and neurological analytics.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Color(0xFF5D4037), height: 1.4),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.sync_rounded),
            label: const Text("Check Verification Status"),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF57F17)),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiRow() {
    return Row(
      children: [
        Expanded(
          child: _buildKpiCard(
            title: "Assigned Patients",
            value: "${_assignedPatients.where((p) => p.status == 'ACCEPTED').length}",
            icon: Icons.people_alt_rounded,
            color: Colors.teal,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildKpiCard(
            title: "Pending Requests",
            value: "${_assignedPatients.where((p) => p.status == 'PENDING').length}",
            icon: Icons.pending_actions_rounded,
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildKpiCard(
            title: "Cognitive Risk Flags",
            value: "1",
            icon: Icons.warning_amber_rounded,
            color: Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildKpiCard({required String title, required String value, required IconData icon, required MaterialColor color}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color.shade900)),
          const SizedBox(height: 2),
          Text(title, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildPatientCard(AssignedPatientModel p) {
    final isPending = p.status.toUpperCase() == 'PENDING';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isPending ? Colors.orange.shade200 : const Color(0xFFE0E0E0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: isPending ? Colors.orange.shade100 : Colors.teal.shade50,
                child: Icon(Icons.elderly_rounded, color: isPending ? Colors.orange.shade800 : Colors.teal.shade800),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.fullName,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Age: ${p.age} yrs • ${p.gender} • 📍 ${p.district}, ${p.state}",
                      style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPending ? Colors.orange.shade100 : Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  p.status,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isPending ? Colors.orange.shade900 : Colors.green.shade900,
                  ),
                ),
              ),
            ],
          ),
          if (p.notes.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              "Notes: ${p.notes}",
              style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppTheme.textSecondary),
            ),
          ],
          const SizedBox(height: 12),
          const Divider(),
          if (isPending) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => _respondAssignment(p, 'REJECT'),
                  child: const Text("Decline"),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () => _respondAssignment(p, 'ACCEPT'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                  child: const Text("Accept Patient"),
                ),
              ],
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Phone: ${p.phoneNumber}", style: const TextStyle(fontSize: 12, color: Colors.black87)),
                TextButton.icon(
                  onPressed: () {
                    final linkedPatient = LinkedPatient(
                      patientId: p.patientId,
                      fullName: p.fullName,
                      email: "",
                      phoneNumber: p.phoneNumber,
                      age: p.age,
                      state: p.state,
                      district: p.district,
                      qrCodeToken: p.qrCodeToken,
                      relation: "Doctor Patient",
                      isPrimary: false,
                      linkedDate: "Today",
                    );
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CaretakerAnalyticsDashboardScreen(
                          linkedPatients: [linkedPatient],
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.analytics_rounded, size: 18, color: Colors.teal),
                  label: const Text("View Clinical Analytics", style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
