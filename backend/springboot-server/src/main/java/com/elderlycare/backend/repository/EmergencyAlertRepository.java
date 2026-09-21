package com.elderlycare.backend.repository;

import com.elderlycare.backend.entity.EmergencyAlert;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface EmergencyAlertRepository extends JpaRepository<EmergencyAlert, Long> {

    @Query("SELECT a FROM EmergencyAlert a WHERE a.status = 'ACTIVE' ORDER BY a.createdAt DESC")
    List<EmergencyAlert> findAllActiveAlerts();

    @Query("SELECT a FROM EmergencyAlert a WHERE a.patientId = :patientId AND a.status = 'ACTIVE' ORDER BY a.createdAt DESC")
    List<EmergencyAlert> findActiveAlertsByPatientId(@Param("patientId") String patientId);

    @Query("SELECT a FROM EmergencyAlert a WHERE a.patientId IN (SELECT m.patientId FROM PatientCaretakerMapping m WHERE m.caretakerId = :caretakerId) AND a.status = 'ACTIVE' ORDER BY a.createdAt DESC")
    List<EmergencyAlert> findActiveAlertsForCaretaker(@Param("caretakerId") String caretakerId);
}
