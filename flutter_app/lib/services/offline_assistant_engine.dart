import 'dart:math';

class AssistantReply {
  final String reply;
  final String intent;
  final String? action;

  const AssistantReply({
    required this.reply,
    required this.intent,
    this.action,
  });
}

class ConversationTurn {
  final String user;
  final String assistant;
  final String intent;
  ConversationTurn(this.user, this.assistant, this.intent);
}

class OfflineAssistantEngine {
  String language = 'en';
  String userName = '';
  final List<ConversationTurn> memory = [];
  bool _awaitingYesNo = false;
  String _lastTopicIntent = '';

  static const int _maxMemory = 12;

  void setLanguage(String lang) => language = (lang == 'bn') ? 'bn' : 'en';
  void setUserName(String name) {
    if (name.trim().isNotEmpty) userName = name.trim();
  }

  String get welcome {
    final h = DateTime.now().hour;
    final bnGreet = h < 12 ? 'শুভ সকাল' : h < 17 ? 'শুভ অপরাহ্ন' : 'শুভ সন্ধ্যা';
    final enGreet = h < 12 ? 'Good morning' : h < 17 ? 'Good afternoon' : 'Good evening';
    if (language == 'bn') {
      return userName.isNotEmpty
          ? '$bnGreet $userName! আমি আপনার সঙ্গী। আপনি কেমন আছেন?'
          : '$bnGreet! আমি আপনার সঙ্গী। আপনি কেমন আছেন?';
    }
    return userName.isNotEmpty
        ? '$enGreet $userName! I am your companion. How are you feeling today?'
        : '$enGreet! I am your companion. How are you feeling today?';
  }

  AssistantReply reply(String userText) {
    final text = userText.trim();
    if (text.isEmpty) {
      return _make(
          language == 'bn' ? 'আপনি কী বলতে চান? আমি শুনছি।' : 'What would you like to say? I am listening.');
    }

    final intent = _matchIntent(text);
    if (_awaitingYesNo && (intent == 'yes' || intent == 'no')) {
      _awaitingYesNo = false;
      final result = _handleYesNo(intent == 'yes');
      _remember(text, result.reply, result.intent);
      return result;
    }

    final repeated = memory
        .any((t) => t.user.trim().toLowerCase() == text.toLowerCase());

    AssistantReply result;
    if (intent != 'default' && intent != 'yes' && intent != 'no') {
      result = _respond(intent, text, repeated: repeated);
      _awaitingYesNo = _opensFollowUp(intent);
      if (_awaitingYesNo) _lastTopicIntent = intent;
    } else {
      result = _contextualFallback(text);
      _awaitingYesNo = false;
    }
    _remember(text, result.reply, result.intent);
    return result;
  }

  AssistantReply _make(String reply, {String? intent, String? action}) {
    return AssistantReply(reply: reply, intent: intent ?? 'default', action: action);
  }

  void _remember(String user, String assistant, String intent) {
    memory.add(ConversationTurn(user, assistant, intent));
    if (memory.length > _maxMemory) memory.removeAt(0);
  }

  bool _opensFollowUp(String intent) {
    return intent == 'water' || intent == 'game' || intent == 'rest' || intent == 'food';
  }

