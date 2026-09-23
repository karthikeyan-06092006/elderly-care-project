package com.elderlycare.backend.dto;

public class SocialConnectionDto {

    private Long connectionId;
    private String requesterPatientId;
    private String requesterName;
    private String receiverPatientId;
    private String receiverName;
    private String status;
    private boolean patientApproved;
    private boolean caretakerApproved;
    private String caretakerId;
    private String requestMessage;
    private String requestedAt;
    private String connectedAt;

    public SocialConnectionDto() {
    }

    public Long getConnectionId() {
        return connectionId;
    }

    public void setConnectionId(Long connectionId) {
        this.connectionId = connectionId;
    }

    public String getRequesterPatientId() {
        return requesterPatientId;
    }

    public void setRequesterPatientId(String requesterPatientId) {
        this.requesterPatientId = requesterPatientId;
    }

    public String getRequesterName() {
        return requesterName;
    }

    public void setRequesterName(String requesterName) {
        this.requesterName = requesterName;
    }

    public String getReceiverPatientId() {
        return receiverPatientId;
    }

    public void setReceiverPatientId(String receiverPatientId) {
        this.receiverPatientId = receiverPatientId;
    }

    public String getReceiverName() {
        return receiverName;
    }

    public void setReceiverName(String receiverName) {
        this.receiverName = receiverName;
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

    public String getRequestedAt() {
        return requestedAt;
    }

    public void setRequestedAt(String requestedAt) {
        this.requestedAt = requestedAt;
    }

    public String getConnectedAt() {
        return connectedAt;
    }

    public void setConnectedAt(String connectedAt) {
        this.connectedAt = connectedAt;
    }
}