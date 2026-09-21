package com.elderlycare.backend.repository;

import com.elderlycare.backend.entity.GameSessionLog;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface GameSessionRepository extends JpaRepository<GameSessionLog, String> {
    List<GameSessionLog> findByPatientIdOrderByPlayedAtDesc(String patientId);
    List<GameSessionLog> findByPatientIdAndGameTitleOrderByPlayedAtDesc(String patientId, String gameTitle);
}
