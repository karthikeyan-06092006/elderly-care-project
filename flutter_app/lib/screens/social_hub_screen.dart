import 'package:flutter/material.dart';
import '../models/social_models.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'social_chat_screen.dart';

class SocialHubScreen extends StatefulWidget {
  final PatientProfile profile;
  final bool isBengali;

  const SocialHubScreen({
    super.key,
    required this.profile,
    this.isBengali = false,
  });

  @override
  State<SocialHubScreen> createState() => _SocialHubScreenState();
}

class _SocialHubScreenState extends State<SocialHubScreen> {
  List<DiscoverablePatient> _discoverable = [];
  List<SocialConnection> _connections = [];
  bool _isLoading = true;
  String? _errorMessage;

  String get _myId => widget.profile.userId;

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
        ApiService.getSocialConnections(_myId),
        ApiService.getDiscoverablePatients(_myId),
      ]);
      if (!mounted) return;
      setState(() {
        _connections = results[0] as List<SocialConnection>;
        _discoverable = results[1] as List<DiscoverablePatient>;
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

  List<SocialConnection> get _incomingRequests {
    return _connections
        .where((c) => c.isPending && c.receiverPatientId == _myId && !c.patientApproved)
        .toList();
  }

  List<SocialConnection> get _activeConnections {
    return _connections.where((c) => c.isConnected || c.isWaitingForCaretaker).toList();
  }

  Future<void> _sendRequest(DiscoverablePatient patient) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.group_add_rounded, color: AppTheme.primary, size: 26),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Connect with ${patient.fullName}',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add a short message:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              maxLines: 3,
              maxLength: 200,
              decoration: const InputDecoration(
                hintText: 'e.g. Hello! Would you like to chat with me?',
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Your request becomes active only after your friend accepts it AND a caregiver approves it.',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            child: const Text('Send Request'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final result = await ApiService.sendConnectionRequest(
      requesterPatientId: _myId,
      receiverPatientId: patient.userId,
      requestMessage: controller.text.trim(),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.success ? '✅ ${result.message}' : '❌ ${result.message}'),
        backgroundColor: result.success ? Colors.green.shade700 : Colors.red.shade700,
        duration: const Duration(seconds: 4),
      ),
    );
    if (result.success) {
      _loadAll();
    }
  }

  Future<void> _respondToRequest(SocialConnection conn, bool accept) async {
    final result = await ApiService.respondToConnection(
      connectionId: conn.connectionId,
      patientId: _myId,
      accept: accept,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.success ? '✅ ${result.message}' : '❌ ${result.message}'),
        backgroundColor: result.success ? Colors.green.shade700 : Colors.red.shade700,
        duration: const Duration(seconds: 4),
      ),
    );
    _loadAll();
  }

  void _openChat(SocialConnection conn) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SocialChatScreen(
          connection: conn,
          currentUserId: _myId,
          currentUserName: widget.profile.name,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Social Hub'),
          bottom: const TabBar(
            labelColor: AppTheme.primary,
            unselectedLabelColor: AppTheme.textSecondary,
            indicatorColor: AppTheme.primary,
            indicatorWeight: 3,
            tabs: [
              Tab(icon: Icon(Icons.explore_outlined), text: 'Discover'),
              Tab(icon: Icon(Icons.notifications_outlined), text: 'Requests'),
              Tab(icon: Icon(Icons.groups_outlined), text: 'Connections'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Refresh',
              onPressed: _loadAll,
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? _buildErrorState()
                : TabBarView(
                    children: [
                      _buildDiscoverTab(),
                      _buildRequestsTab(),
                      _buildConnectionsTab(),
                    ],
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
            Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14)),
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

  Widget _buildDiscoverTab() {
    if (_discoverable.isEmpty) {
      return _buildEmptyState(
        icon: Icons.groups_outlined,
        title: 'No patients to discover',
        subtitle: 'All available patients have already received a request from you.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _discoverable.length,
      itemBuilder: (context, index) {
        final p = _discoverable[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: const Color(0xFFE0F2F1),
                  child: Text(
                    p.fullName.isNotEmpty ? p.fullName[0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primary),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.fullName,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        p.email,
                        style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _sendRequest(p),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                  label: const Text('Request'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRequestsTab() {
    if (_incomingRequests.isEmpty) {
      return _buildEmptyState(
        icon: Icons.notifications_outlined,
        title: 'No incoming requests',
        subtitle: 'When another patient sends you a request, you can accept or reject it here.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _incomingRequests.length,
      itemBuilder: (context, index) {
        final conn = _incomingRequests[index];
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
                      radius: 24,
                      backgroundColor: const Color(0xFFE0F2F1),
                      child: Text(
                        conn.requesterName.isNotEmpty ? conn.requesterName[0].toUpperCase() : '?',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        conn.requesterName,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                    ),
                  ],
                ),
                if (conn.requestMessage.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    '"${conn.requestMessage}"',
                    style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary, fontStyle: FontStyle.italic),
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _respondToRequest(conn, false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade700,
                          side: BorderSide(color: Colors.red.shade300, width: 1.5),
                        ),
                        icon: const Icon(Icons.close_rounded, size: 18),
                        label: const Text('Reject'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _respondToRequest(conn, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                        ),
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: const Text('Accept'),
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

  Widget _buildConnectionsTab() {
    if (_activeConnections.isEmpty) {
      return _buildEmptyState(
        icon: Icons.groups_outlined,
        title: 'No connections yet',
        subtitle: 'Connections become active when both the patient and a caregiver approve.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _activeConnections.length,
      itemBuilder: (context, index) {
        final conn = _activeConnections[index];
        final other = conn.otherName(_myId);
        Widget trailing;
        if (conn.isWaitingForCaretaker) {
          trailing = Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.amber.shade300),
            ),
            child: const Text(
              'Awaiting caregiver approval',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFB26A00)),
            ),
          );
        } else {
          trailing = IconButton(
            icon: const Icon(Icons.chat_bubble_rounded, color: AppTheme.primary, size: 26),
            tooltip: 'Open chat',
            onPressed: () => _openChat(conn),
          );
        }
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFFE0F2F1),
                  child: Text(
                    other.isNotEmpty ? other[0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primary),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        other,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        conn.isConnected ? '● Connected' : 'Pending approval',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: conn.isConnected ? Colors.green.shade700 : Colors.amber.shade800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        conn.connectedAt.isNotEmpty ? 'Since ${conn.connectedAt}' : 'Requested ${conn.requestedAt}',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                trailing,
              ],
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