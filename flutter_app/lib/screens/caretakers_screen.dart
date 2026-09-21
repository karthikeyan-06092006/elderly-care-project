import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../theme/app_theme.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/call_service.dart';

class CaretakersScreen extends StatefulWidget {
  final PatientProfile profile;
  final bool isBengali;

  const CaretakersScreen({
    super.key,
    required this.profile,
    this.isBengali = false,
  });

  @override
  State<CaretakersScreen> createState() => _CaretakersScreenState();
}

class _CaretakersScreenState extends State<CaretakersScreen> {
  List<LinkedCaretaker> _dbCaretakers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCaretakersFromDb();
  }

  Future<void> _fetchCaretakersFromDb() async {
    setState(() => _isLoading = true);
    try {
      final list = await ApiService.getPatientCaretakers(widget.profile.email);
      if (!mounted) return;
      setState(() {
        _dbCaretakers = list;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _makeCall(BuildContext context, String phoneNumber) async {
    await CallService.makeDirectPhoneCall(
      context: context,
      phoneNumber: phoneNumber,
      isBengali: widget.isBengali,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isBn = widget.isBengali;

    // Use DB data if available, otherwise fallback to local profile model
    CaretakerContact primaryCt;
    List<CaretakerContact> otherCts = [];

    if (_dbCaretakers.isNotEmpty) {
      final primaryItem = _dbCaretakers.firstWhere(
        (c) => c.isPrimary,
        orElse: () => _dbCaretakers.first,
      );
      primaryCt = primaryItem.toContact();

      otherCts = _dbCaretakers
          .where((c) => c.caretakerId != primaryItem.caretakerId)
          .map((c) => c.toContact())
          .toList();
    } else {
      primaryCt = widget.profile.primaryCaretaker;
      otherCts = widget.profile.otherCaretakers;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isBn ? "যত্নশীলদের বিবরণ" : "Caretakers",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Refresh Caretakers",
            onPressed: _fetchCaretakersFromDb,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchCaretakersFromDb,
        color: AppTheme.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Center(child: LinearProgressIndicator(minHeight: 3)),
                ),

              // 1. Primary Caretaker Section
              _buildSectionHeader(
                title: isBn ? "⭐ প্রধান যত্নশীল" : "⭐ Primary Caretaker",
                subtitle: isBn
                    ? "জরুরি পরিস্থিতিতে প্রথমে এদের সাথে যোগাযোগ করা হবে"
                    : "First contact for emergency SOS alerts and daily updates",
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2F1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.primary.withAlpha(120), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withAlpha(25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: AppTheme.primary,
                          child: const Icon(
                            Icons.favorite_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primary,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      isBn ? "প্রধান যত্নশীল" : "PRIMARY CARETAKER",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  if (_dbCaretakers.isNotEmpty) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade100,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        "DB LINKED ✓",
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                primaryCt.name,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              Text(
                                primaryCt.relation,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.phone_in_talk_rounded, color: AppTheme.primary, size: 22),
                            const SizedBox(width: 10),
                            Text(
                              primaryCt.phone.isNotEmpty ? primaryCt.phone : "No number",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        if (primaryCt.phone.isNotEmpty)
                          ElevatedButton.icon(
                            onPressed: () => _makeCall(context, primaryCt.phone),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.call, size: 18),
                            label: Text(
                              isBn ? "কল করুন" : "Call",
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // 2. Other Caretakers Section
              if (otherCts.isNotEmpty) ...[
                _buildSectionHeader(
                  title: isBn ? "👥 অন্যান্য যত্নশীলগণ (${otherCts.length})" : "👥 Other Caretakers (${otherCts.length})",
                  subtitle: isBn
                      ? "সহকারী ডাক্তার ও নার্সদের তালিকা"
                      : "Secondary caregivers, family members & attending doctors",
                ),
                const SizedBox(height: 12),
                ...otherCts.map((ct) => Card(
                  elevation: 1.5,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.blue.shade50,
                          child: Icon(
                            Icons.person_outline_rounded,
                            color: Colors.blue.shade700,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ct.name,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                ct.relation,
                                style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                ct.phone,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (ct.phone.isNotEmpty)
                          IconButton.filledTonal(
                            onPressed: () => _makeCall(context, ct.phone),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.green.shade50,
                              foregroundColor: Colors.green.shade800,
                            ),
                            icon: const Icon(Icons.phone_rounded, size: 22),
                            tooltip: "Call ${ct.name}",
                          ),
                      ],
                    ),
                  ),
                )),
                const SizedBox(height: 24),
              ],

              // 3. QR Code for New Caretaker Connection
              _buildSectionHeader(
                title: isBn ? "📲 নতুন যত্নশীল সংযোগ (QR Code)" : "📲 Connect New Caretaker (QR Code)",
                subtitle: isBn
                    ? "নতুন কোনো কেয়ারটেকার যুক্ত হতে এই কোডটি স্ক্যান করবেন"
                    : "Scan this unique code using Caretaker app to link this patient",
              ),
              const SizedBox(height: 12),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppTheme.primary.withAlpha(60), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(10),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: QrImageView(
                          data: widget.profile.qrCodeToken,
                          version: QrVersions.auto,
                          size: 200.0,
                          eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: AppTheme.primary,
                          ),
                          dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.profile.qrCodeToken,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        isBn
                            ? "কেয়ারটেকার তার ফোন থেকে এই কিউআর কোড স্ক্যান করে রোগীর সাথে যুক্ত হতে পারেন।"
                            : "Caretakers can scan this QR code from their app to pair with this profile.",
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({required String title, required String subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
        ),
      ],
    );
  }
}
