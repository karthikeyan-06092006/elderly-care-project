package com.elderlycare.backend.repository;

import com.elderlycare.backend.entity.HealthcareAssignment;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface HealthcareAssignmentRepository extends JpaRepository<HealthcareAssignment, Long> {

    List<HealthcareAssignment> findByHealthcareWorkerId(String healthcareWorkerId);

    List<HealthcareAssignment> findByHealthcareWorkerIdAndStatus(String healthcareWorkerId, String status);

    List<HealthcareAssignment> findByPatientId(String patientId);

    List<HealthcareAssignment> findByPatientIdAndStatus(String patientId, String status);

    Optional<HealthcareAssignment> findByPatientIdAndHealthcareWorkerId(String patientId, String healthcareWorkerId);
}
