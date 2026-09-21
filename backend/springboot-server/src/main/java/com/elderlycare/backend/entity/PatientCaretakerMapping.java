package com.elderlycare.backend.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "PATIENT_CARETAKER_MAPPINGS", uniqueConstraints = {
    @UniqueConstraint(columnNames = {"PATIENT_ID", "CARETAKER_ID"})
})
public class PatientCaretakerMapping {

    @Id
    @GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "mapping_seq_gen")
    @SequenceGenerator(name = "mapping_seq_gen", sequenceName = "MAPPING_SEQ", allocationSize = 1)
    @Column(name = "ID")
    private Long id;

    @Column(name = "PATIENT_ID", nullable = false, length = 36)
    private String patientId;

    @Column(name = "CARETAKER_ID", nullable = false, length = 36)
    private String caretakerId;

    @Column(name = "RELATION", nullable = false, length = 50)
    private String relation; // e.g. "Primary Caregiver", "Son", "Family Physician", "Assisting Nurse"

    @Column(name = "IS_PRIMARY", nullable = false)
    private boolean isPrimary;

    @Column(name = "LINKED_AT")
    private LocalDateTime linkedAt;

    public PatientCaretakerMapping() {
    }

    public PatientCaretakerMapping(String patientId, String caretakerId, String relation, boolean isPrimary, LocalDateTime linkedAt) {
        this.patientId = patientId;
        this.caretakerId = caretakerId;
        this.relation = relation;
        this.isPrimary = isPrimary;
        this.linkedAt = linkedAt;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getPatientId() {
        return patientId;
    }

    public void setPatientId(String patientId) {
        this.patientId = patientId;
    }

    public String getCaretakerId() {
        return caretakerId;
    }

    public void setCaretakerId(String caretakerId) {
        this.caretakerId = caretakerId;
    }

    public String getRelation() {
        return relation;
    }

    public void setRelation(String relation) {
        this.relation = relation;
    }

    public boolean isPrimary() {
        return isPrimary;
    }

    public void setPrimary(boolean primary) {
        isPrimary = primary;
    }

    public LocalDateTime getLinkedAt() {
        return linkedAt;
    }

    public void setLinkedAt(LocalDateTime linkedAt) {
        this.linkedAt = linkedAt;
    }
}
