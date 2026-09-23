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
  int age;
  String dateOfBirth;
  String state;
  String district;
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
    this.age = 70,
    this.dateOfBirth = '',
    this.state = "Assam",
    this.district = "Kamrup Metro",
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
    int? age,
    String? dateOfBirth,
    String? state,
    String? district,
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
      age: age ?? this.age,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      state: state ?? this.state,
      district: district ?? this.district,
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
      age: session.age > 0 ? session.age : 70,
      dateOfBirth: session.dateOfBirth,
      state: session.state.isNotEmpty ? session.state : "Assam",
      district: session.district.isNotEmpty ? session.district : "Kamrup Metro",
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
      age: 72,
      dateOfBirth: "15/04/1954",
      state: "Assam",
      district: "Kamrup Metro",
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
  final String role; // 'PATIENT', 'CARETAKER', 'HEALTHCARE_WORKER', 'ADMIN'
  final int age;
  final String dateOfBirth;
  final String gender;
  final String state;
  final String district;
  final String pincode;
  final String profession;
  final String specialization;
  final String hospitalName;
  final String stateCouncil;
  final String registrationNumber;
  final String verificationStatus; // 'PENDING', 'APPROVED', 'REJECTED'
  final String qrCodeToken;
  final String registeredDate;
  final String token;

  const UserSession({
    required this.userId,
    required this.email,
    required this.name,
    required this.phone,
    required this.role,
    this.age = 0,
    this.dateOfBirth = '',
    this.gender = '',
    this.state = '',
    this.district = '',
    this.pincode = '',
    this.profession = '',
    this.specialization = '',
    this.hospitalName = '',
    this.stateCouncil = '',
    this.registrationNumber = '',
    this.verificationStatus = 'APPROVED',
    required this.qrCodeToken,
    required this.registeredDate,
    required this.token,
  });

  bool get isPatient => role.toUpperCase() == 'PATIENT';
  bool get isCaretaker => role.toUpperCase() == 'CARETAKER';
  bool get isHealthcareWorker => role.toUpperCase() == 'HEALTHCARE_WORKER';
  bool get isAdmin => role.toUpperCase() == 'ADMIN';
  bool get isVerified => verificationStatus.toUpperCase() == 'APPROVED';

  factory UserSession.fromJson(Map<String, dynamic> json) {
    return UserSession(
      userId: json['userId'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? 'PATIENT',
      age: json['age'] is int ? json['age'] : int.tryParse(json['age']?.toString() ?? '0') ?? 0,
      dateOfBirth: json['dateOfBirth'] ?? '',
      gender: json['gender'] ?? '',
      state: json['state'] ?? '',
      district: json['district'] ?? '',
      pincode: json['pincode'] ?? '',
      profession: json['profession'] ?? '',
      specialization: json['specialization'] ?? '',
      hospitalName: json['hospitalName'] ?? '',
      stateCouncil: json['stateCouncil'] ?? '',
      registrationNumber: json['registrationNumber'] ?? '',
      verificationStatus: json['verificationStatus'] ?? 'APPROVED',
      qrCodeToken: json['qrCodeToken'] ?? '',
      registeredDate: json['registeredDate'] ?? '',
      token: json['token'] ?? '',
    );
  }
}

class HealthcareWorkerModel {
  final String workerId;
  final String fullName;
  final String email;
  final String phone;
  final String profession;
  final String specialization;
  final String hospitalName;
  final String state;
  final String district;
  final String stateCouncil;
  final String registrationNumber;
  final String verificationStatus;

  const HealthcareWorkerModel({
    required this.workerId,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.profession,
    required this.specialization,
    required this.hospitalName,
    required this.state,
    required this.district,
    required this.stateCouncil,
    required this.registrationNumber,
    required this.verificationStatus,
  });

