package com.elderlycare.backend.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "SOCIAL_CONNECTIONS")
public class SocialConnection {

    @Id
    @GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "social_conn_seq_gen")
    @SequenceGenerator(name = "social_conn_seq_gen", sequenceName = "SOCIAL_CONN_SEQ", allocationSize = 1)
    @Column(name = "ID")
    private Long id;

    @Column(name = "REQUESTER_PATIENT_ID", nullable = false, length = 36)
    private String requesterPatientId;

    @Column(name = "RECEIVER_PATIENT_ID", nullable = false, length = 36)
    private String receiverPatientId;

    @Column(name = "STATUS", nullable = false, length = 20)
    private String status; // "PENDING", "CONNECTED", "REJECTED"

    @Column(name = "PATIENT_APPROVED", nullable = false)
    private boolean patientApproved;

    @Column(name = "CARETAKER_APPROVED", nullable = false)
    private boolean caretakerApproved;

    @Column(name = "CARETAKER_ID", length = 36)
    private String caretakerId;

    @Column(name = "REQUEST_MESSAGE", length = 500)
    private String requestMessage;

    @Column(name = "REQUESTED_AT")
    private LocalDateTime requestedAt;

    @Column(name = "PATIENT_APPROVED_AT")
    private LocalDateTime patientApprovedAt;

    @Column(name = "CARETAKER_APPROVED_AT")
    private LocalDateTime caretakerApprovedAt;

    @Column(name = "CONNECTED_AT")
    private LocalDateTime connectedAt;

    public SocialConnection() {
    }

    public SocialConnection(String requesterPatientId, String receiverPatientId, String status,
                            String requestMessage, LocalDateTime requestedAt) {
        this.requesterPatientId = requesterPatientId;
        this.receiverPatientId = receiverPatientId;
        this.status = status;
        this.requestMessage = requestMessage;
        this.requestedAt = requestedAt;
        this.patientApproved = false;
        this.caretakerApproved = false;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getRequesterPatientId() {
        return requesterPatientId;
    }

    public void setRequesterPatientId(String requesterPatientId) {
        this.requesterPatientId = requesterPatientId;
    }

    public String getReceiverPatientId() {
        return receiverPatientId;
    }

    public void setReceiverPatientId(String receiverPatientId) {
        this.receiverPatientId = receiverPatientId;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public boolean isPatientApproved() {
        return patientApproved;
    }

    public void setPatientApproved(boolean patientApproved) {
        this.patientApproved = patientApproved;
    }

    public boolean isCaretakerApproved() {
        return caretakerApproved;
    }

    public void setCaretakerApproved(boolean caretakerApproved) {
        this.caretakerApproved = caretakerApproved;
    }

    public String getCaretakerId() {
        return caretakerId;
    }

    public void setCaretakerId(String caretakerId) {
        this.caretakerId = caretakerId;
    }

    public String getRequestMessage() {
        return requestMessage;
    }

    public void setRequestMessage(String requestMessage) {
        this.requestMessage = requestMessage;
    }

    public LocalDateTime getRequestedAt() {
        return requestedAt;
    }

    public void setRequestedAt(LocalDateTime requestedAt) {
        this.requestedAt = requestedAt;
    }

    public LocalDateTime getPatientApprovedAt() {
        return patientApprovedAt;
    }

    public void setPatientApprovedAt(LocalDateTime patientApprovedAt) {
        this.patientApprovedAt = patientApprovedAt;
    }

    public LocalDateTime getCaretakerApprovedAt() {
        return caretakerApprovedAt;
    }

    public void setCaretakerApprovedAt(LocalDateTime caretakerApprovedAt) {
        this.caretakerApprovedAt = caretakerApprovedAt;
    }

    public LocalDateTime getConnectedAt() {
        return connectedAt;
    }

    public void setConnectedAt(LocalDateTime connectedAt) {
        this.connectedAt = connectedAt;
    }
}