  AssistantReply _handleYesNo(bool yes) {
    final bn = language == 'bn';
    switch (_lastTopicIntent) {
      case 'water':
        return _make(_pickVariants('yw',
            bn
                ? ['চমৎকার! জল খেলে শরীর আর মন দুটোই ভালো থাকে।', 'দারুণ! জল খাওয়া ভালো, এতে শরীর সতেজ লাগে।']
                : [
                    'Wonderful! Drinking water keeps both your body and mind well.',
                    'Great! Water is good for you, it will refresh your body.'
                  ]));
      case 'food':
        if (yes) {
          return _make(_pickVariants('yf_yes',
              bn
                  ? ['খুব ভালো! পুষ্টিকর খাবার মস্তিষ্কের জন্য দারুণ।', 'চমৎকার! ভালো খাবার আপনাকে শক্তিশালী রাখবে।']
                  : [
                      'Very good! Nutritious food is great for your mind.',
                      'Awesome! Good food keeps you strong and healthy.'
                    ]));
        }
        return _make(_pickVariants('yf_no',
            bn
                ? ['ঠিক আছে, খিদে লাগলে যত্নশীলকে বলবেন। আমি পাশেই আছি।', 'কোনো সমস্যা নেই, পরে খেতে চাইলেই বলুন।']
                : [
                    'That is okay. Tell your caregiver when you feel hungry. I am right here.',
                    'No problem at all. Just tell me when you want to eat later.'
                  ]));
      case 'game':
        if (yes) {
          final content = _pickVariants('yg_yes',
              bn
                  ? ['দারুণ! চলুন একটি মজার মেমোরি গেম খেলি, এটি মস্তিষ্ক সতেজ রাখে।', 'চমৎকার! এখনই মজার একটি গেম খেলি।']
                  : [
                      'Wonderful! Let us play a fun memory game to keep your mind sharp.',
                      'Great! Let us play a fun game right now.'
                    ]);
          return _make(content, intent: 'game', action: 'open_game');
        }
        return _make(_pickVariants('yg_no',
            bn
                ? ['ঠিক আছে, কখন ইচ্ছে করবে খেলবেন। আপাতত আরাম করুন।', 'দুশ্চিন্তা নেই, খেলতে মন চাইলে বলুন।']
                : [
                    'That is okay. Play whenever you feel like it. Rest for now.',
                    'No worries. Just say the word when you want to play.'
                  ]));
      case 'rest':
        return _make(_pickVariants('yr',
            bn
                ? ['খুব ভালো। শান্তিতে বিশ্রাম নিন, আমি পাশে আছি।', 'ঠিক আছে, চোখ বন্ধ করে একটু বিশ্রাম নিন।']
                : [
                    'Very good. Rest peacefully, I am right here.',
                    'Alright, close your eyes and rest for a little while.'
                  ]));
    }
    return _make(_pickVariants('yq',
        bn
            ? ['আমি আপনার সঙ্গে আছি। আপনি আরও যা বলতে চান শুনতে চাই।', 'ঠিক আছে, আমি এখানেই আছি। আর কী বলতে চান?']
            : [
                'I am here with you. I would love to hear more from you.',
                'Okay, I am right here. What else would you like to share?'
              ]));
  }

  String _matchIntent(String text) {
    final lower = text.toLowerCase();
    final Map<String, int> scores = {};
    int maxScore = 0;
    String best = 'default';
    for (final entry in _intents.entries) {
      int s = 0;
      for (final kw in entry.value['q']!) {
        if (_contains(lower, kw)) {
          s += kw.length > 4 ? 3 : 2;
        }
      }
      for (final kw in entry.value['w']!) {
        if (lower.split(' ').map((w) => w.trim()).any((w) => w == kw)) {
          s += 1;
        }
      }
      if (s > maxScore) {
        maxScore = s;
        best = entry.key;
      }
      if (s > 0) scores[entry.key] = s;
    }
    return best;
  }

  bool _contains(String text, String kw) {
    if (text.isEmpty || kw.isEmpty) return false;
    return text.contains(kw);
  }

  final Map<String, int> _lastVariantIdx = {};

  String _pickVariants(String key, List<String> variants) {
    if (variants.isEmpty) return '';
    final resolved = variants.map((v) => v.replaceAll('{name}', userName)).toList();
    final target = '$key:$language';
    int idx = _lastVariantIdx[target] ?? Random().nextInt(resolved.length);
    if (resolved.length > 1) {
      idx = (idx + 1 + Random().nextInt(resolved.length - 1)) % resolved.length;
    }
    _lastVariantIdx[target] = idx;
    return resolved[idx];
  }

