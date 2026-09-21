package com.elderlycare.backend.dto;

import java.time.LocalDateTime;

public class EmergencyAlertDto {
    private Long alertId;
    private String patientId;
    private String patientName;
    private String patientEmail;
    private String patientPhone;
    private String primaryCaretakerName;
    private String primaryCaretakerPhone;
    private String status;
    private LocalDateTime createdAt;
    private int secondsAgo;

    public EmergencyAlertDto() {
    }

    public EmergencyAlertDto(Long alertId, String patientId, String patientName, String patientEmail,
                             String patientPhone, String primaryCaretakerName, String primaryCaretakerPhone,
                             String status, LocalDateTime createdAt) {
        this.alertId = alertId;
        this.patientId = patientId;
        this.patientName = patientName;
        this.patientEmail = patientEmail;
        this.patientPhone = patientPhone;
        this.primaryCaretakerName = primaryCaretakerName;
        this.primaryCaretakerPhone = primaryCaretakerPhone;
        this.status = status;
        this.createdAt = createdAt;
    }

    public Long getAlertId() {
        return alertId;
    }

    public void setAlertId(Long alertId) {
        this.alertId = alertId;
    }

    public String getPatientId() {
        return patientId;
    }

    public void setPatientId(String patientId) {
        this.patientId = patientId;
    }

    public String getPatientName() {
        return patientName;
    }

    public void setPatientName(String patientName) {
        this.patientName = patientName;
    }

    public String getPatientEmail() {
        return patientEmail;
    }

    public void setPatientEmail(String patientEmail) {
        this.patientEmail = patientEmail;
    }

    public String getPatientPhone() {
        return patientPhone;
    }

    public void setPatientPhone(String patientPhone) {
        this.patientPhone = patientPhone;
    }

    public String getPrimaryCaretakerName() {
        return primaryCaretakerName;
    }

    public void setPrimaryCaretakerName(String primaryCaretakerName) {
        this.primaryCaretakerName = primaryCaretakerName;
    }

    public String getPrimaryCaretakerPhone() {
        return primaryCaretakerPhone;
    }

    public void setPrimaryCaretakerPhone(String primaryCaretakerPhone) {
        this.primaryCaretakerPhone = primaryCaretakerPhone;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public int getSecondsAgo() {
        return secondsAgo;
    }

    public void setSecondsAgo(int secondsAgo) {
        this.secondsAgo = secondsAgo;
    }
}
