package com.elderlycare.backend.repository;

import com.elderlycare.backend.entity.Reminder;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ReminderRepository extends JpaRepository<Reminder, String> {

    List<Reminder> findByPatientIdOrderByReminderTimeAsc(String patientId);

    List<Reminder> findByCreatedBy(String createdBy);

    @Query("SELECT r FROM Reminder r WHERE r.patientId = :patientId AND r.isActive = true ORDER BY r.reminderTime ASC")
    List<Reminder> findActiveRemindersByPatientId(@Param("patientId") String patientId);

    long countByPatientIdAndCategory(String patientId, String category);
}
