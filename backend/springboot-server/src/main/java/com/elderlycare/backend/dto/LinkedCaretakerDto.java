package com.elderlycare.backend.dto;

public class LinkedCaretakerDto {

    private String caretakerId;
    private String fullName;
    private String email;
    private String phoneNumber;
    private String relation;
    private boolean isPrimary;
    private String linkedDate;

    public LinkedCaretakerDto() {
    }

    public LinkedCaretakerDto(String caretakerId, String fullName, String email, String phoneNumber, String relation, boolean isPrimary, String linkedDate) {
        this.caretakerId = caretakerId;
        this.fullName = fullName;
        this.email = email;
        this.phoneNumber = phoneNumber;
        this.relation = relation;
        this.isPrimary = isPrimary;
        this.linkedDate = linkedDate;
    }

    public String getCaretakerId() {
        return caretakerId;
    }

    public void setCaretakerId(String caretakerId) {
        this.caretakerId = caretakerId;
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