  AssistantReply _respond(String intent, String text, {bool repeated = false}) {
    final bn = language == 'bn';
    String content;
    String? action;
    switch (intent) {
      case 'greeting':
        content = _pickVariants('greet',
            bn
                ? [
                    'নমস্কার{name}! আজ আপনি কেমন আছেন?',
                    'হ্যালো{name}! আপনার দিন কেমন যাচ্ছে?',
                    'আসসালামু আলাইকুম{name}! আপনার সঙ্গে কথা বলে ভালো লাগলো।'
                  ]
                : [
                    'Hello{name}! How are you feeling today?',
                    'Hi there{name}! How is your day going?',
                    'Hello{name}! I am so glad you came to talk. How have you been?'
                  ]);
        break;
      case 'how_are_you':
        content = _pickVariants('how',
            bn
                ? [
                    'আমি ভালোই আছি, আপনার যত্ন নিতে পেরে আনন্দিত। আর আপনি কেমন অনুভব করছেন?',
                    'আমার কথা বাদ দিন, আমি জানতে চাই — আপনি কেমন আছেন?',
                    'আমি বেশ ভালো আছি, জিজ্ঞেস করার জন্য ধন্যবাদ। আপনি কেমন আছেন?'
                  ]
                : [
                    'I am doing well, and I am glad to take care of you. How do you feel right now?',
                    'Never mind me — I want to know how YOU are.',
                    'I am doing great, thanks for asking. What about you?'
                  ]);
        break;
      case 'your_name':
        content = _pickVariants('yn',
            bn
                ? [
                    'আমি আপনার চিন্তার সঙ্গী। আপনি চাইলে একটি নাম দিয়ে ডাকতে পারেন।',
                    'আমাকে আপনার পছন্দমতো নামে ডাকুন। আমি আপনার সঙ্গের জন্য এখানে আছি।'
                  ]
                : [
                    'I am your caring companion. You can call me whatever you like.',
                    'Call me whatever name feels right to you. I am here for your company.'
                  ]);
        break;
      case 'my_name':
        final name = _extractName(text);
        if (name != null) {
          setUserName(name);
          content = _pickVariants('myn',
              bn
                  ? ['খুব আনন্দ হলো জানতে পেরে, $name!', '$name দারুণ নাম! আপনার সঙ্গে কথা বলে ভালো লাগে।']
                  : ['I am so glad to know you, $name!', '$name is a lovely name! I enjoy our talks.']);
        } else {
          content = _pickVariants('myn0',
              bn
                  ? ['আপনার নামটি আবার বলুন তো?', 'আমি নামটি ঠিক বুঝতে পারিনি, আবার বলবেন?']
                  : ['Could you tell me your name again?', 'I did not quite catch that. Say your name again?']);
        }
        break;
      case 'medicine':
        content = _pickVariants('med',
            bn
                ? [
                    'ওষুধ সময়মতো খাওয়া খুব জরুরি। সময় হয়ে থাকলে যত্নশীলকে বলেন বা অ্যাপের রিমাইন্ডার দেখুন।',
                    'আপনার ওষুধের কথা মনে করিয়ে দেওয়ার জন্যই আমি আছি। এবারের ডোজ হয়েছিল কিনা দেখে নিন।'
                  ]
                : [
                    'Taking medicine on time is very important. If it is time for your pills, tell your caregiver or check the app reminder.',
                    'I am here to remind you about your pills. Did you take your last dose?'
                  ]);
        break;
      case 'reminder':
        content = _pickVariants('rem',
            bn
                ? [
                    'আমি আপনার ওষুধ ও খাবারের সময় মনে করিয়ে দেওয়ার জন্য আছি, ভয় পাবেন না।',
                    'চিন্তা নেই, অ্যাপটি আপনার সময়গুলো মনে করিয়ে দেবে। আমি পাশে আছি।'
                  ]
                : [
                    'I am here to remind you of your medicines and meal times, so do not worry.',
                    'No worries — the app reminds you of your schedule, and I am by your side.'
                  ]);
        break;
      case 'water':
        content = _pickVariants('water',
            bn
                ? ['একটু জল খেতে চান? শরীর সুস্থ রাখতে দিনে কয়েকবার জল খাওয়া দরকার।', 'শরীরকে সতেজ রাখতে খানিক জল খাওয়া ভালো। ইচ্ছে করে?']
                : [
                    'Would you like a glass of water? Drinking regularly keeps you healthy.',
                    'A little water keeps you fresh. Would you like some?'
                  ]);
        break;
      case 'food':
        content = _pickVariants('food',
            bn
                ? ['পুষ্টিকর খাবার আপনাকে শক্তিশালী রাখে। কিছু খেয়েছেন?', 'খাবারের কথা মনে পড়লে যত্নশীলকে বলুন, ওরা সাহায্য করবেন। কিছু ভারী খেয়েছেন?']
                : [
                    'Nutritious food keeps you strong. Have you eaten something?',
                    'Tell your caregiver when you feel hungry and they will help. Did you have a proper meal?'
                  ]);
        break;
      case 'rest':
        content = _pickVariants('rest',
            bn
                ? ['বিশ্রাম নেওয়া খুব ভালো। একটু চোখ বন্ধ করে শুয়ে থাকুন, আমি পাশে আছি।', 'শরীরের জন্য বিশ্রাম জরুরি। এখনই একটু শুয়ে পড়ুন।']
                : [
                    'Rest is good for you. Close your eyes for a little while, I am right here.',
                    'Rest matters a lot. Lie down and rest now.'
                  ]);
        break;
      case 'game':
        final c = _pickVariants('game',
            bn
                ? ['মস্তিষ্ক সতেজ রাখতে মেমোরি গেম খুব ভালো। খেলতে চান?', 'একটি মজার গেম খেললে মন ভালো থাকবে। শুরু করবেন?']
                : [
                    'Memory games are wonderful for keeping your mind sharp. Would you like to play one?',
                    'A fun game will cheer you up. Shall we start?'
                  ]);
        content = c;
        action = 'open_game';
        break;
      case 'time':
        content = _pickVariants('time',
            bn
                ? ['${_bengaliTime()} ', '${_bengaliTime()} বাইরে আবহাওয়া ভালো কিনা জানতে চান?']
                : ['${_englishTime()} ', '${_englishTime()} Would you like to know about the weather too?']);
        break;
      case 'doctor':
        content = _pickVariants('doc',
            bn
                ? ['ডাক্তার দেখাতে ভয় পাবেন না। যত্নশীলকে বললে অ্যাপয়েন্টমেন্ট ঠিক করে দেবেন, আমি আপনার সঙ্গে থাকব।', 'চেকআপ জরুরি হতে পারে। যত্নশীলকে ডাক্তারের কথা বলুন, আমি পাশে আছি।']
                : [
                    'Do not worry about seeing the doctor. Tell your caregiver and they will fix an appointment. I will be with you.',
                    'A check up might be important. Mention it to your caregiver, I am right here.'
                  ]);
        break;
      case 'emergency':
        final c = _pickVariants('em',
            bn
                ? ['চিন্তা করবেন না, আমি এখনই আপনার যত্নশীলকে জানাচ্ছি। শান্ত থাকুন।', 'আর কোনো চিন্তা নেই, সাহায্যের ব্যবস্থা করছি। শান্ত থাকুন।']
                : [
                    'Do not worry, I am alerting your caregiver right away. Please stay calm.',
                    'Do not panic, I am arranging help for you right now. Stay calm.'
                  ]);
        content = c;
        action = 'sos';
        break;
      case 'family':
        content = _pickVariants('fam',
            bn
                ? ['আপনার পরিবার আপনাকে খুব ভালোবাসে। চাইলে আমরা একসঙ্গে তাদের কথা স্মরণ করতে পারি।', 'পরিবারের ভালোবাসা আপনার শক্তি। তাদের কথা ভাবলে মন ভালো থাকে, তাই না?']
                : [
                    'Your family loves you very much. Whenever you want, we can remember them together.',
                    'Family love is your strength. Thinking of them always warms the heart, right?'
                  ]);
        break;
      case 'mood':
        content = _pickVariants('mood',
            bn
                ? ['আপনার অনুভূতি আমি বুঝতে পারি। কান্না বা নীরবতা স্বাভাবিক, আমি আপনার সঙ্গে আছি।', 'মন খারাপ হলে পরিচিত কাউকে সঙ্গে নিয়ে কথা বলেন। আমি সবসময় আছি।']
                : [
                    'I understand how you feel. It is okay to feel sad sometimes. I am here with you.',
                    'When you feel low, talk to someone you trust. I am always here for you.'
                  ]);
        break;
      case 'weather':
        content = _pickVariants('wea',
            bn
                ? ['আবহাওয়া যাই হোক, জানালার পাশে বসে বিশ্রাম নিলে মন ভালো থাকে।', 'বৃষ্টি বা রোদ — এটা আপনার মনকেও আজ ভালো রাখতে দিন।']
                : [
                    'Whatever the weather, sitting by the window for a while calms the mind.',
                    'Rain or shine — let the weather not spoil your good mood today.'
                  ]);
        break;
      case 'music':
        content = _pickVariants('music',
            bn
                ? ['পুরনো গান শুনলে মন ভালো হয়ে যায়। আপনার পছন্দের কোনো গানের কথা মনে পড়ে?', 'সুর শুনলে মন সতেজ থাকে। একটা গান মনে করিয়ে দিবে?']
                : [
                    'Listening to old songs makes the heart happy. Can you remember a song you love?',
                    'Music refreshes the mood. Can you hum a tune you like?'
                  ]);
        break;
      case 'thank':
        content = _pickVariants('thx',
            bn
                ? ['আপনাকে ধন্যবাদ! আপনার সাথে কথা বলে আমারও ভালো লাগে।', 'এ আপনাকে ধন্যবাদ! আমি সবসময় এখানে থাকব।']
                : [
                    'Thank you! I enjoy our conversation too.',
                    'You are very welcome! I will always be here for you.'
                  ]);
        break;
      case 'farewell':
        content = _pickVariants('bye',
            bn
                ? ['বিদায়! বিশ্রাম নিন, প্রয়োজন হলে আমি পাশে আছি।', 'আবার আসবেন। বিশ্রামে থাকুন, আমি এখানেই আছি।']
                : [
                    'Goodbye! Rest well. I am always here if you need me.',
                    'Come back again. Rest well, I will be right here.'
                  ]);
        break;
      case 'tell_more':
        content = _pickVariants('more',
            bn
                ? ['আমি মন দিয়ে শুনছি। যা ভাবছেন, তা আমাকে বলুন।', 'বলুন, আমি আপনার জন্য কান পেতে বসে আছি।']
                : [
                    'I am listening carefully. Tell me whatever is on your mind.',
                    'Go on, I am all ears for you.'
                  ]);
        break;
      default:
        return _contextualFallback(text);
    }

    if (repeated && intent != 'greeting' && intent != 'emergency') {
      final prefix = _pickVariants('rep_$intent',
          bn
              ? ['আগে তো আপনি এ কথা বলেছিলেন। ', 'এটা তো আগেও বলেছেন। ']
              : ['You mentioned that before. ', 'I recall you told me that. ']);
      content = '$prefix$content';
    }
    return _make(content, intent: intent, action: action);
  }

