package com.elderlycare.backend.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "REMINDERS")
public class Reminder {

    @Id
    @Column(name = "REMINDER_ID", length = 36)
    private String reminderId;

    @Column(name = "PATIENT_ID", nullable = false, length = 36)
    private String patientId;

    @Column(name = "CREATED_BY", length = 36)
    private String createdBy;

    @Column(name = "TITLE", nullable = false, length = 150)
    private String title;

    @Column(name = "CATEGORY", nullable = false, length = 30)
    private String category; // MEDICINE, FOOD, SLEEP, WATER, APPOINTMENT, OTHER

    @Column(name = "REMINDER_TIME", nullable = false, length = 10)
    private String reminderTime; // "HH:mm" e.g. "08:30" or "13:00"

    @Column(name = "DAYS_OF_WEEK", length = 50)
    private String daysOfWeek; // "DAILY", "MON,WED,FRI", etc.

    @Column(name = "VOICE_MESSAGE", length = 300)
    private String voiceMessage;

    @Column(name = "VOICE_LANGUAGE", length = 10)
    private String voiceLanguage; // "en" or "bn"

    @Column(name = "IS_ACTIVE")
    private Boolean isActive = true;

    @Column(name = "STATUS", length = 20)
    private String status = "PENDING"; // PENDING, TAKEN, SNOOZED, MISSED

    @Column(name = "LAST_TRIGGERED_AT")
    private LocalDateTime lastTriggeredAt;

    @Column(name = "CREATED_AT")
    private LocalDateTime createdAt = LocalDateTime.now();

    public Reminder() {
    }

    public String getReminderId() {
        return reminderId;
    }

    public void setReminderId(String reminderId) {
        this.reminderId = reminderId;
    }

    public String getPatientId() {
        return patientId;
    }

    public void setPatientId(String patientId) {
        this.patientId = patientId;
    }

    public String getCreatedBy() {
        return createdBy;
    }

    public void setCreatedBy(String createdBy) {
        this.createdBy = createdBy;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getCategory() {
        return category;
    }

    public void setCategory(String category) {
        this.category = category;
    }

    public String getReminderTime() {
        return reminderTime;
    }

    public void setReminderTime(String reminderTime) {
        this.reminderTime = reminderTime;
    }

    public String getDaysOfWeek() {
        return daysOfWeek;
    }

    public void setDaysOfWeek(String daysOfWeek) {
        this.daysOfWeek = daysOfWeek;
    }

    public String getVoiceMessage() {
        return voiceMessage;
    }

    public void setVoiceMessage(String voiceMessage) {
        this.voiceMessage = voiceMessage;
    }

    public String getVoiceLanguage() {
        return voiceLanguage;
    }

    public void setVoiceLanguage(String voiceLanguage) {
        this.voiceLanguage = voiceLanguage;
    }

    public Boolean getIsActive() {
        return isActive;
    }

    public void setIsActive(Boolean active) {
        isActive = active;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public LocalDateTime getLastTriggeredAt() {
        return lastTriggeredAt;
    }

    public void setLastTriggeredAt(LocalDateTime lastTriggeredAt) {
        this.lastTriggeredAt = lastTriggeredAt;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
}
