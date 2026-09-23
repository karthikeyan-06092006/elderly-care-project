package com.elderlycare.backend.controller;

import com.elderlycare.backend.dto.ApiResponse;
import com.elderlycare.backend.entity.HealthcareAssignment;
import com.elderlycare.backend.entity.User;
import com.elderlycare.backend.repository.HealthcareAssignmentRepository;
import com.elderlycare.backend.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.*;

@RestController
@RequestMapping("/api/healthcare")
@CrossOrigin(origins = "*")
public class HealthcareController {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private HealthcareAssignmentRepository assignmentRepository;

    /**
     * Get nearby verified healthcare workers (filtered by state/district)
     */
    @GetMapping("/nearby")
    public ResponseEntity<?> getNearbyHealthcareWorkers(
            @RequestParam(required = false) String state,
            @RequestParam(required = false) String district) {
        try {
            List<User> workers;
            if ((state != null && !state.trim().isEmpty()) || (district != null && !district.trim().isEmpty())) {
                String cleanState = (state != null && !state.trim().isEmpty()) ? state.trim() : null;
                String cleanDistrict = (district != null && !district.trim().isEmpty()) ? district.trim() : null;
                workers = userRepository.findNearbyHealthcareWorkers(cleanState, cleanDistrict);
            } else {
                workers = userRepository.findAllVerifiedHealthcareWorkers();
            }

            List<Map<String, Object>> responseList = new ArrayList<>();
            for (User u : workers) {
                Map<String, Object> map = new HashMap<>();
                map.put("workerId", u.getUserId());
                map.put("fullName", u.getFullName());
                map.put("email", u.getEmail());
                map.put("phone", u.getPhoneNumber());
                map.put("profession", u.getProfession() != null ? u.getProfession() : "DOCTOR");
                map.put("specialization", u.getSpecialization() != null ? u.getSpecialization() : "General Practice");
                map.put("hospitalName", u.getHospitalName() != null ? u.getHospitalName() : "NER Community Health");
                map.put("state", u.getState() != null ? u.getState() : "Assam");
                map.put("district", u.getDistrict() != null ? u.getDistrict() : "Kamrup Metro");
                map.put("stateCouncil", u.getStateCouncil() != null ? u.getStateCouncil() : "Assam Medical Council");
                map.put("registrationNumber", u.getRegistrationNumber() != null ? u.getRegistrationNumber() : "AMC-VERIFIED");
                map.put("verificationStatus", u.getVerificationStatus());
                responseList.add(map);
            }

            return ResponseEntity.ok(ApiResponse.success("Fetched " + responseList.size() + " healthcare workers", responseList));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Failed to fetch healthcare workers: " + e.getMessage()));
        }
    }

    /**
     * Caregiver or Patient requests care assignment from a Doctor/Nurse
     */
    @PostMapping("/request-assignment")
    public ResponseEntity<?> requestAssignment(@RequestBody Map<String, String> body) {
        try {
            String patientId = body.get("patientId");
            String workerId = body.get("workerId");
            String requestedBy = body.get("requestedBy");
            String notes = body.get("notes");

            if (patientId == null || workerId == null) {
                return ResponseEntity.badRequest().body(ApiResponse.error("patientId and workerId are required"));
            }

            Optional<HealthcareAssignment> existing = assignmentRepository.findByPatientIdAndHealthcareWorkerId(patientId, workerId);
            if (existing.isPresent()) {
                HealthcareAssignment a = existing.get();
                if ("ACCEPTED".equalsIgnoreCase(a.getStatus())) {
                    return ResponseEntity.ok(ApiResponse.success("Already connected with this healthcare worker", a));
                } else if ("PENDING".equalsIgnoreCase(a.getStatus())) {
                    return ResponseEntity.ok(ApiResponse.success("Care request is already pending acceptance", a));
                }
            }

            HealthcareAssignment assignment = new HealthcareAssignment();
            assignment.setPatientId(patientId);
            assignment.setHealthcareWorkerId(workerId);
            assignment.setRequestedBy(requestedBy);
            assignment.setStatus("PENDING");
            assignment.setNotes(notes);
            assignment.setCreatedAt(LocalDateTime.now());

            assignmentRepository.save(assignment);
            return ResponseEntity.ok(ApiResponse.success("Care request submitted successfully to healthcare provider", assignment));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Failed to request assignment: " + e.getMessage()));
        }
    }

    /**
     * Doctor/Nurse accepts or declines a patient request
     */
    @PostMapping("/respond-assignment")
    public ResponseEntity<?> respondAssignment(@RequestBody Map<String, Object> body) {
        try {
            Object rawId = body.get("assignmentId");
            String action = (String) body.get("action"); // "ACCEPT" or "REJECT"

            if (rawId == null || action == null) {
                return ResponseEntity.badRequest().body(ApiResponse.error("assignmentId and action are required"));
            }

            Long assignmentId = Long.parseLong(rawId.toString());
            Optional<HealthcareAssignment> opt = assignmentRepository.findById(assignmentId);
            if (opt.isEmpty()) {
                return ResponseEntity.badRequest().body(ApiResponse.error("Assignment request not found"));
            }

            HealthcareAssignment a = opt.get();
            if ("ACCEPT".equalsIgnoreCase(action)) {
                a.setStatus("ACCEPTED");
            } else {
                a.setStatus("REJECTED");
            }
            assignmentRepository.save(a);

            return ResponseEntity.ok(ApiResponse.success("Assignment updated to " + a.getStatus(), a));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Failed to respond to assignment: " + e.getMessage()));
        }
    }

    /**
     * Doctor/Nurse views their list of assigned and pending patients
     */
    @GetMapping("/assigned-patients")
    public ResponseEntity<?> getAssignedPatients(@RequestParam String workerId) {
        try {
            List<HealthcareAssignment> assignments = assignmentRepository.findByHealthcareWorkerId(workerId);
            List<Map<String, Object>> result = new ArrayList<>();

            for (HealthcareAssignment a : assignments) {
                Optional<User> patientOpt = userRepository.findById(a.getPatientId());
                if (patientOpt.isPresent()) {
                    User p = patientOpt.get();
                    Map<String, Object> item = new HashMap<>();
                    item.put("assignmentId", a.getAssignmentId());
                    item.put("status", a.getStatus());
                    item.put("notes", a.getNotes());
                    item.put("patientId", p.getUserId());
                    item.put("fullName", p.getFullName());
                    item.put("age", p.getAge() != null ? p.getAge() : 70);
                    item.put("gender", p.getGender() != null ? p.getGender() : "Not Specified");
                    item.put("phoneNumber", p.getPhoneNumber());
                    item.put("state", p.getState() != null ? p.getState() : "Assam");
                    item.put("district", p.getDistrict() != null ? p.getDistrict() : "Kamrup Metro");
                    item.put("qrCodeToken", p.getQrCodeToken());
                    item.put("createdAt", a.getCreatedAt() != null ? a.getCreatedAt().toString() : "");
                    result.add(item);
                }
            }

            return ResponseEntity.ok(ApiResponse.success("Fetched assigned patients", result));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Failed to get assigned patients: " + e.getMessage()));
        }
    }
}
