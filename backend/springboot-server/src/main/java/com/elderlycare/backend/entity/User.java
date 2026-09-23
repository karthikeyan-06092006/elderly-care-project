package com.elderlycare.backend.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "USERS")
public class User {

    @Id
    @Column(name = "USER_ID", length = 36)
    private String userId;

    @Column(name = "EMAIL", unique = true, nullable = false, length = 100)
    private String email;

    @Column(name = "PASSWORD_HASH", nullable = false, length = 255)
    private String passwordHash;

    @Column(name = "ROLE", nullable = false, length = 30)
    private String role; // "PATIENT", "CARETAKER", "HEALTHCARE_WORKER", "ADMIN"

    @Column(name = "FULL_NAME", length = 100)
    private String fullName;

    @Column(name = "PHONE_NUMBER", length = 20)
    private String phoneNumber;

    @Column(name = "AGE")
    private Integer age;

    @Column(name = "DATE_OF_BIRTH", length = 30)
    private String dateOfBirth;

    @Column(name = "GENDER", length = 20)
    private String gender;

    @Column(name = "STATE", length = 100)
    private String state;

    @Column(name = "DISTRICT", length = 100)
    private String district;

    @Column(name = "PINCODE", length = 20)
    private String pincode;

    @Column(name = "PROFESSION", length = 50)
    private String profession; // "DOCTOR", "NURSE", "ASHA_WORKER"

    @Column(name = "SPECIALIZATION", length = 100)
    private String specialization;

    @Column(name = "HOSPITAL_NAME", length = 150)
    private String hospitalName;

    @Column(name = "STATE_COUNCIL", length = 100)
    private String stateCouncil;

    @Column(name = "REGISTRATION_NUMBER", length = 100)
    private String registrationNumber;

    @Column(name = "NUID", length = 50)
    private String nuid;

    @Column(name = "ID_PROOF_URL", length = 500)
    private String idProofUrl;

    @Column(name = "VERIFICATION_STATUS", length = 20)
    private String verificationStatus; // "PENDING", "APPROVED", "REJECTED"

    @Column(name = "QR_CODE_TOKEN", length = 100)
    private String qrCodeToken;

    @Column(name = "FCM_TOKEN", length = 500)
    private String fcmToken;

    @Column(name = "CREATED_AT")
    private LocalDateTime createdAt;

    public User() {
    }

    public User(String userId, String email, String passwordHash, String role, String fullName, String phoneNumber, String qrCodeToken, LocalDateTime createdAt) {
        this.userId = userId;
        this.email = email;
        this.passwordHash = passwordHash;
        this.role = role;
        this.fullName = fullName;
        this.phoneNumber = phoneNumber;
        this.qrCodeToken = qrCodeToken;
        this.createdAt = createdAt;
        this.verificationStatus = "APPROVED";
    }

    // Getters and Setters
    public String getUserId() {
        return userId;
    }

    public void setUserId(String userId) {
        this.userId = userId;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getPasswordHash() {
        return passwordHash;
    }

    public void setPasswordHash(String passwordHash) {
        this.passwordHash = passwordHash;
    }

    public String getRole() {
        return role;
    }

    public void setRole(String role) {
        this.role = role;
    }

    public String getFullName() {
        return fullName;
    }

    public void setFullName(String fullName) {
        this.fullName = fullName;
    }

    public String getPhoneNumber() {
        return phoneNumber;
    }

    public void setPhoneNumber(String phoneNumber) {
        this.phoneNumber = phoneNumber;
    }

    public Integer getAge() {
        return age;
    }

    public void setAge(Integer age) {
        this.age = age;
    }

    public String getGender() {
        return gender;
    }

    public void setGender(String gender) {
        this.gender = gender;
    }

    public String getState() {
        return state;
    }

    public void setState(String state) {
        this.state = state;
    }

    public String getDistrict() {
        return district;
    }

    public void setDistrict(String district) {
        this.district = district;
    }

    public String getPincode() {
        return pincode;
    }

    public void setPincode(String pincode) {
        this.pincode = pincode;
    }

    public String getProfession() {
        return profession;
    }

    public void setProfession(String profession) {
        this.profession = profession;
    }

    public String getSpecialization() {
        return specialization;
    }

    public void setSpecialization(String specialization) {
        this.specialization = specialization;
    }

    public String getHospitalName() {
        return hospitalName;
    }

    public void setHospitalName(String hospitalName) {
        this.hospitalName = hospitalName;
    }

    public String getStateCouncil() {
        return stateCouncil;
    }

    public void setStateCouncil(String stateCouncil) {
        this.stateCouncil = stateCouncil;
    }

    public String getRegistrationNumber() {
        return registrationNumber;
    }

    public void setRegistrationNumber(String registrationNumber) {
        this.registrationNumber = registrationNumber;
    }

    public String getNuid() {
        return nuid;
    }

    public void setNuid(String nuid) {
        this.nuid = nuid;
    }

    public String getIdProofUrl() {
        return idProofUrl;
    }

    public void setIdProofUrl(String idProofUrl) {
        this.idProofUrl = idProofUrl;
    }

    public String getVerificationStatus() {
        return verificationStatus;
    }

    public void setVerificationStatus(String verificationStatus) {
        this.verificationStatus = verificationStatus;
    }

    public String getQrCodeToken() {
        return qrCodeToken;
    }

    public void setQrCodeToken(String qrCodeToken) {
        this.qrCodeToken = qrCodeToken;
    }

    public String getFcmToken() {
        return fcmToken;
    }

    public void setFcmToken(String fcmToken) {
        this.fcmToken = fcmToken;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public String getDateOfBirth() {
        return dateOfBirth;
    }

    public void setDateOfBirth(String dateOfBirth) {
        this.dateOfBirth = dateOfBirth;
    }
}
