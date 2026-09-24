import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../services/voice_assistant_service.dart';

class VoiceAssistantScreen extends StatefulWidget {
  final bool isBengali;
  final String? userName;

  const VoiceAssistantScreen({super.key, this.isBengali = false, this.userName});

  @override
  State<VoiceAssistantScreen> createState() => _VoiceAssistantScreenState();
}

class _VoiceAssistantScreenState extends State<VoiceAssistantScreen>
    with SingleTickerProviderStateMixin {
  static const MethodChannel _voiceSetupChannel =
      MethodChannel('com.elderlycare/voice_setup');
  final VoiceAssistantService _service = VoiceAssistantService();
  late final AnimationController _pulse;
  late bool _isBn;
  String _liveTranscript = '';
  String _lastReply = '';
  bool _micOn = false;
  bool _speaking = false;
  bool _thinking = false;
  bool _ready = false;
  bool _sosSent = false;
  final List<String> _recentChat = [];

  @override
  void initState() {
    super.initState();
    _isBn = widget.isBengali;
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
      lowerBound: 0.6,
      upperBound: 1.15,
    )..repeat(reverse: true);
    _initialize();
  }

  Future<void> _initialize() async {
    final bn = widget.isBengali;
    _service.onStateChanged = (s) {
      if (!mounted) return;
      setState(() {
        _micOn = s == AssistantState.listening;
        _speaking = s == AssistantState.speaking;
        _thinking = s == AssistantState.thinking;
      });
      if (s == AssistantState.speaking && _speaking) _pulse.repeat(reverse: true);
      if (s == AssistantState.idle) _pulse.value = 0.6;
    };
    _service.onTranscript = (text, isFinal) {
      if (!mounted) return;
      if (text.trim().isNotEmpty) _liveTranscript = text;
      if (isFinal && text.trim().isNotEmpty) _liveTranscript = text;
      setState(() {});
    };
    _service.onReply = (reply, intent) {
      if (!mounted) return;
      _lastReply = reply;
      _recentChat.insert(0, reply);
      if (_recentChat.length > 5) _recentChat.removeLast();
      if (intent == 'sos' || intent == 'emergency' || intent == '_empty') {
        _sosSent = true;
      }
      if (reply.trim().isNotEmpty) _liveTranscript = '';
      setState(() {});
    };
    if (widget.userName != null) _service.setUserName(widget.userName!);

    final ok = await _service.ensureInitialized(language: bn ? 'bn' : 'en');
    if (!mounted) return;
    setState(() => _ready = ok);
    await _service.greet();
  }

  @override
  void dispose() {
    _pulse.dispose();
    _service.dispose();
    super.dispose();
  }

  Future<void> _switchLanguage() async {
    final nextBn = !_isBn;
    setState(() {
      _isBn = nextBn;
      _liveTranscript = '';
      _lastReply = '';
    });
    await _service.ensureInitialized(language: nextBn ? 'bn' : 'en');
    await _service.greet();
  }

  Future<void> _toggleMic() async {
    if (_micOn) {
      await _service.stopListening();
    } else {
      await _service.startListening();
    }
    setState(() {});
  }

  Future<void> _sendSos() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_isBn ? 'জরুরি সাহায্য' : 'Emergency SOS'),
        content: Text(_isBn
            ? 'আপনি কি নিশ্চিত যে আপনি জরুরি সাহায্য চাচ্ছেন? যত্নশীলকে অবিলম্বে জানানো হবে।'
            : 'Are you sure you want to alert your caregiver immediately?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(_isBn ? 'না' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: const Text('SOS'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      if (!mounted) return;
      setState(() => _sosSent = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isBn
              ? 'আপনার যত্নশীলকে জরুরি বার্তা পাঠানো হয়েছে।'
              : 'Emergency alert sent to your caregiver.'),
          backgroundColor: Colors.red.shade700,
        ),
      );
      if (_service.engine.language == 'bn') {
        await _service.speakText('আমি আপনার যত্নশীলকে জানিয়ে দিচ্ছি। আপনি শান্ত থাকুন।');
      } else {
        await _service.speakText('I am alerting your caregiver now. Please stay calm.');
      }
    }
  }

  Future<void> _openVoiceSetup() async {
    final isBn = _isBn;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isBn ? 'ভয়েস সেটআপ' : 'Voice setup',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                isBn
                    ? 'কথা বলতে ও শুনতে ফোনে নিচের ডেটা একবার ইনস্টল করুন।'
                    : 'Install these once on your phone so the assistant can speak and listen.',
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.record_voice_over, color: AppTheme.primary),
                title: Text(isBn ? 'কথা বলার ভয়েস (টেক্সট-টু-স্পিচ)' : 'Speaking voice (text-to-speech)'),
                subtitle: Text(isBn ? 'ইংরেজি বা বাংলা ভয়েস ডাউনলোড করুন' : 'Download an English or Bangla voice'),
                trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
                onTap: () {
                  Navigator.pop(ctx);
                  _launchVoiceSetting('tts');
                },
              ),
              ListTile(
                leading: const Icon(Icons.hearing, color: AppTheme.primary),
                title: Text(isBn ? 'অফলাইন ভয়েস শোনা (রিকগনিশন)' : 'Offline voice recognition'),
                subtitle: Text(isBn ? 'ইংরেজি অফলাইন প্যাক ডাউনলোড করুন' : 'Download the English offline pack'),
                trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
                onTap: () {
                  Navigator.pop(ctx);
                  _launchVoiceSetting('recognition');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchVoiceSetting(String setting) async {
    try {
      await _voiceSetupChannel.invokeMethod('openSettings', {'setting': setting});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isBn
                ? 'সেটিংস খোলা যায়নি, ফোনের সেটিংস থেকে খুলুন'
                : 'Could not open settings. Open it from your phone Settings.',
          ),
        ),
      );
    }
  }

  String get _statusText {
    if (!_ready) {
      return _isBn
          ? 'ভয়েস সহায়ক চালু করা যাচ্ছে না'
          : 'Voice assistant unavailable';
    }
    if (_micOn) return _isBn ? 'শুনছি... কথা বলুন' : 'Listening... speak now';
    if (_thinking) {
      return _isBn ? 'ভাবছি... (১ম উত্তর একটু সময় নিতে পারে)' : 'Thinking... (first answer can take a moment)';
    }
    if (_speaking) return _isBn ? 'বলছি...' : 'Speaking...';
    return _isBn ? 'মাইক্রোফোনে চাপ দিন' : 'Tap the microphone';
  }

  @override
  Widget build(BuildContext context) {
    final isBn = _isBn;

    return Scaffold(
      appBar: AppBar(
        title: Text(isBn ? 'ভয়েস সহকারী' : 'Voice Assistant'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ActionChip(
              avatar: Icon(
                Icons.translate_rounded,
                size: 16,
                color: isBn ? Colors.white : AppTheme.primary,
              ),
              label: Text(
                isBn ? "বাংলা (BN)" : "English (EN)",
                style: TextStyle(
                  color: isBn ? Colors.white : AppTheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              backgroundColor: isBn ? const Color(0xFF00796B) : Colors.white,
              side: const BorderSide(color: AppTheme.primary, width: 1.5),
              onPressed: _switchLanguage,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              const Spacer(flex: 1),
              _statusChip(),
              const SizedBox(height: 32),

              GestureDetector(
                onTap: _ready ? _toggleMic : null,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primaryLight,
                    border: Border.all(
                      color: (_micOn || _speaking) ? AppTheme.primary : Colors.transparent,
                      width: 3,
                    ),
                  ),
                  child: ScaleTransition(
                    scale: (_micOn || _speaking) ? _pulse : const AlwaysStoppedAnimation(1.0),
                    child: CircleAvatar(
                      radius: 80,
                      backgroundColor: (_micOn || _speaking) ? AppTheme.primary : Colors.white,
                      child: Icon(
                        _micOn ? Icons.mic : Icons.mic_none,
                        size: 72,
                        color: (_micOn || _speaking) ? Colors.white : AppTheme.primary,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _statusText,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: (_micOn || _speaking) ? AppTheme.primary : AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 12),

              const Spacer(flex: 1),

              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                child: _liveTranscript.trim().isNotEmpty
                    ? Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFCFD8DC)),
                        ),
                        child: Text(
                          '"${_liveTranscript.trim()}"',
                          style: const TextStyle(fontSize: 17, color: AppTheme.textPrimary),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),

              if (_lastReply.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.record_voice_over, color: AppTheme.primary, size: 26),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _lastReply,
                          style: const TextStyle(
                            fontSize: 17,
                            color: AppTheme.textPrimary,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (_sosSent) ...[
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.emergency, color: Colors.red, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      isBn ? 'যত্নশীলকে জানানো হয়েছে' : 'Caregiver has been alerted',
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],

              const Spacer(flex: 1),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    iconSize: 28,
                    tooltip: isBn ? 'ভয়েস সেটআপ' : 'Voice setup',
                    onPressed: _openVoiceSetup,
                    icon: const Icon(Icons.settings, color: AppTheme.textSecondary),
                  ),
                  IconButton(
                    iconSize: 28,
                    tooltip: isBn ? 'পুনরায় শুনুন' : 'Repeat reply',
                    onPressed: _lastReply.isEmpty
                        ? null
                        : () => _service.speakText(_lastReply),
                    icon: const Icon(Icons.replay, color: AppTheme.primary),
                  ),
                  ElevatedButton.icon(
                    onPressed: _sendSos,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                    ),
                    icon: const Icon(Icons.emergency_share),
                    label: Text(isBn ? 'জরুরি' : 'SOS'),
                  ),
                  IconButton(
                    iconSize: 28,
                    tooltip: isBn ? 'হোমে যান' : 'Close',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusChip() {
    final color = !_ready
        ? AppTheme.textSecondary
        : (_micOn || _speaking)
            ? AppTheme.primary
            : AppTheme.textSecondary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_micOn || _speaking)
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
          ),
        Text(
          isBnHint(_isBn),
          style: TextStyle(color: color, fontSize: 14),
        ),
      ],
    );
  }

  String isBnHint(bool bn) {
    if (!_ready) return bn ? 'চেষ্টা করা হচ্ছে...' : 'Initializing...';
    if (_micOn) return bn ? 'আমি শুনছি' : 'Listening';
    if (_thinking) return bn ? 'ভাবছি' : 'Thinking';
    return bn ? 'ব্যবহারের জন্য প্রস্তুত' : 'Ready';
  }
}