  AssistantReply _contextualFallback(String text) {
    final bn = language == 'bn';
    if (memory.isNotEmpty) {
      final last = memory.last;
      if (last.intent == 'greeting' || last.intent == 'how_are_you') {
        return _make(_pickVariants('cf_greet',
            bn
                ? ['আপনার কথা শুনে ভালো লাগলো। আর কিছু জানতে চান?', 'আমি মন দিয়ে শুনছি, আপনি কেমন আছেন?']
                : [
                    'I am glad to hear from you. Would you like to know anything else?',
                    'I am listening closely. How are you today?'
                  ]));
      }
      if (_opensFollowUp(last.intent)) {
        return _make(_pickVariants('cf_topic',
            bn
                ? ['কথাটা মনে রাখলাম। আপনি আরও বলুন।', 'ঠিক আছে, যা ইচ্ছে বলুন, আমি শুনছি।']
                : ['Got it, please go on.', 'Alright, say whatever you wish, I am listening.']));
      }
    }
    return _make(_pickVariants('cf',
        bn
            ? [
                'আমি আপনার কথা শুনছি। আপনি কেমন বোধ করছেন আমাকে বলুন।',
                'হ্যাঁ, আমি বুঝতে পারছি। আপনি আরও বলুন।',
                'সময়ের কথা ভাববেন না, আমি ধৈর্য ধরে শুনছি।',
                'আপনার মনের কথা জানাতে ভয় পাবেন না।'
              ]
            : [
                'I am listening. Tell me how you feel.',
                'Yes, I understand. Please go on.',
                'Take your time, I am patiently listening.',
                'Do not hesitate to share what is on your mind.'
              ]));
  }

