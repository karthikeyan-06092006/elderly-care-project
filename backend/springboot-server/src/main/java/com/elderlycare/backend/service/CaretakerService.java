package com.elderlycare.backend.service;

import com.elderlycare.backend.dto.ApiResponse;
import com.elderlycare.backend.dto.LinkPatientRequest;
import com.elderlycare.backend.dto.LinkedCaretakerDto;
import com.elderlycare.backend.dto.LinkedPatientDto;
import com.elderlycare.backend.entity.PatientCaretakerMapping;
import com.elderlycare.backend.entity.User;
import com.elderlycare.backend.repository.PatientCaretakerRepository;
import com.elderlycare.backend.repository.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

@Service
public class CaretakerService {

    private static final Logger log = LoggerFactory.getLogger(CaretakerService.class);
    private static final DateTimeFormatter DATE_FORMATTER = DateTimeFormatter.ofPattern("dd MMMM yyyy");

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PatientCaretakerRepository patientCaretakerRepository;

    @Transactional
    public ApiResponse linkPatient(LinkPatientRequest req) {
        // 1. Validate caretaker
        Optional<User> caretakerOpt = userRepository.findById(req.getCaretakerId());
        if (caretakerOpt.isEmpty()) {
            return ApiResponse.error("Caretaker account not found.");
        }
        User caretaker = caretakerOpt.get();

        // 2. Validate patient by QR Token
        String token = req.getPatientQrToken().trim();
        Optional<User> patientOpt = userRepository.findByQrCodeTokenIgnoreCase(token);
        if (patientOpt.isEmpty()) {
            // Also try looking up by direct user ID or email in case the token was typed
            patientOpt = userRepository.findById(token);
            if (patientOpt.isEmpty()) {
                patientOpt = userRepository.findByEmailIgnoreCase(token);
            }
        }

        if (patientOpt.isEmpty()) {
            return ApiResponse.error("Patient not found for scanned QR code: " + token);
        }

        User patient = patientOpt.get();

        if (patient.getUserId().equals(caretaker.getUserId())) {
            return ApiResponse.error("You cannot link yourself as your own patient.");
        }

        String relation = (req.getRelation() != null && !req.getRelation().trim().isEmpty())
                ? req.getRelation().trim()
                : "Primary Caregiver";

        boolean makePrimary = req.getIsPrimary() != null ? req.getIsPrimary() : false;

        // Check existing mappings for this patient
        List<PatientCaretakerMapping> existingPatientMappings = patientCaretakerRepository.findByPatientId(patient.getUserId());
        if (existingPatientMappings.isEmpty()) {
            // If this is the very first caretaker for this patient, make them primary automatically
            makePrimary = true;
        }

        if (makePrimary) {
            patientCaretakerRepository.clearPrimaryForPatient(patient.getUserId());
        }

        // 3. Save or update mapping
        Optional<PatientCaretakerMapping> existingMapping = patientCaretakerRepository
                .findByPatientIdAndCaretakerId(patient.getUserId(), caretaker.getUserId());

        PatientCaretakerMapping mapping;
        if (existingMapping.isPresent()) {
            mapping = existingMapping.get();
            mapping.setRelation(relation);
            mapping.setPrimary(makePrimary);
        } else {
            mapping = new PatientCaretakerMapping(
                    patient.getUserId(),
                    caretaker.getUserId(),
                    relation,
                    makePrimary,
                    LocalDateTime.now()
            );
        }

        patientCaretakerRepository.save(mapping);
        log.info("✅ Linked Caretaker {} ({}) with Patient {} ({}) - Relation: {}",
                caretaker.getFullName(), caretaker.getEmail(),
                patient.getFullName(), patient.getEmail(),
                relation);

        String linkedDateStr = mapping.getLinkedAt() != null
                ? mapping.getLinkedAt().format(DATE_FORMATTER)
                : LocalDateTime.now().format(DATE_FORMATTER);

        LinkedPatientDto dto = new LinkedPatientDto(
                patient.getUserId(),
                patient.getFullName(),
                patient.getEmail(),
                patient.getPhoneNumber(),
                patient.getQrCodeToken(),
                relation,
                makePrimary,
                linkedDateStr
        );

        return ApiResponse.ok("Successfully linked patient: " + patient.getFullName(), dto);
    }

    public List<LinkedPatientDto> getPatientsForCaretaker(String caretakerId) {
        List<PatientCaretakerMapping> mappings = patientCaretakerRepository.findByCaretakerId(caretakerId);
        List<LinkedPatientDto> result = new ArrayList<>();

        for (PatientCaretakerMapping m : mappings) {
            Optional<User> patientOpt = userRepository.findById(m.getPatientId());
            if (patientOpt.isPresent()) {
                User patient = patientOpt.get();
                String dateStr = m.getLinkedAt() != null ? m.getLinkedAt().format(DATE_FORMATTER) : "";
                result.add(new LinkedPatientDto(
                        patient.getUserId(),
                        patient.getFullName(),
                        patient.getEmail(),
                        patient.getPhoneNumber(),
                        patient.getQrCodeToken(),
                        m.getRelation(),
                        m.isPrimary(),
                        dateStr
                ));
            }
        }
        return result;
    }

    public List<LinkedCaretakerDto> getCaretakersForPatient(String patientIdOrEmail) {
        String cleanId = patientIdOrEmail.trim();
        Optional<User> patientOpt = userRepository.findById(cleanId);
        if (patientOpt.isEmpty()) {
            patientOpt = userRepository.findByEmailIgnoreCase(cleanId);
        }

        if (patientOpt.isEmpty()) {
            return List.of();
        }

        User patient = patientOpt.get();
        List<PatientCaretakerMapping> mappings = patientCaretakerRepository.findByPatientId(patient.getUserId());
        List<LinkedCaretakerDto> result = new ArrayList<>();

        for (PatientCaretakerMapping m : mappings) {
            Optional<User> caretakerOpt = userRepository.findById(m.getCaretakerId());
            if (caretakerOpt.isPresent()) {
                User caretaker = caretakerOpt.get();
                String dateStr = m.getLinkedAt() != null ? m.getLinkedAt().format(DATE_FORMATTER) : "";
                result.add(new LinkedCaretakerDto(
                        caretaker.getUserId(),
                        caretaker.getFullName(),
                        caretaker.getEmail(),
                        caretaker.getPhoneNumber(),
                        m.getRelation(),
                        m.isPrimary(),
                        dateStr
                ));
            }
        }
        return result;
    }
}
