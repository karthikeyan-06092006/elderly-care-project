import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import '../models/social_models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class SocialChatScreen extends StatefulWidget {
  final SocialConnection connection;
  final String currentUserId;
  final String currentUserName;
  final bool isParticipant;

  const SocialChatScreen({
    super.key,
    required this.connection,
    required this.currentUserId,
    required this.currentUserName,
    this.isParticipant = true,
  });

  @override
  State<SocialChatScreen> createState() => _SocialChatScreenState();
}

class _SocialChatScreenState extends State<SocialChatScreen> {
  static const MethodChannel _mediaSaveChannel = MethodChannel('com.elderlycare/media_save');
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<SocialMessage> _messages = [];
  bool _isLoading = true;
  Timer? _pollingTimer;
  String? _activeVoiceUrl;
  AudioPlayer? _player;

  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  bool _isSending = false;

  bool get _isMe => widget.isParticipant;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (_) => _loadMessages(silent: true));
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    _player?.dispose();
    if (_isRecording) {
      _recorder.dispose();
    }
    super.dispose();
  }

  Future<void> _loadMessages({bool silent = false}) async {
    if (_isMe) {
      final list = await ApiService.getSocialMessages(widget.connection.connectionId, widget.currentUserId);
      if (!mounted) return;
      final hadMessages = _messages.isNotEmpty;
      setState(() {
        _messages = list;
        _isLoading = false;
      });
      if (!hadMessages && list.isNotEmpty) {
        _scrollToBottom();
      }
    } else {
      setState(() => _isLoading = false);
      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Caregivers can view conversations in read-only mode.'),
            backgroundColor: AppTheme.primary,
          ),
        );
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendText() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();
    await _dispatchMessage(type: 'TEXT', content: text);
  }

  Future<void> _pickAndSendPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1600);
    if (picked == null) return;

    setState(() => _isSending = true);
    final upload = await ApiService.uploadSocialMedia(picked.path);
    if (upload.success && upload.data != null) {
      await _dispatchMessage(type: 'PHOTO', mediaUrl: upload.data);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Photo upload failed: ${upload.message}'), backgroundColor: Colors.red),
        );
      }
      setState(() => _isSending = false);
    }
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      final path = await _recorder.stop();
      setState(() => _isRecording = false);
      if (path != null && path.isNotEmpty) {
        await _sendVoice(path);
      }
      return;
    }

    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission is required for voice messages.'), backgroundColor: Colors.red),
        );
      }
      return;
    }
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path);
    if (mounted) setState(() => _isRecording = true);
  }

  Future<void> _sendVoice(String filePath) async {
    setState(() => _isSending = true);
    final upload = await ApiService.uploadSocialMedia(filePath);
    if (upload.success && upload.data != null) {
      final durationMs = await _estimateDuration(filePath, upload.data!);
      await _dispatchMessage(type: 'VOICE', mediaUrl: upload.data, durationMs: durationMs);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Voice upload failed: ${upload.message}'), backgroundColor: Colors.red),
        );
      }
      setState(() => _isSending = false);
    }
  }

  Future<int> _estimateDuration(String filePath, String mediaUrl) async {
    try {
      final probe = AudioPlayer();
      await probe.setFilePath(filePath);
      final duration = probe.duration;
      await probe.dispose();
      if (duration != null) return duration.inMilliseconds;
    } catch (_) {}
    return 0;
  }

  Future<void> _dispatchMessage({
    required String type,
    String? content,
    String? mediaUrl,
    int? durationMs,
  }) async {
    final result = await ApiService.sendSocialMessage(
      senderId: widget.currentUserId,
      connectionId: widget.connection.connectionId,
      type: type,
      content: content,
      mediaUrl: mediaUrl,
      durationMs: durationMs,
    );
    if (!mounted) return;
    setState(() => _isSending = false);
    if (result.success) {
      if (result.data != null) {
        setState(() => _messages = [..._messages, result.data!]);
        _scrollToBottom();
      } else {
        await _loadMessages(silent: true);
        _scrollToBottom();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _playVoice(SocialMessage msg) async {
    if (_activeVoiceUrl == msg.mediaUrl && _player != null) {
      await _player!.pause();
      if (mounted) setState(() => _activeVoiceUrl = null);
      return;
    }
    try {
      _player?.dispose();
      final player = AudioPlayer();
      _player = player;
      await player.setUrl('${ApiService.mediaBaseUrl}${msg.mediaUrl}');
      setState(() => _activeVoiceUrl = msg.mediaUrl);
      player.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed && mounted) {
          setState(() => _activeVoiceUrl = null);
        }
      });
      await player.play();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not play this voice message.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _formatDuration(int ms) {
    final seconds = (ms / 1000).round();
    final m = (seconds ~/ 60).toString().padLeft(1, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  String _extOf(SocialMessage msg) {
    final url = msg.mediaUrl;
    final dot = url.lastIndexOf('.');
    return dot >= 0 ? url.substring(dot) : '';
  }

  void _showMediaMenu(SocialMessage msg) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                msg.isPhoto ? Icons.download_rounded : Icons.audio_file_rounded,
                color: AppTheme.primary,
              ),
              title: Text(msg.isPhoto ? 'Save photo' : 'Save voice note'),
              subtitle: const Text('Save this to your device'),
              onTap: () {
                Navigator.pop(ctx);
                _saveMediaToDevice(msg);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
              title: const Text('Delete message'),
              subtitle: const Text('Remove this message for everyone'),
              onTap: () {
                Navigator.pop(ctx);
                _deleteMessage(msg);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveMediaToDevice(SocialMessage msg) async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saving...')));
    try {
      final url = '${ApiService.mediaBaseUrl}${msg.mediaUrl}';
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) {
        throw Exception('Download failed (${response.statusCode})');
      }
      final ext = _extOf(msg);
      final mime = msg.isPhoto
          ? (ext == '.png'
              ? 'image/png'
              : ext == '.gif'
                  ? 'image/gif'
                  : ext == '.webp'
                      ? 'image/webp'
                      : 'image/jpeg')
          : (ext == '.mp3'
              ? 'audio/mpeg'
              : ext == '.wav'
                  ? 'audio/wav'
                  : ext == '.ogg'
                      ? 'audio/ogg'
                      : 'audio/mp4');
      final saved = await _mediaSaveChannel.invokeMethod<String>('saveMedia', {
        'bytes': response.bodyBytes,
        'displayName': 'cognitivecare_${DateTime.now().millisecondsSinceEpoch}$ext',
        'mimeType': mime,
        'type': msg.isPhoto ? 'image' : 'audio',
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(saved != null && saved.isNotEmpty
              ? (msg.isPhoto ? 'Saved to Gallery' : 'Saved to device')
              : 'Saved'),
          backgroundColor: AppTheme.primary,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _deleteMessage(SocialMessage msg) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete message?'),
        content: const Text('This removes the message and its media for everyone in this chat.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final result = await ApiService.deleteSocialMessage(
      messageId: msg.messageId,
      connectionId: widget.connection.connectionId,
      userId: widget.currentUserId,
    );
    if (!mounted) return;
    if (result.success) {
      setState(() => _messages.removeWhere((m) => m.messageId == msg.messageId));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message), backgroundColor: AppTheme.primary),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final otherName = widget.connection.otherName(widget.currentUserId);
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(otherName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Text(
              'Connected',
              style: TextStyle(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: Colors.white,
      ),
      body: Column(
        children: [
          if (widget.isParticipant)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              color: const Color(0xFFE8F5E9),
              child: const Text(
                '💬 Text messages, voice notes and photos are allowed.',
                style: TextStyle(fontSize: 12, color: Color(0xFF2E7D32)),
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? _buildEmptyChat()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(14),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          return _buildMessageBubble(_messages[index]);
                        },
                      ),
          ),
          if (_isSending)
            Container(
              padding: const EdgeInsets.all(10),
              alignment: Alignment.center,
              child: const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          if (widget.isParticipant) _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildEmptyChat() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.forum_outlined, size: 70, color: AppTheme.primaryLight),
          const SizedBox(height: 14),
          const Text(
            'No messages yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            'Send a friendly message to ${widget.connection.otherName(widget.currentUserId)}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(SocialMessage msg) {
    final outbound = msg.senderId == widget.currentUserId;
    final bubbleColor = outbound ? AppTheme.primary : Colors.white;
    final textColor = outbound ? Colors.white : AppTheme.textPrimary;

    return Align(
      alignment: outbound ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(outbound ? 18 : 4),
            bottomRight: Radius.circular(outbound ? 4 : 18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (msg.isText) ...[
              Text(
                msg.content,
                style: TextStyle(fontSize: 16, color: textColor, height: 1.3),
              ),
            ],
            if (msg.isPhoto) ...[
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: msg.mediaUrl.isNotEmpty
                        ? Image.network(
                            '${ApiService.mediaBaseUrl}${msg.mediaUrl}',
                            width: 220,
                            height: 220,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              width: 220,
                              height: 160,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.broken_image_outlined, size: 48, color: Colors.grey),
                            ),
                          )
                        : Container(
                            width: 220,
                            height: 160,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.image_outlined, size: 48, color: Colors.grey),
                          ),
                  ),
                  if (widget.isParticipant)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: InkWell(
                        onTap: () => _showMediaMenu(msg),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(70),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.more_vert_rounded, color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                ],
              ),
            ],
            if (msg.isVoice) _buildVoiceBubble(msg, textColor),
            const SizedBox(height: 4),
            Text(
              msg.sentAt,
              style: TextStyle(
                fontSize: 11,
                color: outbound ? Colors.white70 : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceBubble(SocialMessage msg, Color textColor) {
    final isPlaying = _activeVoiceUrl == msg.mediaUrl;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _playVoice(msg),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
              size: 34, color: textColor),
          const SizedBox(width: 8),
          Container(
            height: 4,
            width: 90,
            decoration: BoxDecoration(
              color: textColor.withAlpha(100),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            msg.durationMs > 0 ? _formatDuration(msg.durationMs) : 'Voice',
            style: TextStyle(
              fontSize: 14,
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (widget.isParticipant) ...[
            const SizedBox(width: 4),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _showMediaMenu(msg),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Icon(Icons.more_vert_rounded, size: 18, color: textColor.withAlpha(160)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 10,
        right: 10,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? 8 : 16,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFECEFF1))),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.photo_camera_outlined, color: AppTheme.primary, size: 28),
            onPressed: _isSending ? null : _pickAndSendPhoto,
            tooltip: 'Share photo',
          ),
          IconButton(
            icon: _isRecording
                ? const Icon(Icons.stop_circle_rounded, color: Colors.red, size: 34)
                : const Icon(Icons.mic_none_rounded, color: AppTheme.primary, size: 30),
            onPressed: _isSending ? null : _toggleRecording,
            tooltip: _isRecording ? 'Stop recording' : 'Record voice',
          ),
          if (_isRecording)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text('● Recording...', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          Expanded(
            child: TextField(
              controller: _textController,
              enabled: !_isRecording,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendText(),
              decoration: InputDecoration(
                hintText: 'Type a friendly message...',
                hintStyle: const TextStyle(fontSize: 15),
                filled: true,
                fillColor: const Color(0xFFF1F3F5),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          IconButton.filled(
            onPressed: _isSending || _isRecording ? null : _sendText,
            style: IconButton.styleFrom(backgroundColor: AppTheme.primary),
            icon: const Icon(Icons.send_rounded, color: Colors.white, size: 24),
            tooltip: 'Send',
          ),
        ],
      ),
    );
  }
}