package com.elderlycare.backend.dto;

public class TriggerSosRequest {
    private String patientEmail;
    private String patientName;
    private String patientPhone;
    private String notes;

    public TriggerSosRequest() {
    }

    public TriggerSosRequest(String patientEmail, String patientName, String patientPhone, String notes) {
        this.patientEmail = patientEmail;
        this.patientName = patientName;
        this.patientPhone = patientPhone;
        this.notes = notes;
    }

    public String getPatientEmail() {
        return patientEmail;
    }

    public void setPatientEmail(String patientEmail) {
        this.patientEmail = patientEmail;
    }

    public String getPatientName() {
        return patientName;
    }

    public void setPatientName(String patientName) {
        this.patientName = patientName;
    }

    public String getPatientPhone() {
        return patientPhone;
    }

    public void setPatientPhone(String patientPhone) {
        this.patientPhone = patientPhone;
    }

    public String getNotes() {
        return notes;
    }

    public void setNotes(String notes) {
        this.notes = notes;
    }
}
