import 'package:flutter/material.dart';
import '../models/social_models.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'social_chat_screen.dart';

class CaretakerSocialScreen extends StatefulWidget {
  final UserSession session;

  const CaretakerSocialScreen({
    super.key,
    required this.session,
  });

  @override
  State<CaretakerSocialScreen> createState() => _CaretakerSocialScreenState();
}

class _CaretakerSocialScreenState extends State<CaretakerSocialScreen> {
  List<SocialConnection> _pending = [];
  List<SocialConnection> _connected = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final results = await Future.wait([
        ApiService.getPendingCaretakerApprovals(widget.session.userId),
        ApiService.getConnectedForCaretaker(widget.session.userId),
      ]);
      if (!mounted) return;
      setState(() {
        _pending = results[0];
        _connected = results[1];
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _decide(SocialConnection conn, bool approve) async {
    final result = await ApiService.caretakerDecision(
      connectionId: conn.connectionId,
      caretakerId: widget.session.userId,
      approve: approve,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.success ? '✅ ${result.message}' : '❌ ${result.message}'),
        backgroundColor: result.success ? Colors.green.shade700 : Colors.red.shade700,
        duration: const Duration(seconds: 5),
      ),
    );
    _loadAll();
  }

  void _viewChat(SocialConnection conn) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SocialChatScreen(
          connection: conn,
          currentUserId: widget.session.userId,
          currentUserName: widget.session.name,
          isParticipant: false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Social Connections'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Refresh',
              onPressed: _loadAll,
            ),
          ],
          bottom: TabBar(
            labelColor: AppTheme.primary,
            unselectedLabelColor: AppTheme.textSecondary,
            indicatorColor: AppTheme.primary,
            indicatorWeight: 3,
            tabs: [
              Tab(
                icon: const Icon(Icons.fact_check_outlined),
                text: 'Pending (${_pending.length})',
              ),
              Tab(
                icon: const Icon(Icons.forum_outlined),
                text: 'Active (${_connected.length})',
              ),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? _buildErrorState()
                : TabBarView(
                    children: [_buildPendingTab(), _buildActiveTab()],
                  ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(_errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: _loadAll,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingTab() {
    if (_pending.isEmpty) {
      return _buildEmptyState(
        icon: Icons.fact_check_outlined,
        title: 'No pending approvals',
        subtitle: 'When a patient in your care receives a social connection request, it will appear here.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pending.length,
      itemBuilder: (context, index) {
        final conn = _pending[index];
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
                      radius: 22,
                      backgroundColor: const Color(0xFFE0F2F1),
                      child: Text(
                        (conn.requesterName.isNotEmpty ? conn.requesterName[0] : '?').toUpperCase(),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primary),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        conn.requesterName,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'NEEDS APPROVAL',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFB26A00)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.arrow_downward_rounded, size: 16, color: AppTheme.textSecondary),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Wants to connect with ${conn.receiverName}',
                        style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                      ),
                    ),
                  ],
                ),
                if (conn.requestMessage.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    '"${conn.requestMessage}"',
                    style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontStyle: FontStyle.italic),
                  ),
                ],
                if (conn.patientApproved) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, size: 16, color: Colors.green),
                      const SizedBox(width: 6),
                      Text(
                        '${conn.receiverName} already accepted',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.green.shade700),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _decide(conn, false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade700,
                          side: BorderSide(color: Colors.red.shade300, width: 1.5),
                        ),
                        icon: const Icon(Icons.close_rounded),
                        label: const Text('Reject'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _decide(conn, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                        ),
                        icon: const Icon(Icons.check_rounded),
                        label: Text(conn.patientApproved ? 'Approve & Connect' : 'Approve'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActiveTab() {
    if (_connected.isEmpty) {
      return _buildEmptyState(
        icon: Icons.forum_outlined,
        title: 'No active conversations',
        subtitle: 'Approved connections between patients will be listed here so you can review them.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _connected.length,
      itemBuilder: (context, index) {
        final conn = _connected[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          color: Colors.white,
          child: ListTile(
            contentPadding: const EdgeInsets.all(10),
            leading: CircleAvatar(
              radius: 22,
              backgroundColor: const Color(0xFFE0F2F1),
              child: Text(
                (conn.requesterName.isNotEmpty ? conn.requesterName[0] : '?').toUpperCase(),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primary),
              ),
            ),
            title: Text(
              '${conn.requesterName} ⇄ ${conn.receiverName}',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            subtitle: Text(
              conn.connectedAt.isNotEmpty ? 'Connected since ${conn.connectedAt}' : 'Connected',
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.visibility_rounded, color: AppTheme.primary),
              tooltip: 'View conversation',
              onPressed: () => _viewChat(conn),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState({required IconData icon, required String title, required String subtitle}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 70, color: AppTheme.primaryLight),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}