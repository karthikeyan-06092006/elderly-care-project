package com.elderlycare.backend.dto;

public class UpdateFcmTokenRequest {
    private String email;
    private String fcmToken;

    public UpdateFcmTokenRequest() {
    }

    public UpdateFcmTokenRequest(String email, String fcmToken) {
        this.email = email;
        this.fcmToken = fcmToken;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getFcmToken() {
        return fcmToken;
    }

    public void setFcmToken(String fcmToken) {
        this.fcmToken = fcmToken;
    }
}
