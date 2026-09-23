package com.elderlycare.backend.dto;

import jakarta.validation.constraints.NotBlank;

public class VerifyOtpRequest {

    private String email;
    private String phone;

    @NotBlank(message = "OTP code is required")
    private String otp;

    public VerifyOtpRequest() {
    }

    public VerifyOtpRequest(String phone, String otp) {
        this.phone = phone;
        this.otp = otp;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getPhone() {
        return phone;
    }

    public void setPhone(String phone) {
        this.phone = phone;
    }

    public String getOtp() {
        return otp;
    }

    public void setOtp(String otp) {
        this.otp = otp;
    }
}
