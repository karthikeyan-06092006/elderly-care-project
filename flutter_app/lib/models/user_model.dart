class CaretakerContact {
  final String name;
  final String phone;
  final String relation;
  final bool isPrimary;

  const CaretakerContact({
    required this.name,
    required this.phone,
    required this.relation,
    this.isPrimary = false,
  });
}

class PatientProfile {
  String userId;
  String name;
  String email;
  String phone;
  String registeredDate;
  String qrCodeToken;
  String? photoPath;
  CaretakerContact primaryCaretaker;
  List<CaretakerContact> otherCaretakers;

  PatientProfile({
    this.userId = '',
    required this.name,
    required this.email,
    required this.phone,
    required this.registeredDate,
    required this.qrCodeToken,
    this.photoPath,
    required this.primaryCaretaker,
    required this.otherCaretakers,
  });

  PatientProfile copyWith({
    String? userId,
    String? name,
    String? email,
    String? phone,
    String? registeredDate,
    String? qrCodeToken,
    String? photoPath,
    bool clearPhoto = false,
    CaretakerContact? primaryCaretaker,
    List<CaretakerContact>? otherCaretakers,
  }) {
    return PatientProfile(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      registeredDate: registeredDate ?? this.registeredDate,
      qrCodeToken: qrCodeToken ?? this.qrCodeToken,
      photoPath: clearPhoto ? null : (photoPath ?? this.photoPath),
      primaryCaretaker: primaryCaretaker ?? this.primaryCaretaker,
      otherCaretakers: otherCaretakers ?? this.otherCaretakers,
    );
  }

  factory PatientProfile.fromSession(UserSession session) {
    return PatientProfile(
      userId: session.userId,
      name: session.name.isNotEmpty ? session.name : "Patient",
      email: session.email,
      phone: session.phone.isNotEmpty ? session.phone : "",
      registeredDate: session.registeredDate.isNotEmpty ? session.registeredDate : "Today",
      qrCodeToken: session.qrCodeToken.isNotEmpty ? session.qrCodeToken : "PATIENT-NEW",
      primaryCaretaker: const CaretakerContact(
        name: "No Primary Caregiver Linked",
        phone: "",
        relation: "Unlinked",
        isPrimary: false,
      ),
      otherCaretakers: const [],
    );
  }

  factory PatientProfile.demo(String email, String name, String phone) {
    return PatientProfile(
      name: name.isNotEmpty ? name : "Patient",
      email: email.isNotEmpty ? email : "patient@example.com",
      phone: phone.isNotEmpty ? phone : "",
      registeredDate: "19 September 2026",
      qrCodeToken: "PATIENT-QR",
      primaryCaretaker: const CaretakerContact(
        name: "No Primary Caregiver Linked",
        phone: "",
        relation: "Unlinked",
        isPrimary: false,
      ),
      otherCaretakers: const [],
    );
  }
}

class UserSession {
  final String userId;
  final String email;
  final String name;
  final String phone;
  final String role; // 'PATIENT' or 'CARETAKER'
  final String qrCodeToken;
  final String registeredDate;
  final String token;

  const UserSession({
    required this.userId,
    required this.email,
    required this.name,
    required this.phone,
    required this.role,
    required this.qrCodeToken,
    required this.registeredDate,
    required this.token,
  });

  bool get isPatient => role.toUpperCase() == 'PATIENT';
  bool get isCaretaker => role.toUpperCase() == 'CARETAKER';

  factory UserSession.fromJson(Map<String, dynamic> json) {
    return UserSession(
      userId: json['userId'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? 'PATIENT',
      qrCodeToken: json['qrCodeToken'] ?? '',
      registeredDate: json['registeredDate'] ?? '',
      token: json['token'] ?? '',
    );
  }
}

class LinkedPatient {
  final String patientId;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String qrCodeToken;
  final String relation;
  final bool isPrimary;
  final String linkedDate;

  const LinkedPatient({
    required this.patientId,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.qrCodeToken,
    required this.relation,
    required this.isPrimary,
    required this.linkedDate,
  });

  factory LinkedPatient.fromJson(Map<String, dynamic> json) {
    return LinkedPatient(
      patientId: json['patientId'] ?? '',
      fullName: json['fullName'] ?? 'Unknown Patient',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      qrCodeToken: json['qrCodeToken'] ?? '',
      relation: json['relation'] ?? 'Caregiver',
      isPrimary: json['primary'] ?? json['isPrimary'] ?? false,
      linkedDate: json['linkedDate'] ?? '',
    );
  }
}

class LinkedCaretaker {
  final String caretakerId;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String relation;
  final bool isPrimary;
  final String linkedDate;

  const LinkedCaretaker({
    required this.caretakerId,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.relation,
    required this.isPrimary,
    required this.linkedDate,
  });

  factory LinkedCaretaker.fromJson(Map<String, dynamic> json) {
    return LinkedCaretaker(
      caretakerId: json['caretakerId'] ?? '',
      fullName: json['fullName'] ?? 'Caretaker',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      relation: json['relation'] ?? 'Caretaker',
      isPrimary: json['primary'] ?? json['isPrimary'] ?? false,
      linkedDate: json['linkedDate'] ?? '',
    );
  }

  CaretakerContact toContact() {
    return CaretakerContact(
      name: fullName,
      phone: phoneNumber,
      relation: relation,
      isPrimary: isPrimary,
    );
  }
}

class ActiveEmergencyAlert {
  final int alertId;
  final String patientId;
  final String patientName;
  final String patientEmail;
  final String patientPhone;
  final String primaryCaretakerName;
  final String primaryCaretakerPhone;
  final String status;
  final String createdAt;
  final int secondsAgo;

  const ActiveEmergencyAlert({
    required this.alertId,
    required this.patientId,
    required this.patientName,
    required this.patientEmail,
    required this.patientPhone,
    required this.primaryCaretakerName,
    required this.primaryCaretakerPhone,
    required this.status,
    required this.createdAt,
    required this.secondsAgo,
  });

  factory ActiveEmergencyAlert.fromJson(Map<String, dynamic> json) {
    return ActiveEmergencyAlert(
      alertId: json['alertId'] is int ? json['alertId'] : int.tryParse(json['alertId']?.toString() ?? '0') ?? 0,
      patientId: json['patientId'] ?? '',
      patientName: json['patientName'] ?? 'Patient',
      patientEmail: json['patientEmail'] ?? '',
      patientPhone: json['patientPhone'] ?? '',
      primaryCaretakerName: json['primaryCaretakerName'] ?? '',
      primaryCaretakerPhone: json['primaryCaretakerPhone'] ?? '',
      status: json['status'] ?? 'ACTIVE',
      createdAt: json['createdAt'] ?? '',
      secondsAgo: json['secondsAgo'] is int ? json['secondsAgo'] : 0,
    );
  }
}

