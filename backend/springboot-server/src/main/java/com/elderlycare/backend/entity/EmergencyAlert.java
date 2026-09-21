package com.elderlycare.backend.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "EMERGENCY_ALERTS")
public class EmergencyAlert {

    @Id
    @GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "alert_seq_gen")
    @SequenceGenerator(name = "alert_seq_gen", sequenceName = "ALERT_SEQ", allocationSize = 1)
    @Column(name = "ID")
    private Long id;

    @Column(name = "PATIENT_ID", nullable = false, length = 36)
    private String patientId;

    @Column(name = "PATIENT_NAME", nullable = false, length = 100)
    private String patientName;

    @Column(name = "PATIENT_EMAIL", nullable = false, length = 100)
    private String patientEmail;

    @Column(name = "PATIENT_PHONE", length = 20)
    private String patientPhone;

    @Column(name = "PRIMARY_CARETAKER_NAME", length = 100)
    private String primaryCaretakerName;

    @Column(name = "PRIMARY_CARETAKER_PHONE", length = 20)
    private String primaryCaretakerPhone;

    @Column(name = "STATUS", nullable = false, length = 20)
    private String status; // "ACTIVE" or "RESOLVED"

    @Column(name = "CREATED_AT", nullable = false)
    private LocalDateTime createdAt;

    @Column(name = "RESOLVED_AT")
    private LocalDateTime resolvedAt;

    public EmergencyAlert() {
    }

    public EmergencyAlert(String patientId, String patientName, String patientEmail, String patientPhone,
                          String primaryCaretakerName, String primaryCaretakerPhone,
                          String status, LocalDateTime createdAt) {
        this.patientId = patientId;
        this.patientName = patientName;
        this.patientEmail = patientEmail;
        this.patientPhone = patientPhone;
        this.primaryCaretakerName = primaryCaretakerName;
        this.primaryCaretakerPhone = primaryCaretakerPhone;
        this.status = status;
        this.createdAt = createdAt;
    }

    // Getters and Setters
    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
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

    public LocalDateTime getResolvedAt() {
        return resolvedAt;
    }

    public void setResolvedAt(LocalDateTime resolvedAt) {
        this.resolvedAt = resolvedAt;
    }
}
