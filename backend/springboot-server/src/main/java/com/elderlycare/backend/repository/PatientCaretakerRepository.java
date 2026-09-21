package com.elderlycare.backend.repository;

import com.elderlycare.backend.entity.PatientCaretakerMapping;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface PatientCaretakerRepository extends JpaRepository<PatientCaretakerMapping, Long> {

    @Query("SELECT m FROM PatientCaretakerMapping m WHERE m.patientId = :patientId ORDER BY m.isPrimary DESC, m.linkedAt ASC")
    List<PatientCaretakerMapping> findByPatientId(@Param("patientId") String patientId);

    @Query("SELECT m FROM PatientCaretakerMapping m WHERE m.caretakerId = :caretakerId ORDER BY m.linkedAt DESC")
    List<PatientCaretakerMapping> findByCaretakerId(@Param("caretakerId") String caretakerId);

    @Query("SELECT m FROM PatientCaretakerMapping m WHERE m.patientId = :patientId AND m.caretakerId = :caretakerId")
    Optional<PatientCaretakerMapping> findByPatientIdAndCaretakerId(
            @Param("patientId") String patientId,
            @Param("caretakerId") String caretakerId
    );

    @Modifying
    @Query("UPDATE PatientCaretakerMapping m SET m.isPrimary = false WHERE m.patientId = :patientId")
    void clearPrimaryForPatient(@Param("patientId") String patientId);
}
