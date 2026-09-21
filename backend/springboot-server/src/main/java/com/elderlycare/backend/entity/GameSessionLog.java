package com.elderlycare.backend.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "GAME_SESSION_LOGS")
public class GameSessionLog {

    @Id
    @Column(name = "SESSION_ID", length = 36)
    private String id;

    @Column(name = "PATIENT_ID", nullable = false, length = 100)
    private String patientId;

    @Column(name = "PATIENT_NAME", length = 100)
    private String patientName;

    @Column(name = "GAME_TITLE", nullable = false, length = 100)
    private String gameTitle;

    @Column(name = "SCORE", nullable = false)
    private Double score;

    @Column(name = "COMPLETION_TIME_SECONDS", nullable = false)
    private Double completionTimeSeconds;

    @Column(name = "ACCURACY_PERCENTAGE", nullable = false)
    private Double accuracyPercentage;

    @Column(name = "MISTAKES_COUNT", nullable = false)
    private Integer mistakesCount;

    @Column(name = "DIFFICULTY_LEVEL", length = 50)
    private String difficultyLevel;

    @Column(name = "AI_RECOMMENDED_LEVEL", length = 50)
    private String aiRecommendedLevel;

    @Column(name = "AI_CONFIDENCE")
    private Double aiConfidence;

    @Column(name = "PLAYED_AT", nullable = false)
    private LocalDateTime playedAt;

    public GameSessionLog() {
        this.id = UUID.randomUUID().toString();
        this.playedAt = LocalDateTime.now();
    }

    public GameSessionLog(String patientId, String patientName, String gameTitle, Double score,
                          Double completionTimeSeconds, Double accuracyPercentage, Integer mistakesCount,
                          String difficultyLevel, String aiRecommendedLevel, Double aiConfidence) {
        this.id = UUID.randomUUID().toString();
        this.patientId = patientId;
        this.patientName = patientName;
        this.gameTitle = gameTitle;
        this.score = score;
        this.completionTimeSeconds = completionTimeSeconds;
        this.accuracyPercentage = accuracyPercentage;
        this.mistakesCount = mistakesCount;
        this.difficultyLevel = difficultyLevel;
        this.aiRecommendedLevel = aiRecommendedLevel;
        this.aiConfidence = aiConfidence;
        this.playedAt = LocalDateTime.now();
    }

    public String getId() {
        return id;
    }

    public void setId(String id) {
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

    public String getGameTitle() {
        return gameTitle;
    }

    public void setGameTitle(String gameTitle) {
        this.gameTitle = gameTitle;
    }

    public Double getScore() {
        return score;
    }

    public void setScore(Double score) {
        this.score = score;
    }

    public Double getCompletionTimeSeconds() {
        return completionTimeSeconds;
    }

    public void setCompletionTimeSeconds(Double completionTimeSeconds) {
        this.completionTimeSeconds = completionTimeSeconds;
    }

    public Double getAccuracyPercentage() {
        return accuracyPercentage;
    }

    public void setAccuracyPercentage(Double accuracyPercentage) {
        this.accuracyPercentage = accuracyPercentage;
    }

    public Integer getMistakesCount() {
        return mistakesCount;
    }

    public void setMistakesCount(Integer mistakesCount) {
        this.mistakesCount = mistakesCount;
    }

    public String getDifficultyLevel() {
        return difficultyLevel;
    }

    public void setDifficultyLevel(String difficultyLevel) {
        this.difficultyLevel = difficultyLevel;
    }

    public String getAiRecommendedLevel() {
        return aiRecommendedLevel;
    }

    public void setAiRecommendedLevel(String aiRecommendedLevel) {
        this.aiRecommendedLevel = aiRecommendedLevel;
    }

    public Double getAiConfidence() {
        return aiConfidence;
    }

    public void setAiConfidence(Double aiConfidence) {
        this.aiConfidence = aiConfidence;
    }

    public LocalDateTime getPlayedAt() {
        return playedAt;
    }

    public void setPlayedAt(LocalDateTime playedAt) {
        this.playedAt = playedAt;
    }
}
