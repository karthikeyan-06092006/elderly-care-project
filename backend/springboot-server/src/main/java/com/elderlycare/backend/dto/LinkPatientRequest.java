package com.elderlycare.backend.dto;

import jakarta.validation.constraints.NotBlank;

public class LinkPatientRequest {

    @NotBlank(message = "Caretaker ID is required")
    private String caretakerId;

    @NotBlank(message = "Patient QR code token is required")
    private String patientQrToken;

    private String relation; // Default e.g. "Primary Caregiver", "Family Member", "Attending Physician"

    private Boolean isPrimary;

    public LinkPatientRequest() {
    }

    public LinkPatientRequest(String caretakerId, String patientQrToken, String relation, Boolean isPrimary) {
        this.caretakerId = caretakerId;
        this.patientQrToken = patientQrToken;
        this.relation = relation;
        this.isPrimary = isPrimary;
    }

    public String getCaretakerId() {
        return caretakerId;
    }

    public void setCaretakerId(String caretakerId) {
        this.caretakerId = caretakerId;
    }

    public String getPatientQrToken() {
        return patientQrToken;
    }

    public void setPatientQrToken(String patientQrToken) {
        this.patientQrToken = patientQrToken;
    }

    public String getRelation() {
        return relation;
    }

    public void setRelation(String relation) {
        this.relation = relation;
    }

    public Boolean getIsPrimary() {
        return isPrimary;
    }

    public void setIsPrimary(Boolean isPrimary) {
        this.isPrimary = isPrimary;
    }
}
