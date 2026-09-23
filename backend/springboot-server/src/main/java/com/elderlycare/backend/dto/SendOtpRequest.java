package com.elderlycare.backend.dto;

public class SendOtpRequest {

    private String email;
    private String phone;
    private String role; // "PATIENT", "CARETAKER", "HEALTHCARE_WORKER"
    private String name;
    private String stateCouncil;
    private String registrationNumber;

    public SendOtpRequest() {
    }

    public SendOtpRequest(String phone) {
        this.phone = phone;
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

    public String getRole() {
        return role;
    }

    public void setRole(String role) {
        this.role = role;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getStateCouncil() {
        return stateCouncil;
    }

    public void setStateCouncil(String stateCouncil) {
        this.stateCouncil = stateCouncil;
    }

    public String getRegistrationNumber() {
        return registrationNumber;
    }

    public void setRegistrationNumber(String registrationNumber) {
        this.registrationNumber = registrationNumber;
    }
}
