package com.elderlycare.backend.dto;

import java.time.LocalDateTime;

public class GameSessionDto {
    private String id;
    private String patientId;
    private String patientName;
    private String gameTitle;
    private Double score;
    private Double completionTimeSeconds;
    private Double accuracyPercentage;
    private Integer mistakesCount;
    private String difficultyLevel;
    private String aiRecommendedLevel;
    private Double aiConfidence;
    private LocalDateTime playedAt;

    public GameSessionDto() {}

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