  String _englishTime() {
    final now = DateTime.now();
    final h = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final m = now.minute.toString().padLeft(2, '0');
    final mer = now.hour >= 12 ? 'PM' : 'AM';
    return 'It is $h:$m $mer now. Take a gentle moment to relax.';
  }

  String _bengaliTime() {
    final now = DateTime.now();
    final h = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final m = now.minute.toString().padLeft(2, '0');
    return 'এখন সময় $h:$m। শান্তভাবে কিছুক্ষণ বিশ্রাম নিন।';
  }

  String? _extractName(String text) {
    final patterns = [
      RegExp(r'i am ([a-z ]+)', caseSensitive: false),
      RegExp(r"i'm ([a-z ]+)", caseSensitive: false),
      RegExp(r'my name is ([a-z ]+)', caseSensitive: false),
      RegExp(r'call me ([a-z ]+)', caseSensitive: false),
    ];
    for (final p in patterns) {
      final m = p.firstMatch(text);
      if (m != null) {
        final name = m.group(1)!.trim().split(RegExp(r'\s+')).first;
        if (name.isNotEmpty) return _capitalize(name);
      }
    }
    return null;
  }

  String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  Map<String, Map<String, List<String>>> get _intents => {
        'greeting': {
          'q': ['hello', 'hi', 'hey', 'good morning', 'good afternoon', 'good evening',
                'নমস্কার', 'হ্যালো', 'নমশেখা', 'আসসালামু', 'হাই', 'নান্না'],
          'w': ['hi', 'hello', 'hey']
        },
        'how_are_you': {
          'q': ['how are you', 'how do you feel', 'কেমন আছেন', 'কেমন আছ', 'ভালো আছেন', 'কেমন আছো'],
          'w': []
        },
        'your_name': {
          'q': ['what is your name', 'your name', 'who are you', 'তোমার নাম', 'আপনার নাম', 'কে তুমি', 'কে আপনি'],
          'w': ['name']
        },
        'my_name': {
          'q': ['my name is', 'i am', "i'm", 'call me', 'আমার নাম'],
          'w': []
        },
        'medicine': {
          'q': ['medicine', 'medication', 'pills', 'tablet', 'pheese', 'ওষুধ', 'ঔষধ', 'ট্যাবলেট', 'পিল', 'ইনসুলিন'],
          'w': ['medicine', 'pills', 'pill']
        },
        'reminder': {
          'q': ['remind', 'reminder', 'alarm', 'schedule', 'স্মরণ', 'রিমাইন্ডার', 'মনে করিয়ে', 'অ্যালার্ম'],
          'w': []
        },
        'water': {
          'q': ['water', 'drink water', 'thirsty', 'জল', 'পানি', 'তেষ্টা'],
          'w': ['water']
        },
        'food': {
          'q': ['food', 'hungry', 'eat', 'lunch', 'dinner', 'breakfast', 'খাবার', 'খিদে', 'দুপুর', 'রাতের খাবার', 'নাস্তা'],
          'w': []
        },
        'rest': {
          'q': ['sleep', 'rest', 'tired', 'nap', 'ঘুম', 'বিশ্রাম', 'ক্লান্ত', 'শুতে'],
          'w': []
        },
        'game': {
          'q': ['game', 'play', 'puzzle', 'memory game', 'activity', 'খেলা', 'গেম', 'ধাঁধা', 'মেমোরি'],
          'w': ['game', 'play']
        },
        'time': {
          'q': ['what time', 'what day', "today's date", 'current time', 'এখন সময়', 'কয়টা', 'কোন দিন', 'তারিখ'],
          'w': ['time']
        },
        'doctor': {
          'q': ['doctor', 'appointment', 'hospital', 'clinic', 'checkup', 'ডাক্তার', 'চিকিৎসক', 'হাসপাতাল', 'অ্যাপয়েন্টমেন্ট'],
          'w': []
        },
        'emergency': {
          'q': ['emergency', 'help me', 'sos', 'ambulance', 'chest pain', 'fall down', 'fallen', 'hurt',
                'জরুরি', 'সাহায্য', 'ব্যথা', 'পড়ে গেছি', 'এম্বুলেন্স', 'বুক ব্যথা'],
          'w': ['help']
        },
        'family': {
          'q': ['family', 'my son', 'my daughter', 'grandchildren', 'wife', 'husband',
                'পরিবার', 'ছেলে', 'মেয়ে', 'নাতি', 'স্ত্রী', 'স্বামী'],
          'w': []
        },
        'mood': {
          'q': ['sad', 'lonely', 'scared', 'confused', 'anxious', 'crying', 'depressed',
                'মন খারাপ', 'একা', 'ভয়', 'বিভ্রান্ত', 'উদাস', 'কাঁদছি'],
          'w': []
        },
        'weather': {
          'q': ['weather', 'hot', 'cold', 'rain', 'আবহাওয়া', 'গরম', 'ঠান্ডা', 'বৃষ্টি'],
          'w': []
        },
        'music': {
          'q': ['music', 'song', 'sing', 'radio', 'গান', 'সুর', 'মিউজিক', 'গাই'],
          'w': []
        },
        'thank': {
          'q': ['thank you', 'thanks', 'thx', 'ধন্যবাদ'],
          'w': ['thanks', 'thank']
        },
        'farewell': {
          'q': ['bye', 'goodbye', 'good night', 'see you', 'বিদায়', 'আসি', 'শুভ রাত্রি'],
          'w': []
        },
        'yes': {
          'q': ['yes', 'yeah', 'yep', 'sure', 'হ্যাঁ', 'উই', 'ঠিক আছে'],
          'w': ['yes']
        },
        'no': {
          'q': ['no', 'nope', 'not', 'na', 'না', 'নেই'],
          'w': ['no']
        },
        'tell_more': {
          'q': ['tell me more', 'more', 'go on', 'continue', 'বলুন', 'আরও বলুন', 'বাকি'],
          'w': []
        },
      };

  void reset() {
    memory.clear();
    _awaitingYesNo = false;
    _lastTopicIntent = '';
  }
}