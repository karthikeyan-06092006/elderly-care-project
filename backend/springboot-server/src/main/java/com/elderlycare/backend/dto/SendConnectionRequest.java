package com.elderlycare.backend.dto;

import jakarta.validation.constraints.NotBlank;

public class SendConnectionRequest {

    @NotBlank(message = "Receiver patient is required")
    private String receiverPatientId;

    private String requestMessage;

    public String getReceiverPatientId() {
        return receiverPatientId;
    }

    public void setReceiverPatientId(String receiverPatientId) {
        this.receiverPatientId = receiverPatientId;
    }

    public String getRequestMessage() {
        return requestMessage;
    }

    public void setRequestMessage(String requestMessage) {
        this.requestMessage = requestMessage;
    }
}