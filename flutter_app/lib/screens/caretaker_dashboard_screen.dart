import 'dart:async';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/call_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import 'landing_screen.dart';
import 'qr_scanner_screen.dart';
import 'caretaker_analytics_dashboard_screen.dart';
import 'nearby_doctors_screen.dart';
import 'caretaker_social_screen.dart';
import 'voice_assistant_screen.dart';
import 'reminders_screen.dart';
import '../services/profile_storage_service.dart';

class CaretakerDashboardScreen extends StatefulWidget {
  final UserSession session;

  const CaretakerDashboardScreen({
    super.key,
    required this.session,
  });

  @override
  State<CaretakerDashboardScreen> createState() => _CaretakerDashboardScreenState();
}

class _CaretakerDashboardScreenState extends State<CaretakerDashboardScreen> {
  List<LinkedPatient> _patients = [];
  List<ActiveEmergencyAlert> _activeAlerts = [];
  int _pendingSocialApprovals = 0;
  Timer? _emergencyPollingTimer;
  int _lastKnownAlertCount = 0;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchLinkedPatients();
    _fetchActiveAlerts();
    _fetchPendingSocialApprovals();
    NotificationService.registerDeviceToken(widget.session.email);
    // Poll for active emergency alerts every 4 seconds
    _emergencyPollingTimer = Timer.periodic(const Duration(seconds: 4), (_) => _fetchActiveAlerts());
  }

  @override
  void dispose() {
    _emergencyPollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchActiveAlerts() async {
    try {
      final alerts = await ApiService.getActiveEmergencyAlerts(widget.session.userId);
      if (!mounted) return;

      if (alerts.length > _lastKnownAlertCount && alerts.isNotEmpty) {
        final newest = alerts.first;
        NotificationService.showEmergencyNotification(
          title: "🚨 EMERGENCY SOS: ${newest.patientName}",
          body: "Patient ${newest.patientName} has triggered an emergency alert! Tap to respond.",
        );
      }
      _lastKnownAlertCount = alerts.length;

      setState(() {
        _activeAlerts = alerts;
      });
    } catch (_) {}
  }

  Future<void> _fetchPendingSocialApprovals() async {
    try {
      final list = await ApiService.getPendingCaretakerApprovals(widget.session.userId);
      if (!mounted) return;
      setState(() {
        _pendingSocialApprovals = list.length;
      });
    } catch (_) {}
  }

  Future<void> _fetchLinkedPatients() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await ApiService.getCaretakerPatients(widget.session.userId);
      if (!mounted) return;
      setState(() {
        _patients = list;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = "Failed to load patients: $e";
        _isLoading = false;
      });
    }
  }

  Future<void> _openQrScanner() async {
    final scannedCode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
    );

    if (scannedCode != null && scannedCode.isNotEmpty) {
      if (!mounted) return;
      _showConfirmLinkDialog(scannedCode);
    }
  }

  void _showConfirmLinkDialog(String scannedToken) {
    String selectedRelation = "Primary Caregiver";
    bool isPrimary = true;
    bool isSubmitting = false;

    final relations = [
      "Primary Caregiver",
      "Son / Daughter",
      "Spouse / Partner",
      "Family Physician",
      "Assisting Nurse",
      "Relative",
      "Neighbor / Friend",
    ];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.person_add_alt_1_rounded, color: AppTheme.primary, size: 28),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Link Patient Account",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Scanned Patient QR Token:",
                    style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.primary.withAlpha(100)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.qr_code, color: AppTheme.primary, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            scannedToken,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppTheme.primary,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Relation Selector
                  const Text(
                    "Your Relationship with Patient:",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedRelation,
                        isExpanded: true,
                        items: relations.map((r) => DropdownMenuItem(
                          value: r,
                          child: Text(r, style: const TextStyle(fontSize: 14)),
                        )).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => selectedRelation = val);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Primary Caregiver checkbox
                  CheckboxListTile(
                    value: isPrimary,
                    contentPadding: EdgeInsets.zero,
                    activeColor: AppTheme.primary,
                    title: const Text(
                      "Set as Primary Caretaker",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      "First responder for emergency SOS alerts",
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    onChanged: (val) {
                      setDialogState(() => isPrimary = val ?? false);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: isSubmitting ? null : () async {
                  setDialogState(() => isSubmitting = true);
                  final messenger = ScaffoldMessenger.of(context);
                  final navigator = Navigator.of(ctx);

                  final result = await ApiService.linkPatient(
                    caretakerId: widget.session.userId,
                    patientQrToken: scannedToken,
                    relation: selectedRelation,
                    isPrimary: isPrimary,
                  );

                  navigator.pop();

                  if (result.success) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text("✅ ${result.message}"),
                        backgroundColor: Colors.green.shade700,
                        duration: const Duration(seconds: 4),
                      ),
                    );
                    _fetchLinkedPatients();
                  } else {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text("❌ ${result.message}"),
                        backgroundColor: Colors.red.shade700,
                        duration: const Duration(seconds: 4),
                      ),
                    );
                  }
                },
                child: isSubmitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text("Confirm & Link"),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _makeCall(String phoneNumber) async {
    await CallService.makeDirectPhoneCall(
      context: context,
      phoneNumber: phoneNumber,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          "Caregiver Portal",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: const Color(0xFF00695C),
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.mic_rounded),
            tooltip: "Voice Assistant",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => VoiceAssistantScreen(
                    isBengali: false,
                    userName: widget.session.name,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: "Refresh Patients",
            onPressed: _fetchLinkedPatients,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Logout",
            onPressed: () async {
              await ProfileStorageService.clearSession();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LandingScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      // 1. Bottom Right Camera Action Button
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openQrScanner,
        backgroundColor: const Color(0xFF00796B),
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.qr_code_scanner_rounded, size: 26),
        label: const Text(
          "Scan Patient QR",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchLinkedPatients,
        color: AppTheme.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ACTIVE EMERGENCY SOS ALERTS (Real-Time Broadcast)
              if (_activeAlerts.isNotEmpty) ...[
                ..._activeAlerts.map((alert) => _buildEmergencyAlertCard(alert)),
                const SizedBox(height: 16),
              ],

              // Caregiver Profile Card
              _buildCaregiverHeaderCard(),
              const SizedBox(height: 14),

              // 🧠 Cognitive AI Analytics & Reports Banner
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CaretakerAnalyticsDashboardScreen(
                        session: widget.session,
                        linkedPatients: _patients,
                        isBengali: false,
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00695C), Color(0xFF00897B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF004D40).withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Cognitive AI Analytics",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              "Time-Series Trajectory & Decline Alerts",
                              style: TextStyle(
                                color: Color(0xFFB2DFDB),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // 👥 Social Connection Approvals Banner
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CaretakerSocialScreen(session: widget.session),
                    ),
                  ).then((_) => _fetchPendingSocialApprovals());
                },
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00897B), Color(0xFF26A69A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF004D40).withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.groups_rounded, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Social Approvals",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              "Accept or reject patient connection requests",
                              style: TextStyle(
                                color: Color(0xFFB2DFDB),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_pendingSocialApprovals > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade600,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            '$_pendingSocialApprovals pending',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else
                        const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Section Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.elderly_rounded, color: Color(0xFF00695C), size: 24),
                      const SizedBox(width: 8),
                      Text(
                        "Assigned Patients (${_patients.length})",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF263238),
                        ),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: _openQrScanner,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text("Link New"),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Patients List / Loading / Empty State
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_errorMessage != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(30.0),
                    child: Column(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 40),
                        const SizedBox(height: 10),
                        Text(_errorMessage!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _fetchLinkedPatients,
                          child: const Text("Retry"),
                        ),
                      ],
                    ),
                  ),
                )
              else if (_patients.isEmpty)
                _buildEmptyPatientsCard()
              else
                ..._patients.map((p) => _buildPatientCard(p)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCaregiverHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2F1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.medical_services_rounded,
              color: Color(0xFF00796B),
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Dr. / Caregiver ${widget.session.name.isNotEmpty ? widget.session.name : ''}",
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF263238),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.session.email,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF607D8B)),
                ),
                if (widget.session.phone.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    widget.session.phone,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF00796B)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPatientsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          const Icon(Icons.qr_code_scanner_rounded, size: 60, color: Color(0xFF00796B)),
          const SizedBox(height: 16),
          const Text(
            "No Patients Linked Yet",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF263238)),
          ),
          const SizedBox(height: 8),
          const Text(
            "To pair with a dementia patient, ask the patient or their family to show their QR Code (under Profile -> Caretakers) and scan it using the button below.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Color(0xFF607D8B), height: 1.4),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _openQrScanner,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00796B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.camera_alt_rounded),
            label: const Text("Scan Patient QR Code"),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientCard(LinkedPatient patient) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: const Color(0xFFE0F2F1),
                  child: const Icon(
                    Icons.elderly_rounded,
                    color: Color(0xFF00796B),
                    size: 30,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              patient.fullName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF263238),
                              ),
                            ),
                          ),
                          if (patient.isPrimary) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade100,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.amber.shade700, width: 1),
                              ),
                              child: Text(
                                "PRIMARY",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber.shade900,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00796B).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              patient.relation,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF00796B),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Age: ${patient.age} yrs • 📍 ${patient.district}",
                            style: const TextStyle(fontSize: 12, color: Color(0xFF607D8B), fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              children: [
                const Icon(Icons.phone_outlined, size: 18, color: Color(0xFF607D8B)),
                const SizedBox(width: 8),
                Text(
                  patient.phoneNumber.isNotEmpty ? patient.phoneNumber : "No phone",
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF37474F)),
                ),
                const Spacer(),
                if (patient.phoneNumber.isNotEmpty)
                  ElevatedButton.icon(
                    onPressed: () => _makeCall(patient.phoneNumber),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.call, size: 16),
                    label: const Text("Call"),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.qr_code, size: 16, color: Color(0xFF90A4AE)),
                const SizedBox(width: 6),
                Text(
                  "QR: ${patient.qrCodeToken}",
                  style: const TextStyle(fontSize: 12, color: Color(0xFF78909C)),
                ),
                const Spacer(),
                if (patient.linkedDate.isNotEmpty)
                  Text(
                    "Linked: ${patient.linkedDate}",
                    style: const TextStyle(fontSize: 11, color: Color(0xFF90A4AE)),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RemindersScreen(
                        patientId: patient.patientId,
                        patientName: patient.fullName,
                        createdBy: widget.session.userId,
                        isCaretakerViewing: true,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.alarm_on_rounded, size: 18, color: Colors.white),
                label: const Text(
                  "⏰ Set Routine Alarms (Medicine, Food, Sleep)",
                  style: TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D9488),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => NearbyDoctorsScreen(
                        patient: patient,
                        caretakerSession: widget.session,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.medical_services_outlined, size: 16, color: Color(0xFF00796B)),
                label: const Text("Find Local Doctors & ASHA Workers Near Patient", style: TextStyle(fontSize: 12, color: Color(0xFF00796B), fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF00796B)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyAlertCard(ActiveEmergencyAlert alert) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE), // Urgent soft red
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.shade700, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withAlpha(50),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.warning_rounded, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "🚨 ACTIVE EMERGENCY SOS",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      "Patient: ${alert.patientName}",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: const Text(
                  "URGENT",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (alert.primaryCaretakerName.isNotEmpty) ...[
            Text(
              "Primary caregiver being dialed: ${alert.primaryCaretakerName} (${alert.primaryCaretakerPhone})",
              style: TextStyle(
                fontSize: 13,
                color: Colors.red.shade900,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              // 1. Direct Call Patient
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _makeCall(alert.patientPhone),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.call, size: 18),
                  label: const Text(
                    "Call Patient",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // 2. Mark as Responded / Resolve
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final success = await ApiService.resolveEmergencyAlert(alert.alertId);
                    if (success) {
                      _fetchActiveAlerts();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("✅ Emergency marked as responded & resolved"),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green.shade800,
                    side: BorderSide(color: Colors.green.shade700, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text(
                    "Responded",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
