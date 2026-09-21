package com.elderlycare.backend.dto;

public class LinkedPatientDto {

    private String patientId;
    private String fullName;
    private String email;
    private String phoneNumber;
    private String qrCodeToken;
    private String relation;
    private boolean isPrimary;
    private String linkedDate;

    public LinkedPatientDto() {
    }

    public LinkedPatientDto(String patientId, String fullName, String email, String phoneNumber, String qrCodeToken, String relation, boolean isPrimary, String linkedDate) {
        this.patientId = patientId;
        this.fullName = fullName;
        this.email = email;
        this.phoneNumber = phoneNumber;
        this.qrCodeToken = qrCodeToken;
        this.relation = relation;
        this.isPrimary = isPrimary;
        this.linkedDate = linkedDate;
    }

    public String getPatientId() {
        return patientId;
    }

    public void setPatientId(String patientId) {
        this.patientId = patientId;
    }

    public String getFullName() {
        return fullName;
    }

    public void setFullName(String fullName) {
        this.fullName = fullName;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getPhoneNumber() {
        return phoneNumber;
    }

    public void setPhoneNumber(String phoneNumber) {
        this.phoneNumber = phoneNumber;
    }

    public String getQrCodeToken() {
        return qrCodeToken;
    }

    public void setQrCodeToken(String qrCodeToken) {
        this.qrCodeToken = qrCodeToken;
    }

    public String getRelation() {
        return relation;
    }

    public void setRelation(String relation) {
        this.relation = relation;
    }

    public boolean isPrimary() {
        return isPrimary;
    }

    public void setPrimary(boolean primary) {
        isPrimary = primary;
    }

    public String getLinkedDate() {
        return linkedDate;
    }

    public void setLinkedDate(String linkedDate) {
        this.linkedDate = linkedDate;
    }
}
