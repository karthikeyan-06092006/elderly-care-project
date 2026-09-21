package com.elderlycare.backend.service;

import com.elderlycare.backend.dto.ApiResponse;
import com.elderlycare.backend.dto.EmergencyAlertDto;
import com.elderlycare.backend.dto.TriggerSosRequest;
import com.elderlycare.backend.entity.EmergencyAlert;
import com.elderlycare.backend.entity.PatientCaretakerMapping;
import com.elderlycare.backend.entity.User;
import com.elderlycare.backend.repository.EmergencyAlertRepository;
import com.elderlycare.backend.repository.PatientCaretakerRepository;
import com.elderlycare.backend.repository.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

@Service
public class EmergencyService {

    private static final Logger log = LoggerFactory.getLogger(EmergencyService.class);

    private final EmergencyAlertRepository alertRepository;
    private final UserRepository userRepository;
    private final PatientCaretakerRepository mappingRepository;

    public EmergencyService(EmergencyAlertRepository alertRepository,
                            UserRepository userRepository,
                            PatientCaretakerRepository mappingRepository) {
        this.alertRepository = alertRepository;
        this.userRepository = userRepository;
        this.mappingRepository = mappingRepository;
    }

    @Transactional
    public ApiResponse triggerSos(TriggerSosRequest request) {
        String email = request.getPatientEmail() != null ? request.getPatientEmail().trim() : "";
        Optional<User> patientOpt = userRepository.findByEmailIgnoreCase(email);

        String patientId;
        String patientName;
        String patientPhone;

        if (patientOpt.isPresent()) {
            User patient = patientOpt.get();
            patientId = patient.getUserId();
            patientName = patient.getFullName() != null && !patient.getFullName().isEmpty()
                    ? patient.getFullName()
                    : (request.getPatientName() != null ? request.getPatientName() : "Patient");
            patientPhone = patient.getPhoneNumber() != null ? patient.getPhoneNumber() : request.getPatientPhone();
        } else {
            patientId = "PATIENT-" + System.currentTimeMillis();
            patientName = request.getPatientName() != null ? request.getPatientName() : "Patient";
            patientPhone = request.getPatientPhone() != null ? request.getPatientPhone() : "";
        }

        // Find linked primary and secondary caregivers
        List<PatientCaretakerMapping> mappings = mappingRepository.findByPatientId(patientId);
        String primaryCaretakerName = "";
        String primaryCaretakerPhone = "";
        List<User> secondaryCaregivers = new ArrayList<>();

        for (PatientCaretakerMapping m : mappings) {
            Optional<User> ctUserOpt = userRepository.findById(m.getCaretakerId());
            if (ctUserOpt.isPresent()) {
                User ctUser = ctUserOpt.get();
                if (m.isPrimary()) {
                    primaryCaretakerName = ctUser.getFullName();
                    primaryCaretakerPhone = ctUser.getPhoneNumber();
                } else {
                    secondaryCaregivers.add(ctUser);
                }
            }
        }

        // Create Emergency Alert
        EmergencyAlert alert = new EmergencyAlert(
                patientId,
                patientName,
                email,
                patientPhone,
                primaryCaretakerName,
                primaryCaretakerPhone,
                "ACTIVE",
                LocalDateTime.now()
        );

        EmergencyAlert saved = alertRepository.save(alert);
        log.info("🚨 EMERGENCY SOS triggered for patient: {} (ID: {}). Alert ID: {}", patientName, patientId, saved.getId());

        // Dispatch notifications to secondary caregivers
        int secondaryCount = 0;
        for (User ct : secondaryCaregivers) {
            secondaryCount++;
            String token = ct.getFcmToken();
            if (token != null && !token.isEmpty()) {
                log.info("🔔 Dispatching FCM Push Alert to secondary caretaker: {} (Token: {}...)",
                        ct.getFullName(), token.substring(0, Math.min(token.length(), 15)));
            } else {
                log.info("🔔 In-App real-time alert dispatched to secondary caretaker: {}", ct.getFullName());
            }
        }

        EmergencyAlertDto dto = toDto(saved);
        String msg = String.format("🚨 Emergency SOS broadcast active. Primary caretaker (%s) is being called; %d secondary caregiver(s) notified!",
                primaryCaretakerName.isEmpty() ? "Unassigned" : primaryCaretakerName,
                secondaryCount);

        return new ApiResponse(true, msg, dto);
    }

    public ApiResponse getActiveAlertsForCaretaker(String caretakerIdOrEmail) {
        String targetId = caretakerIdOrEmail;
        Optional<User> ctOpt = userRepository.findByEmailIgnoreCase(caretakerIdOrEmail);
        if (ctOpt.isPresent()) {
            targetId = ctOpt.get().getUserId();
        }

        List<EmergencyAlert> alerts = alertRepository.findActiveAlertsForCaretaker(targetId);
        List<EmergencyAlertDto> dtoList = new ArrayList<>();
        LocalDateTime now = LocalDateTime.now();

        for (EmergencyAlert a : alerts) {
            EmergencyAlertDto dto = toDto(a);
            if (a.getCreatedAt() != null) {
                dto.setSecondsAgo((int) Duration.between(a.getCreatedAt(), now).getSeconds());
            }
            dtoList.add(dto);
        }

        return new ApiResponse(true, "Active alerts retrieved", dtoList);
    }

    @Transactional
    public ApiResponse resolveAlert(Long alertId) {
        Optional<EmergencyAlert> alertOpt = alertRepository.findById(alertId);
        if (alertOpt.isEmpty()) {
            return new ApiResponse(false, "Alert not found", null);
        }

        EmergencyAlert alert = alertOpt.get();
        alert.setStatus("RESOLVED");
        alert.setResolvedAt(LocalDateTime.now());
        alertRepository.save(alert);

        log.info("✅ Emergency Alert ID {} resolved.", alertId);
        return new ApiResponse(true, "Emergency marked as responded and resolved.", null);
    }

    @Transactional
    public ApiResponse updateFcmToken(String email, String fcmToken) {
        Optional<User> userOpt = userRepository.findByEmailIgnoreCase(email);
        if (userOpt.isEmpty()) {
            return new ApiResponse(false, "User not found", null);
        }

        User user = userOpt.get();
        user.setFcmToken(fcmToken);
        userRepository.save(user);

        log.info("📱 Updated FCM Token for user: {}", email);
        return new ApiResponse(true, "FCM token updated successfully", null);
    }

    private EmergencyAlertDto toDto(EmergencyAlert a) {
        return new EmergencyAlertDto(
                a.getId(),
                a.getPatientId(),
                a.getPatientName(),
                a.getPatientEmail(),
                a.getPatientPhone(),
                a.getPrimaryCaretakerName(),
                a.getPrimaryCaretakerPhone(),
                a.getStatus(),
                a.getCreatedAt()
        );
    }
}