  factory HealthcareWorkerModel.fromJson(Map<String, dynamic> json) {
    return HealthcareWorkerModel(
      workerId: json['workerId'] ?? '',
      fullName: json['fullName'] ?? 'Healthcare Professional',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      profession: json['profession'] ?? 'DOCTOR',
      specialization: json['specialization'] ?? 'Geriatric Care',
      hospitalName: json['hospitalName'] ?? 'Community Health Center',
      state: json['state'] ?? 'Assam',
      district: json['district'] ?? 'Kamrup Metro',
      stateCouncil: json['stateCouncil'] ?? 'State Medical Council',
      registrationNumber: json['registrationNumber'] ?? '',
      verificationStatus: json['verificationStatus'] ?? 'APPROVED',
    );
  }
}

class AssignedPatientModel {
  final int assignmentId;
  final String patientId;
  final String fullName;
  final int age;
  final String gender;
  final String phoneNumber;
  final String state;
  final String district;
  final String status;
  final String qrCodeToken;
  final String notes;

  const AssignedPatientModel({
    required this.assignmentId,
    required this.patientId,
    required this.fullName,
    required this.age,
    required this.gender,
    required this.phoneNumber,
    required this.state,
    required this.district,
    required this.status,
    required this.qrCodeToken,
    required this.notes,
  });

  factory AssignedPatientModel.fromJson(Map<String, dynamic> json) {
    return AssignedPatientModel(
      assignmentId: json['assignmentId'] is int ? json['assignmentId'] : int.tryParse(json['assignmentId']?.toString() ?? '0') ?? 0,
      patientId: json['patientId'] ?? '',
      fullName: json['fullName'] ?? 'Unknown Patient',
      age: json['age'] is int ? json['age'] : int.tryParse(json['age']?.toString() ?? '70') ?? 70,
      gender: json['gender'] ?? 'Not Specified',
      phoneNumber: json['phoneNumber'] ?? '',
      state: json['state'] ?? 'Assam',
      district: json['district'] ?? 'Kamrup Metro',
      status: json['status'] ?? 'PENDING',
      qrCodeToken: json['qrCodeToken'] ?? '',
      notes: json['notes'] ?? '',
    );
  }
}

class AdminPendingWorkerModel {
  final String userId;
  final String fullName;
  final String email;
  final String phone;
  final String profession;
  final String specialization;
  final String hospitalName;
  final String stateCouncil;
  final String registrationNumber;
  final String nuid;
  final String state;
  final String district;
  final String verificationStatus;
  final String createdAt;

  const AdminPendingWorkerModel({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.profession,
    required this.specialization,
    required this.hospitalName,
    required this.stateCouncil,
    required this.registrationNumber,
    required this.nuid,
    required this.state,
    required this.district,
    required this.verificationStatus,
    required this.createdAt,
  });

  factory AdminPendingWorkerModel.fromJson(Map<String, dynamic> json) {
    return AdminPendingWorkerModel(
      userId: json['userId'] ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      profession: json['profession'] ?? 'DOCTOR',
      specialization: json['specialization'] ?? '',
      hospitalName: json['hospitalName'] ?? '',
      stateCouncil: json['stateCouncil'] ?? '',
      registrationNumber: json['registrationNumber'] ?? '',
      nuid: json['nuid'] ?? '',
      state: json['state'] ?? '',
      district: json['district'] ?? '',
      verificationStatus: json['verificationStatus'] ?? 'PENDING',
      createdAt: json['createdAt'] ?? '',
    );
  }
}

class LinkedPatient {
  final String patientId;
  final String fullName;
  final String email;
  final String phoneNumber;
  final int age;
  final String state;
  final String district;
  final String qrCodeToken;
  final String relation;
  final bool isPrimary;
  final String linkedDate;

  const LinkedPatient({
    required this.patientId,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    this.age = 70,
    this.state = 'Assam',
    this.district = 'Kamrup Metro',
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
      age: json['age'] is int ? json['age'] : int.tryParse(json['age']?.toString() ?? '70') ?? 70,
      state: json['state'] ?? 'Assam',
      district: json['district'] ?? 'Kamrup Metro',
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
