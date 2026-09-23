class DiscoverablePatient {
  final String userId;
  final String fullName;
  final String email;
  final String phoneNumber;

  const DiscoverablePatient({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
  });

  factory DiscoverablePatient.fromJson(Map<String, dynamic> json) {
    return DiscoverablePatient(
      userId: json['userId'] ?? '',
      fullName: json['fullName'] ?? 'Patient',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
    );
  }
}

class SocialConnection {
  final int connectionId;
  final String requesterPatientId;
  final String requesterName;
  final String receiverPatientId;
  final String receiverName;
  final String status;
  final bool patientApproved;
  final bool caretakerApproved;
  final String caretakerId;
  final String requestMessage;
  final String requestedAt;
  final String connectedAt;

  const SocialConnection({
    required this.connectionId,
    required this.requesterPatientId,
    required this.requesterName,
    required this.receiverPatientId,
    required this.receiverName,
    required this.status,
    required this.patientApproved,
    required this.caretakerApproved,
    required this.caretakerId,
    required this.requestMessage,
    required this.requestedAt,
    required this.connectedAt,
  });

  bool get isConnected => status == 'CONNECTED';
  bool get isPending => status == 'PENDING';
  bool get isWaitingForPatient =>
      isPending && !patientApproved;
  bool get isWaitingForCaretaker =>
      isPending && patientApproved && !caretakerApproved;

  String otherName(String myUserId) {
    return requesterPatientId == myUserId ? receiverName : requesterName;
  }

  String otherPatientId(String myUserId) {
    return requesterPatientId == myUserId ? receiverPatientId : requesterPatientId;
  }

  bool involvesPatient(String patientId) {
    return requesterPatientId == patientId || receiverPatientId == patientId;
  }

  factory SocialConnection.fromJson(Map<String, dynamic> json) {
    return SocialConnection(
      connectionId: json['connectionId'] is int
          ? json['connectionId']
          : int.tryParse(json['connectionId']?.toString() ?? '0') ?? 0,
      requesterPatientId: json['requesterPatientId'] ?? '',
      requesterName: json['requesterName'] ?? 'Patient',
      receiverPatientId: json['receiverPatientId'] ?? '',
      receiverName: json['receiverName'] ?? 'Patient',
      status: json['status'] ?? 'PENDING',
      patientApproved: json['patientApproved'] ?? false,
      caretakerApproved: json['caretakerApproved'] ?? false,
      caretakerId: json['caretakerId'] ?? '',
      requestMessage: json['requestMessage'] ?? '',
      requestedAt: json['requestedAt'] ?? '',
      connectedAt: json['connectedAt'] ?? '',
    );
  }
}

class SocialMessage {
  final int messageId;
  final int connectionId;
  final String senderId;
  final String senderName;
  final String type;
  final String content;
  final String mediaUrl;
  final int durationMs;
  final bool isRead;
  final String sentAt;

  const SocialMessage({
    required this.messageId,
    required this.connectionId,
    required this.senderId,
    required this.senderName,
    required this.type,
    required this.content,
    required this.mediaUrl,
    required this.durationMs,
    required this.isRead,
    required this.sentAt,
  });

  bool get isText => type == 'TEXT';
  bool get isVoice => type == 'VOICE';
  bool get isPhoto => type == 'PHOTO';

  factory SocialMessage.fromJson(Map<String, dynamic> json) {
    return SocialMessage(
      messageId: json['messageId'] is int
          ? json['messageId']
          : int.tryParse(json['messageId']?.toString() ?? '0') ?? 0,
      connectionId: json['connectionId'] is int
          ? json['connectionId']
          : int.tryParse(json['connectionId']?.toString() ?? '0') ?? 0,
      senderId: json['senderId'] ?? '',
      senderName: json['senderName'] ?? '',
      type: json['type'] ?? 'TEXT',
      content: json['content'] ?? '',
      mediaUrl: json['mediaUrl'] ?? '',
      durationMs: json['durationMs'] is int
          ? json['durationMs']
          : int.tryParse(json['durationMs']?.toString() ?? '0') ?? 0,
      isRead: json['read'] ?? json['isRead'] ?? false,
      sentAt: json['sentAt'] ?? '',
    );
  }
}