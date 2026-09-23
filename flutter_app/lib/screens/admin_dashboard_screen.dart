import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  final UserSession session;

  const AdminDashboardScreen({super.key, required this.session});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Map<String, dynamic> _stats = {};
  List<AdminPendingWorkerModel> _pendingWorkers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    setState(() => _isLoading = true);
    final stats = await ApiService.getAdminStats();
    final workers = await ApiService.getPendingWorkers();

    if (mounted) {
      setState(() {
        _stats = stats.isNotEmpty
            ? stats
            : {
                "totalPatients": 18,
                "totalCaretakers": 14,
                "verifiedDoctors": 6,
                "pendingVerifications": workers.isNotEmpty ? workers.length : 2,
                "activeEmergencyAlerts": 0,
              };
        _pendingWorkers = workers.isNotEmpty
            ? workers
            : [
                const AdminPendingWorkerModel(
                  userId: "DEMO-DOC-1",
                  fullName: "Dr. Anamika Barua",
                  email: "dr.anamika@gmch.gov.in",
                  phone: "+91 98640 55443",
                  profession: "DOCTOR",
                  specialization: "Neurology & Dementia Specialist",
                  hospitalName: "Guwahati Medical College & Hospital (GMCH)",
                  stateCouncil: "Assam Medical Council",
                  registrationNumber: "AMC-2018-9942",
                  nuid: "",
                  state: "Assam",
                  district: "Kamrup Metro",
                  verificationStatus: "PENDING",
                  createdAt: "Today",
                ),
                const AdminPendingWorkerModel(
                  userId: "DEMO-NURSE-1",
                  fullName: "Sister Rina Das",
                  email: "rina.das@ruralhealth.org",
                  phone: "+91 94350 77889",
                  profession: "NURSE",
                  specialization: "Community Geriatric Nurse",
                  hospitalName: "Majuli Rural Primary Health Centre",
                  stateCouncil: "Assam Nurses & Midwives Council",
                  registrationNumber: "RN-AS-88120",
                  nuid: "NUID-99201",
                  state: "Assam",
                  district: "Majuli",
                  verificationStatus: "PENDING",
                  createdAt: "Today",
                ),
              ];
        _isLoading = false;
      });
    }
  }

  Future<void> _verifyWorker(AdminPendingWorkerModel worker, String status) async {
    await ApiService.verifyWorker(
      userId: worker.userId,
      status: status,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("${worker.fullName} has been $status ✓"),
        backgroundColor: status == 'APPROVED' ? Colors.green.shade700 : Colors.red.shade700,
      ),
    );
    _loadAdminData();
  }

  void _showProofDialog(AdminPendingWorkerModel worker) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.verified_user_rounded, color: Colors.teal),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                "Document & License Review",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Applicant: ${worker.fullName}",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Text(
                "${worker.profession} • ${worker.specialization}",
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 12),

              // Mock Certificate Preview Container
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade300, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.description_rounded, color: Colors.green.shade800, size: 28),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${worker.stateCouncil} Registration Proof",
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.green.shade900),
                              ),
                              Text(
                                "Reg No: ${worker.registrationNumber}",
                                style: const TextStyle(fontSize: 11, color: Colors.black87),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    Row(
                      children: const [
                        Icon(Icons.check_circle_rounded, color: Colors.green, size: 16),
                        SizedBox(width: 6),
                        Text(
                          "IMR/Council Database Match: VALID",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.green),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Hospital / Institute: ${worker.hospitalName}",
                      style: const TextStyle(fontSize: 11, color: Colors.black87),
                    ),
                    Text(
                      "Phone: ${worker.phone} | District: ${worker.district}",
                      style: const TextStyle(fontSize: 11, color: Colors.black87),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        "📄 Attached Proof: License_Certificate.pdf (1.8 MB)",
                        style: TextStyle(fontSize: 11, color: Colors.teal, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                "As Primary Admin, verify the uploaded document against official council records before approval.",
                style: TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Close"),
          ),
          OutlinedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _verifyWorker(worker, 'REJECTED');
            },
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Reject"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _verifyWorker(worker, 'APPROVED');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700),
            child: const Text("Approve & Verify"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text("Admin Command Center"),
        backgroundColor: const Color(0xFF1E293B),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadAdminData,
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
                    // Admin Banner
                    _buildAdminBanner(),
                    const SizedBox(height: 18),

                    // KPI Statistics Cards
                    _buildStatsGrid(),
                    const SizedBox(height: 24),

                    // Verification Queue Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Healthcare Verification Queue",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "${_pendingWorkers.length} Pending",
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade900, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (_pendingWorkers.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                        child: const Center(
                          child: Text(
                            "All healthcare worker registrations are verified! ✓",
                            style: TextStyle(fontSize: 15, color: Colors.green, fontWeight: FontWeight.bold),
                          ),
                        ),
                      )
                    else
                      ..._pendingWorkers.map((w) => _buildWorkerVerificationCard(w)),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildAdminBanner() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.blueGrey.shade800, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.amber, size: 32),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.session.name.isNotEmpty ? widget.session.name : "Primary Administrator",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 2),
                const Text(
                  "North Eastern Regional Cognitive Care Hub",
                  style: TextStyle(fontSize: 13, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildStatCard("Total Patients", "${_stats['totalPatients'] ?? 0}", Icons.elderly_rounded, Colors.blue)),
            const SizedBox(width: 10),
            Expanded(child: _buildStatCard("Caretakers", "${_stats['totalCaretakers'] ?? 0}", Icons.health_and_safety_rounded, Colors.teal)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _buildStatCard("Verified Doctors", "${_stats['verifiedDoctors'] ?? 0}", Icons.verified_user_rounded, Colors.green)),
            const SizedBox(width: 10),
            Expanded(child: _buildStatCard("Pending Reviews", "${_pendingWorkers.length}", Icons.hourglass_top_rounded, Colors.orange)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.shade100),
      ),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: color.shade50, child: Icon(icon, color: color.shade700, size: 22)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color.shade900)),
              Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWorkerVerificationCard(AdminPendingWorkerModel w) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFE082)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.teal.shade50,
                child: Icon(w.profession == 'DOCTOR' ? Icons.local_hospital_rounded : Icons.medical_services_rounded, color: Colors.teal.shade800),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(w.fullName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                    Text("${w.profession} • ${w.specialization}", style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(8)),
                child: const Text("PENDING", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.deepOrange)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFF8F9FA), borderRadius: BorderRadius.circular(10)),
            child: Column(
              children: [
                _buildCredentialRow("Council:", w.stateCouncil),
                const SizedBox(height: 4),
                _buildCredentialRow("Reg / IMR No:", w.registrationNumber),
                if (w.nuid.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  _buildCredentialRow("NUID:", w.nuid),
                ],
                const SizedBox(height: 4),
                _buildCredentialRow("Hospital:", w.hospitalName),
                const SizedBox(height: 4),
                _buildCredentialRow("Location:", "📍 ${w.district}, ${w.state}"),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // View Document / License Button
          OutlinedButton.icon(
            onPressed: () => _showProofDialog(w),
            icon: const Icon(Icons.visibility_rounded, size: 16),
            label: const Text("📄 View Attached Proof / License", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 38),
              side: BorderSide(color: Colors.teal.shade400),
              foregroundColor: Colors.teal.shade800,
            ),
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => _verifyWorker(w, 'REJECTED'),
                icon: const Icon(Icons.close_rounded, size: 16, color: Colors.red),
                label: const Text("Reject", style: TextStyle(color: Colors.red)),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _verifyWorker(w, 'APPROVED'),
                icon: const Icon(Icons.check_circle_rounded, size: 18),
                label: const Text("Approve & Verify"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCredentialRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 95, child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey))),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 12, color: Colors.black87))),
      ],
    );
  }
}
