package com.elderlycare.backend.controller;

import com.elderlycare.backend.dto.ApiResponse;
import com.elderlycare.backend.entity.User;
import com.elderlycare.backend.repository.EmergencyAlertRepository;
import com.elderlycare.backend.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.*;

@RestController
@RequestMapping("/api/admin")
@CrossOrigin(origins = "*")
public class AdminController {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private EmergencyAlertRepository emergencyAlertRepository;

    /**
     * Get all pending healthcare workers waiting for verification
     */
    @GetMapping("/pending-workers")
    public ResponseEntity<?> getPendingWorkers() {
        try {
            List<User> pendingWorkers = userRepository.findByRoleAndVerificationStatus("HEALTHCARE_WORKER", "PENDING");
            List<Map<String, Object>> list = new ArrayList<>();
            for (User u : pendingWorkers) {
                Map<String, Object> map = new HashMap<>();
                map.put("userId", u.getUserId());
                map.put("fullName", u.getFullName());
                map.put("email", u.getEmail());
                map.put("phone", u.getPhoneNumber());
                map.put("profession", u.getProfession());
                map.put("specialization", u.getSpecialization());
                map.put("hospitalName", u.getHospitalName());
                map.put("stateCouncil", u.getStateCouncil());
                map.put("registrationNumber", u.getRegistrationNumber());
                map.put("nuid", u.getNuid());
                map.put("state", u.getState());
                map.put("district", u.getDistrict());
                map.put("verificationStatus", u.getVerificationStatus());
                map.put("createdAt", u.getCreatedAt() != null ? u.getCreatedAt().toString() : "");
                list.add(map);
            }
            return ResponseEntity.ok(ApiResponse.success("Fetched pending healthcare workers", list));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Failed to fetch pending workers: " + e.getMessage()));
        }
    }

    /**
     * Admin approves or rejects a healthcare worker registration
     */
    @PostMapping("/verify-worker")
    public ResponseEntity<?> verifyWorker(@RequestBody Map<String, String> body) {
        try {
            String userId = body.get("userId");
            String status = body.get("status"); // "APPROVED" or "REJECTED"
            String reason = body.get("reason");

            if (userId == null || status == null) {
                return ResponseEntity.badRequest().body(ApiResponse.error("userId and status are required"));
            }

            Optional<User> opt = userRepository.findById(userId);
            if (opt.isEmpty()) {
                return ResponseEntity.badRequest().body(ApiResponse.error("User not found"));
            }

            User user = opt.get();
            user.setVerificationStatus(status.trim().toUpperCase());
            userRepository.save(user);

            return ResponseEntity.ok(ApiResponse.success("Healthcare worker status updated to " + user.getVerificationStatus(), user));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Failed to update verification: " + e.getMessage()));
        }
    }

    /**
     * Overall platform statistics for admin dashboard
     */
    @GetMapping("/stats")
    public ResponseEntity<?> getStats() {
        try {
            long totalPatients = userRepository.countByRole("PATIENT");
            long totalCaretakers = userRepository.countByRole("CARETAKER");
            long verifiedDoctors = userRepository.countByRoleAndVerificationStatus("HEALTHCARE_WORKER", "APPROVED");
            long pendingVerifications = userRepository.countByRoleAndVerificationStatus("HEALTHCARE_WORKER", "PENDING");
            long activeEmergencyAlerts = emergencyAlertRepository.countActiveAlerts();

            Map<String, Object> stats = new HashMap<>();
            stats.put("totalPatients", totalPatients);
            stats.put("totalCaretakers", totalCaretakers);
            stats.put("verifiedDoctors", verifiedDoctors);
            stats.put("pendingVerifications", pendingVerifications);
            stats.put("activeEmergencyAlerts", activeEmergencyAlerts);

            return ResponseEntity.ok(ApiResponse.success("System statistics loaded", stats));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Failed to load stats: " + e.getMessage()));
        }
    }
}
