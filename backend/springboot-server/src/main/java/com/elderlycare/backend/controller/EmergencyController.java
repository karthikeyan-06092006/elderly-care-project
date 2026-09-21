package com.elderlycare.backend.controller;

import com.elderlycare.backend.dto.ApiResponse;
import com.elderlycare.backend.dto.TriggerSosRequest;
import com.elderlycare.backend.dto.UpdateFcmTokenRequest;
import com.elderlycare.backend.service.EmergencyService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api")
@CrossOrigin(origins = "*")
public class EmergencyController {

    private final EmergencyService emergencyService;

    public EmergencyController(EmergencyService emergencyService) {
        this.emergencyService = emergencyService;
    }

    @PostMapping("/emergency/sos")
    public ResponseEntity<ApiResponse> triggerSos(@RequestBody TriggerSosRequest request) {
        ApiResponse response = emergencyService.triggerSos(request);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/emergency/active/{caretakerId}")
    public ResponseEntity<ApiResponse> getActiveAlerts(@PathVariable String caretakerId) {
        ApiResponse response = emergencyService.getActiveAlertsForCaretaker(caretakerId);
        return ResponseEntity.ok(response);
    }

    @PostMapping("/emergency/resolve/{alertId}")
    public ResponseEntity<ApiResponse> resolveAlert(@PathVariable Long alertId) {
        ApiResponse response = emergencyService.resolveAlert(alertId);
        return ResponseEntity.ok(response);
    }

    @PostMapping("/user/fcm-token")
    public ResponseEntity<ApiResponse> updateFcmToken(@RequestBody UpdateFcmTokenRequest request) {
        ApiResponse response = emergencyService.updateFcmToken(request.getEmail(), request.getFcmToken());
        return ResponseEntity.ok(response);
    }
}
