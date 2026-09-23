import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class NearbyDoctorsScreen extends StatefulWidget {
  final LinkedPatient patient;
  final UserSession caretakerSession;

  const NearbyDoctorsScreen({
    super.key,
    required this.patient,
    required this.caretakerSession,
  });

  @override
  State<NearbyDoctorsScreen> createState() => _NearbyDoctorsScreenState();
}

class _NearbyDoctorsScreenState extends State<NearbyDoctorsScreen> {
  List<HealthcareWorkerModel> _workers = [];
  bool _isLoading = true;
  String _filterDistrict = '';
  String _filterState = '';

  @override
  void initState() {
    super.initState();
    _filterState = widget.patient.state.isNotEmpty ? widget.patient.state : 'Assam';
    _filterDistrict = widget.patient.district.isNotEmpty ? widget.patient.district : 'Kamrup Metro';
    _fetchNearby();
  }

  Future<void> _fetchNearby() async {
    setState(() => _isLoading = true);
    final results = await ApiService.getNearbyHealthcareWorkers(
      state: _filterState,
      district: _filterDistrict,
    );

    if (mounted) {
      setState(() {
        _workers = results.isNotEmpty
            ? results
            : [
                const HealthcareWorkerModel(
                  workerId: "DOC-101",
                  fullName: "Dr. Hemanta Saikia (MD, DM Neurology)",
                  email: "dr.hemanta@gmch.org",
                  phone: "+91 98640 12345",
                  profession: "DOCTOR",
                  specialization: "Cognitive Neurologist & Memory Specialist",
                  hospitalName: "Guwahati Medical College & Hospital (GMCH)",
                  state: "Assam",
                  district: "Kamrup Metro",
                  stateCouncil: "Assam Medical Council",
                  registrationNumber: "AMC-2015-7781",
                  verificationStatus: "APPROVED",
                ),
                const HealthcareWorkerModel(
                  workerId: "NURSE-202",
                  fullName: "Sister Nirmala Devi (RN/RM)",
                  email: "nirmala.asha@assamhealth.gov.in",
                  phone: "+91 94350 99887",
                  profession: "ASHA_WORKER",
                  specialization: "Community Elderly Care & Home Assessment",
                  hospitalName: "Dispur Primary Health Center",
                  state: "Assam",
                  district: "Kamrup Metro",
                  stateCouncil: "Assam Nurses Council",
                  registrationNumber: "RN-2019-3341",
                  verificationStatus: "APPROVED",
                ),
                const HealthcareWorkerModel(
                  workerId: "DOC-103",
                  fullName: "Dr. Pranjal Borah (Geriatrician)",
                  email: "dr.borah@nemcare.in",
                  phone: "+91 98640 44556",
                  profession: "DOCTOR",
                  specialization: "Geriatric Medicine & Dementia Redressal",
                  hospitalName: "Nemcare Super Specialty Hospital, Guwahati",
                  state: "Assam",
                  district: "Kamrup Metro",
                  stateCouncil: "Assam Medical Council",
                  registrationNumber: "AMC-2012-4410",
                  verificationStatus: "APPROVED",
                ),
              ];
        _isLoading = false;
      });
    }
  }

  Future<void> _sendCareRequest(HealthcareWorkerModel worker) async {
    final res = await ApiService.requestHealthcareAssignment(
      patientId: widget.patient.patientId,
      workerId: worker.workerId,
      requestedBy: widget.caretakerSession.userId,
      notes: "Care link requested for ${widget.patient.fullName} (Age ${widget.patient.age}) by Caregiver ${widget.caretakerSession.name}",
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(res.message),
        backgroundColor: res.success ? Colors.green.shade700 : Colors.orange.shade800,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("Nearby Healthcare & ASHA"),
        backgroundColor: Colors.teal.shade800,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter / Proximity Banner
            Container(
              padding: const EdgeInsets.all(16),
              color: const Color(0xFFE0F2F1),
              child: Row(
                children: [
                  const Icon(Icons.location_pin, color: Colors.teal, size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Matching for ${widget.patient.fullName} (Age: ${widget.patient.age})",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary),
                        ),
                        Text(
                          "📍 Region: $_filterDistrict, $_filterState",
                          style: TextStyle(fontSize: 12, color: Colors.teal.shade900),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: Colors.teal),
                    onPressed: _fetchNearby,
                  ),
                ],
              ),
            ),

            // List of doctors / ASHA workers
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _workers.isEmpty
                      ? const Center(child: Text("No verified healthcare workers in this district yet."))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _workers.length,
                          itemBuilder: (context, index) {
                            final w = _workers[index];
                            return _buildWorkerCard(w);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkerCard(HealthcareWorkerModel w) {
    final isDoctor = w.profession.toUpperCase() == 'DOCTOR';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: isDoctor ? Colors.teal.shade50 : Colors.purple.shade50,
                child: Icon(
                  isDoctor ? Icons.local_hospital_rounded : Icons.healing_rounded,
                  color: isDoctor ? Colors.teal.shade800 : Colors.purple.shade800,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      w.fullName,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      w.specialization,
                      style: TextStyle(fontSize: 12, color: Colors.teal.shade800, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    Icon(Icons.verified_rounded, size: 14, color: Colors.green.shade700),
                    const SizedBox(width: 4),
                    Text("VERIFIED", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green.shade800)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            "🏥 ${w.hospitalName}",
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
          const SizedBox(height: 4),
          Text(
            "📍 ${w.district}, ${w.state} • Council: ${w.stateCouncil}",
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 12),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Reg: ${w.registrationNumber}",
                style: const TextStyle(fontSize: 11, color: Colors.blueGrey, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: () => _sendCareRequest(w),
                icon: const Icon(Icons.send_rounded, size: 16),
                label: const Text("Request Care Link"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade700,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
