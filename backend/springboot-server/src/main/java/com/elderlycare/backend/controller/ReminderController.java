package com.elderlycare.backend.controller;

import com.elderlycare.backend.dto.ApiResponse;
import com.elderlycare.backend.entity.Reminder;
import com.elderlycare.backend.repository.ReminderRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@RestController
@RequestMapping("/api/reminders")
@CrossOrigin(origins = "*")
public class ReminderController {

    @Autowired
    private ReminderRepository reminderRepository;

    @Autowired
    private com.elderlycare.backend.repository.UserRepository userRepository;

    /**
     * Get all active and configured reminders for a patient
     */
    @GetMapping("/patient/{patientId}")
    public ResponseEntity<?> getRemindersForPatient(@PathVariable String patientId) {
        try {
            List<Reminder> list = reminderRepository.findByPatientIdOrderByReminderTimeAsc(patientId);
            if (list.isEmpty()) {
                // If patientId is a userId, check by user's email, or vice versa
                var userOpt = userRepository.findById(patientId);
                if (userOpt.isPresent()) {
                    list = reminderRepository.findByPatientIdOrderByReminderTimeAsc(userOpt.get().getEmail());
                } else {
                    var userByEmail = userRepository.findByEmailIgnoreCase(patientId);
                    if (userByEmail.isPresent()) {
                        list = reminderRepository.findByPatientIdOrderByReminderTimeAsc(userByEmail.get().getUserId());
                    }
                }
            }
            return ResponseEntity.ok(ApiResponse.success("Patient reminders fetched successfully", list));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Failed to fetch reminders: " + e.getMessage()));
        }
    }

    /**
     * Create or schedule a new reminder / alarm (by patient or caretaker)
     */
    @PostMapping
    public ResponseEntity<?> createReminder(@RequestBody Reminder reminder) {
        try {
            if (reminder.getPatientId() == null || reminder.getPatientId().trim().isEmpty()) {
                return ResponseEntity.badRequest().body(ApiResponse.error("patientId is required"));
            }
            if (reminder.getTitle() == null || reminder.getTitle().trim().isEmpty()) {
                return ResponseEntity.badRequest().body(ApiResponse.error("title is required"));
            }
            if (reminder.getReminderTime() == null || reminder.getReminderTime().trim().isEmpty()) {
                return ResponseEntity.badRequest().body(ApiResponse.error("reminderTime is required (e.g. 08:30)"));
            }

            if (reminder.getReminderId() == null || reminder.getReminderId().trim().isEmpty()) {
                reminder.setReminderId(UUID.randomUUID().toString());
            }

            if (reminder.getCategory() == null || reminder.getCategory().trim().isEmpty()) {
                reminder.setCategory("MEDICINE");
            } else {
                reminder.setCategory(reminder.getCategory().trim().toUpperCase());
            }

            if (reminder.getDaysOfWeek() == null || reminder.getDaysOfWeek().trim().isEmpty()) {
                reminder.setDaysOfWeek("DAILY");
            }

            if (reminder.getVoiceLanguage() == null || reminder.getVoiceLanguage().trim().isEmpty()) {
                reminder.setVoiceLanguage("en");
            }

            // Generate default voice announcement message if not supplied
            if (reminder.getVoiceMessage() == null || reminder.getVoiceMessage().trim().isEmpty()) {
                boolean isBn = "bn".equalsIgnoreCase(reminder.getVoiceLanguage());
                String cat = reminder.getCategory();
                if (cat.contains("MED")) {
                    reminder.setVoiceMessage(isBn ? "ওষুধ খাওয়ার সময় হয়েছে। দয়া করে আপনার ওষুধ খান।" : "It is time for your medicine: " + reminder.getTitle());
                } else if (cat.contains("FOOD")) {
                    reminder.setVoiceMessage(isBn ? "খাবার খাওয়ার সময় হয়েছে।" : "It is meal time: " + reminder.getTitle());
                } else if (cat.contains("SLEEP")) {
                    reminder.setVoiceMessage(isBn ? "ঘুমানোর সময় হয়েছে। শুভ রাত্রি।" : "Time for bed. Have a good rest!");
                } else if (cat.contains("WATER")) {
                    reminder.setVoiceMessage(isBn ? "জল পান করার সময় হয়েছে।" : "Time to drink a glass of water!");
                } else {
                    reminder.setVoiceMessage(isBn ? "আপনার একটি রিমাইন্ডার আছে: " + reminder.getTitle() : "Reminder: " + reminder.getTitle());
                }
            }

            if (reminder.getIsActive() == null) {
                reminder.setIsActive(true);
            }
            reminder.setStatus("PENDING");
            reminder.setCreatedAt(LocalDateTime.now());

            Reminder saved = reminderRepository.save(reminder);
            return ResponseEntity.ok(ApiResponse.success("Reminder alarm scheduled successfully", saved));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Failed to create reminder: " + e.getMessage()));
        }
    }

    /**
     * Update reminder status (e.g. TAKEN, SNOOZED, MISSED) or toggle active
     */
    @PutMapping("/{reminderId}/status")
    public ResponseEntity<?> updateStatus(
            @PathVariable String reminderId,
            @RequestParam(required = false) String status,
            @RequestParam(required = false) Boolean active) {
        try {
            Optional<Reminder> opt = reminderRepository.findById(reminderId);
            if (opt.isEmpty()) {
                return ResponseEntity.badRequest().body(ApiResponse.error("Reminder not found"));
            }

            Reminder reminder = opt.get();
            if (status != null && !status.trim().isEmpty()) {
                reminder.setStatus(status.trim().toUpperCase());
                reminder.setLastTriggeredAt(LocalDateTime.now());
            }
            if (active != null) {
                reminder.setIsActive(active);
            }

            Reminder saved = reminderRepository.save(reminder);
            return ResponseEntity.ok(ApiResponse.success("Reminder status updated", saved));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Failed to update status: " + e.getMessage()));
        }
    }

    /**
     * Delete a reminder
     */
    @DeleteMapping("/{reminderId}")
    public ResponseEntity<?> deleteReminder(@PathVariable String reminderId) {
        try {
            if (!reminderRepository.existsById(reminderId)) {
                return ResponseEntity.badRequest().body(ApiResponse.error("Reminder not found"));
            }
            reminderRepository.deleteById(reminderId);
            return ResponseEntity.ok(ApiResponse.success("Reminder deleted successfully", null));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Failed to delete reminder: " + e.getMessage()));
        }
    }
}
