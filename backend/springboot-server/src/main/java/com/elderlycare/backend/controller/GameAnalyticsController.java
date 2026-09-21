package com.elderlycare.backend.controller;

import com.elderlycare.backend.dto.ApiResponse;
import com.elderlycare.backend.dto.GameSessionDto;
import com.elderlycare.backend.entity.GameSessionLog;
import com.elderlycare.backend.repository.GameSessionRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/analytics")
@CrossOrigin(origins = "*")
public class GameAnalyticsController {

    @Autowired
    private GameSessionRepository gameSessionRepository;

    @PostMapping("/game-session")
    public ResponseEntity<ApiResponse> recordGameSession(@RequestBody GameSessionDto request) {
        GameSessionLog log = new GameSessionLog(
                request.getPatientId() != null ? request.getPatientId() : "patient-default",
                request.getPatientName() != null ? request.getPatientName() : "Patient",
                request.getGameTitle() != null ? request.getGameTitle() : "Cognitive Game",
                request.getScore() != null ? request.getScore() : 0.0,
                request.getCompletionTimeSeconds() != null ? request.getCompletionTimeSeconds() : 0.0,
                request.getAccuracyPercentage() != null ? request.getAccuracyPercentage() : 0.0,
                request.getMistakesCount() != null ? request.getMistakesCount() : 0,
                request.getDifficultyLevel() != null ? request.getDifficultyLevel() : "Normal",
                request.getAiRecommendedLevel() != null ? request.getAiRecommendedLevel() : "Normal",
                request.getAiConfidence() != null ? request.getAiConfidence() : 0.0
        );

        if (request.getPlayedAt() != null) {
            log.setPlayedAt(request.getPlayedAt());
        }

        GameSessionLog saved = gameSessionRepository.save(log);

        GameSessionDto responseDto = mapToDto(saved);
        return ResponseEntity.ok(ApiResponse.ok("Game session recorded successfully", responseDto));
    }

    @GetMapping("/patient/{patientId}")
    public ResponseEntity<ApiResponse> getPatientSessions(@PathVariable String patientId) {
        List<GameSessionLog> logs = gameSessionRepository.findByPatientIdOrderByPlayedAtDesc(patientId);
        List<GameSessionDto> dtoList = logs.stream().limit(30).map(this::mapToDto).collect(Collectors.toList());
        return ResponseEntity.ok(ApiResponse.ok("Patient game sessions fetched successfully", dtoList));
    }

    private GameSessionDto mapToDto(GameSessionLog log) {
        GameSessionDto dto = new GameSessionDto();
        dto.setId(log.getId());
        dto.setPatientId(log.getPatientId());
        dto.setPatientName(log.getPatientName());
        dto.setGameTitle(log.getGameTitle());
        dto.setScore(log.getScore());
        dto.setCompletionTimeSeconds(log.getCompletionTimeSeconds());
        dto.setAccuracyPercentage(log.getAccuracyPercentage());
        dto.setMistakesCount(log.getMistakesCount());
        dto.setDifficultyLevel(log.getDifficultyLevel());
        dto.setAiRecommendedLevel(log.getAiRecommendedLevel());
        dto.setAiConfidence(log.getAiConfidence());
        dto.setPlayedAt(log.getPlayedAt());
        return dto;
    }
}
