package com.elderlycare.backend.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "HEALTHCARE_ASSIGNMENTS")
public class HealthcareAssignment {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "ASSIGNMENT_ID")
    private Long assignmentId;

    @Column(name = "PATIENT_ID", nullable = false, length = 36)
    private String patientId;

    @Column(name = "HEALTHCARE_WORKER_ID", nullable = false, length = 36)
    private String healthcareWorkerId;

    @Column(name = "REQUESTED_BY", length = 36)
    private String requestedBy;

    @Column(name = "STATUS", nullable = false, length = 20)
    private String status; // "PENDING", "ACCEPTED", "REJECTED"

    @Column(name = "NOTES", length = 500)
    private String notes;

    @Column(name = "CREATED_AT")
    private LocalDateTime createdAt;

    public HealthcareAssignment() {
    }

    public HealthcareAssignment(String patientId, String healthcareWorkerId, String requestedBy, String status, LocalDateTime createdAt) {
        this.patientId = patientId;
        this.healthcareWorkerId = healthcareWorkerId;
        this.requestedBy = requestedBy;
        this.status = status;
        this.createdAt = createdAt;
    }

    public Long getAssignmentId() {
        return assignmentId;
    }

    public void setAssignmentId(Long assignmentId) {
        this.assignmentId = assignmentId;
    }

    public String getPatientId() {
        return patientId;
    }

    public void setPatientId(String patientId) {
        this.patientId = patientId;
    }

    public String getHealthcareWorkerId() {
        return healthcareWorkerId;
    }

    public void setHealthcareWorkerId(String healthcareWorkerId) {
        this.healthcareWorkerId = healthcareWorkerId;
    }

    public String getRequestedBy() {
        return requestedBy;
    }

    public void setRequestedBy(String requestedBy) {
        this.requestedBy = requestedBy;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public String getNotes() {
        return notes;
    }

    public void setNotes(String notes) {
        this.notes = notes;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
}
