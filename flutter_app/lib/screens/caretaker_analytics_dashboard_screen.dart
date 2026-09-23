import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/user_model.dart' hide PatientProfile;
import '../services/api_service.dart';
import '../services/caregiver_trend_service.dart';

class CaretakerAnalyticsDashboardScreen extends StatefulWidget {
  final UserSession? session;
  final List<LinkedPatient>? linkedPatients;
  final bool isBengali;

  const CaretakerAnalyticsDashboardScreen({
    super.key,
    this.session,
    this.linkedPatients,
    this.isBengali = false,
  });

  @override
  State<CaretakerAnalyticsDashboardScreen> createState() => _CaretakerAnalyticsDashboardScreenState();
}

class _CaretakerAnalyticsDashboardScreenState extends State<CaretakerAnalyticsDashboardScreen> {
  List<PatientProfile> _roster = [];
  late PatientProfile _selectedPatient;
  List<GameSessionRecord> _sessions = [];
  CognitiveTrajectoryAnalysis? _analysis;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initRosterAndLoad();
  }

  Future<void> _initRosterAndLoad() async {
    List<PatientProfile> roster = [];

    // 1. If passed directly from CaretakerDashboardScreen
    if (widget.linkedPatients != null && widget.linkedPatients!.isNotEmpty) {
      final colors = ['0xFF00796B', '0xFF8E24AA', '0xFFE65100', '0xFF1976D2'];
      roster = widget.linkedPatients!.asMap().entries.map((entry) {
        final i = entry.key;
        final lp = entry.value;
        return PatientProfile(
          id: lp.patientId.isNotEmpty ? lp.patientId : 'demo-patient-001',
          name: lp.fullName,
          age: 72,
          stage: lp.relation.isNotEmpty ? lp.relation : 'Mild Impairment',
          avatarColorHex: colors[i % colors.length],
        );
      }).toList();
    } else if (widget.session != null) {
      // 2. Fetch linked patients from backend
      try {
        final fetchedPatients = await ApiService.getCaretakerPatients(widget.session!.userId);
        if (fetchedPatients.isNotEmpty) {
          final colors = ['0xFF00796B', '0xFF8E24AA', '0xFFE65100', '0xFF1976D2'];
          roster = fetchedPatients.asMap().entries.map((entry) {
            final i = entry.key;
            final lp = entry.value;
            return PatientProfile(
              id: lp.patientId.isNotEmpty ? lp.patientId : 'demo-patient-001',
              name: lp.fullName,
              age: 72,
              stage: lp.relation.isNotEmpty ? lp.relation : 'Mild Impairment',
              avatarColorHex: colors[i % colors.length],
            );
          }).toList();
        }
      } catch (_) {}
    }

    // 3. If no patient linked yet or single assigned patient
    if (roster.isEmpty) {
      roster = [
        const PatientProfile(
          id: 'demo-patient-001',
          name: 'Karthikeyan',
          age: 72,
          stage: 'Mild Impairment',
          avatarColorHex: '0xFF00796B',
        ),
      ];
    }

    if (mounted) {
      setState(() {
        _roster = roster;
        _selectedPatient = roster.first;
      });
      await _loadPatientData(_selectedPatient.id);
    }
  }

  Future<void> _loadPatientData(String patientId) async {
    setState(() {
      _isLoading = true;
    });

    final sessions = await CaregiverTrendService.fetchPatientSessions(patientId);
    final analysis = CaregiverTrendService.analyzeTrajectory(sessions);

    if (mounted) {
      setState(() {
        _sessions = sessions;
        _analysis = analysis;
        _isLoading = false;
      });
    }
  }

  void _onPatientChanged(PatientProfile patient) {
    if (_selectedPatient.id == patient.id) return;
    setState(() {
      _selectedPatient = patient;
    });
    _loadPatientData(patient.id);
  }

  @override
  Widget build(BuildContext context) {
    final isBn = widget.isBengali;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          isBn ? "কেয়ারগিভার বিশ্লেষণ ড্যাশবোর্ড" : "Caregiver Cognitive Analytics",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
        ),
        backgroundColor: const Color(0xFF00695C),
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: "Refresh Analytics",
            onPressed: () => _loadPatientData(_selectedPatient.id),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF00695C)))
            : RefreshIndicator(
                color: const Color(0xFF00695C),
                onRefresh: () => _loadPatientData(_selectedPatient.id),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Multi-Patient Caregiver Switcher
                      _buildPatientRosterSection(isBn),
                      const SizedBox(height: 16),

                      // 2. Cognitive Vitality Index Header & Trend Badge
                      if (_analysis != null) _buildVitalityCard(isBn, _analysis!),
                      const SizedBox(height: 16),

                      // 3. AI Linear Regression Time-Series Clinical Insights
                      if (_analysis != null) _buildAiClinicalInsightsCard(isBn, _analysis!),
                      const SizedBox(height: 16),

                      // 4. Visual 7-Session Cognitive Trajectory Graph
                      if (_analysis != null) _buildTrajectoryChartCard(isBn, _analysis!),
                      const SizedBox(height: 16),

                      // 5. Game-by-Game Skill Breakdown
                      if (_analysis != null) _buildGameBreakdownCard(isBn, _analysis!),
                      const SizedBox(height: 16),

                      // 6. Recent Real Game Sessions Log (Database Synced)
                      _buildRecentSessionsLog(isBn),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  // 1. Patient Roster Switcher (1 Caretaker -> Many Patients)
  Widget _buildPatientRosterSection(bool isBn) {
    if (_roster.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isBn ? "নিয়োজিত রোগী:" : "Assigned Patient Roster:",
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2F1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                isBn
                    ? "${_roster.length} জন রোগী"
                    : "${_roster.length} ${_roster.length == 1 ? 'Elder' : 'Elders'}",
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF004D40)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 86,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _roster.length,
            itemBuilder: (context, index) {
              final patient = _roster[index];
              final isSelected = patient.id == _selectedPatient.id;

              return GestureDetector(
                onTap: () => _onPatientChanged(patient),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : const Color(0xFFECEFF1),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF00695C) : Colors.transparent,
                      width: 2,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFF00695C).withValues(alpha: 0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: Color(int.parse(patient.avatarColorHex)),
                        child: Text(
                          patient.name.isNotEmpty ? patient.name[0].toUpperCase() : 'P',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            patient.name,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                          ),
                          Text(
                            "${patient.age}y • ${patient.stage}",
                            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // 2. Cognitive Vitality Card
  Widget _buildVitalityCard(bool isBn, CognitiveTrajectoryAnalysis analysis) {
    Color trendColor;
    IconData trendIcon;
    String trendLabel;

    switch (analysis.trendDirection) {
      case CognitiveTrendDirection.improving:
        trendColor = const Color(0xFF2E7D32);
        trendIcon = Icons.trending_up_rounded;
        trendLabel = isBn
            ? "উন্নতিশীল (+${analysis.rateOfChangePercentage.abs().toStringAsFixed(1)}%)"
            : "Improving (+${analysis.rateOfChangePercentage.abs().toStringAsFixed(1)}%)";
        break;
      case CognitiveTrendDirection.stable:
        trendColor = const Color(0xFFE65100);
        trendIcon = Icons.trending_flat_rounded;
        trendLabel = isBn ? "স্থিতিশীল (Stable)" : "Stable & Preserved";
        break;
      case CognitiveTrendDirection.declining:
        trendColor = const Color(0xFFC2185B);
        trendIcon = Icons.trending_down_rounded;
        trendLabel = isBn
            ? "ক্লান্তি / অবনতি সতর্কতা"
            : "Decline Warning (-${analysis.rateOfChangePercentage.abs().toStringAsFixed(1)}%)";
        break;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isBn ? "জ্ঞানীয় জীবনীশক্তি সূচক" : "Cognitive Vitality Index",
                    style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        analysis.cognitiveVitalityScore.toInt().toString(),
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00695C),
                        ),
                      ),
                      const Text(
                        " / 100",
                        style: TextStyle(fontSize: 16, color: AppTheme.textSecondary, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: trendColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: trendColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(trendIcon, color: trendColor, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      trendLabel,
                      style: TextStyle(color: trendColor, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricStat(
                label: isBn ? "গড় সঠিকতা" : "Avg Accuracy",
                value: "${analysis.averageAccuracy.toInt()}%",
                icon: Icons.check_circle_outline_rounded,
                color: const Color(0xFF00796B),
              ),
              Container(height: 30, width: 1, color: Colors.grey.shade300),
              _buildMetricStat(
                label: isBn ? "গড় সময়" : "Avg Speed",
                value: "${analysis.averageSpeedSeconds.toStringAsFixed(1)}s",
                icon: Icons.timer_outlined,
                color: const Color(0xFF1565C0),
              ),
              Container(height: 30, width: 1, color: Colors.grey.shade300),
              _buildMetricStat(
                label: isBn ? "মোট সেশন" : "Sessions",
                value: "${analysis.totalSessions}",
                icon: Icons.videogame_asset_outlined,
                color: const Color(0xFFE65100),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricStat({required String label, required String value, required IconData icon, required Color color}) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 4),
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
      ],
    );
  }

  // 3. AI Linear Regression Time-Series Clinical Insights
  Widget _buildAiClinicalInsightsCard(bool isBn, CognitiveTrajectoryAnalysis analysis) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF004D40).withValues(alpha: 0.08),
            const Color(0xFF00796B).withValues(alpha: 0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF00796B).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology_rounded, color: Color(0xFF00695C), size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isBn
                      ? "AI ক্লিনিকাল ট্র্যাজেক্টোরি বিশ্লেষণ (Time-Series)"
                      : "AI Clinical Trajectory Model (Linear Regression)",
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF004D40)),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF00695C),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "Slope: ${analysis.trendSlope >= 0 ? '+' : ''}${analysis.trendSlope.toStringAsFixed(2)}",
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            isBn ? analysis.clinicalInsightBn : analysis.clinicalInsightEn,
            style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary, height: 1.4),
          ),
          if (analysis.hasDeclineAlert) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEF5350)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Color(0xFFC62828), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isBn
                          ? "কেয়ারগিভার নোটিশ: টানা সেশনে ভুল বৃদ্ধি পাওয়ায় ডাক্তারের ফলো-আপ প্রয়োজন হতে পারে।"
                          : "Caregiver Notice: 3 consecutive drops in score. Consider scheduling a routine neurology review.",
                      style: const TextStyle(fontSize: 11, color: Color(0xFFB71C1C), fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 4. Visual 7-Session Trajectory Graph
  Widget _buildTrajectoryChartCard(bool isBn, CognitiveTrajectoryAnalysis analysis) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isBn ? "৭-সেশনের সঠিকতা ও গতিধারা" : "7-Session Trajectory Trend",
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              Row(
                children: [
                  _buildLegendItem("Accuracy", const Color(0xFF00897B)),
                  const SizedBox(width: 10),
                  _buildLegendItem("Speed", const Color(0xFFFFA000)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: CustomPaint(
              size: const Size(double.infinity, 120),
              painter: _TrajectoryGraphPainter(
                accuracyPoints: analysis.weeklyAccuracyPoints,
                speedPoints: analysis.weeklySpeedPoints,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              analysis.weeklyAccuracyPoints.length,
              (i) => Text("S${i + 1}", style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
      ],
    );
  }

  // 5. Game-by-Game Skill Breakdown
  Widget _buildGameBreakdownCard(bool isBn, CognitiveTrajectoryAnalysis analysis) {
    final games = [
      {'title': 'Card Matching', 'domain': isBn ? 'স্থানিক স্মৃতি (Spatial)' : 'Spatial Memory', 'icon': Icons.style_rounded, 'color': const Color(0xFF1E88E5)},
      {'title': 'Pattern Memory', 'domain': isBn ? 'ধারাবাহিক দৃষ্টি (Sequence)' : 'Sequence Memory', 'icon': Icons.grid_view_rounded, 'color': const Color(0xFF00897B)},
      {'title': 'Word Recall', 'domain': isBn ? 'ভাষা ও শব্দ (Semantic)' : 'Semantic Fluency', 'icon': Icons.menu_book_rounded, 'color': const Color(0xFF8E24AA)},
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isBn ? "জ্ঞানীয় খেলাভিত্তিক বিশ্লেষণ" : "Cognitive Domain Breakdown",
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 14),
          ...games.map((g) {
            final title = g['title'] as String;
            final domain = g['domain'] as String;
            final icon = g['icon'] as IconData;
            final color = g['color'] as Color;
            final double acc = analysis.gameBreakdownAccuracy[title] ?? 80.0;
            final int plays = analysis.gameBreakdownPlays[title] ?? 1;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, size: 18, color: color),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "$title ($domain)",
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                        ),
                      ),
                      Text(
                        "${acc.toInt()}% • $plays plays",
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: (acc / 100.0).clamp(0.0, 1.0),
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // 6. Recent Real Game Sessions Log (Fetched from DB)
  Widget _buildRecentSessionsLog(bool isBn) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isBn ? "সাম্প্রতিক গেম সেশন লগ (ডাটাবেজ)" : "Live Game Sessions Log (DB)",
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text("Oracle Synced", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_sessions.isEmpty)
            Text(isBn ? "কোনো সেশন পাওয়া যায়নি।" : "No recorded sessions yet.", style: const TextStyle(color: AppTheme.textSecondary))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _sessions.take(6).length,
              separatorBuilder: (ctx, i) => const Divider(height: 14),
              itemBuilder: (ctx, i) {
                final s = _sessions[i];
                return Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2F1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.videogame_asset_rounded, color: Color(0xFF00695C), size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.gameTitle, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                          Text(
                            "${s.difficultyLevel} Level • ${s.completionTimeSeconds.toInt()}s • ${s.playedAt.hour}:${s.playedAt.minute.toString().padLeft(2, '0')}",
                            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text("${s.score.toInt()}/100", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                        Text("${s.accuracyPercentage.toInt()}% Acc", style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                      ],
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class _TrajectoryGraphPainter extends CustomPainter {
  final List<double> accuracyPoints;
  final List<double> speedPoints;

  _TrajectoryGraphPainter({required this.accuracyPoints, required this.speedPoints});

  @override
  void paint(Canvas canvas, Size size) {
    if (accuracyPoints.isEmpty) return;

    final accPaint = Paint()
      ..color = const Color(0xFF00897B)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final accDotPaint = Paint()..color = const Color(0xFF00695C);

    final speedPaint = Paint()
      ..color = const Color(0xFFFFA000)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final speedDotPaint = Paint()..color = const Color(0xFFE65100);

    final double stepX = size.width / max(1, accuracyPoints.length - 1);

    final accPath = Path();
    final speedPath = Path();

    for (int i = 0; i < accuracyPoints.length; i++) {
      final double x = i * stepX;
      // Accuracy maps 0 - 100 to size.height - 0
      final double normAcc = (accuracyPoints[i] / 100.0).clamp(0.0, 1.0);
      final double accY = size.height - (normAcc * size.height * 0.85) - 8;

      // Speed maps 0 - 60s to size.height - 0
      final double normSpeed = (speedPoints.length > i ? speedPoints[i] / 60.0 : 0.3).clamp(0.0, 1.0);
      final double speedY = size.height - (normSpeed * size.height * 0.85) - 8;

      if (i == 0) {
        accPath.moveTo(x, accY);
        speedPath.moveTo(x, speedY);
      } else {
        accPath.lineTo(x, accY);
        speedPath.lineTo(x, speedY);
      }

      canvas.drawCircle(Offset(x, accY), 4, accDotPaint);
      canvas.drawCircle(Offset(x, speedY), 3, speedDotPaint);
    }

    canvas.drawPath(accPath, accPaint);
    canvas.drawPath(speedPath, speedPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
