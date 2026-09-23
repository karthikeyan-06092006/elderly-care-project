package com.elderlycare.backend.controller;

import com.elderlycare.backend.dto.ApiResponse;
import com.elderlycare.backend.dto.PatientSummaryDto;
import com.elderlycare.backend.dto.SendConnectionRequest;
import com.elderlycare.backend.dto.SendMessageRequest;
import com.elderlycare.backend.dto.SocialConnectionDto;
import com.elderlycare.backend.dto.SocialMessageDto;
import com.elderlycare.backend.service.SocialService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

@RestController
@RequestMapping("/api/social")
@CrossOrigin(origins = "*")
public class SocialController {

    @Autowired
    private SocialService socialService;

    @PostMapping("/request")
    public ResponseEntity<ApiResponse> sendConnectionRequest(
            @RequestParam String requesterPatientId,
            @Valid @RequestBody SendConnectionRequest request) {
        ApiResponse response = socialService.sendConnectionRequest(requesterPatientId, request);
        return respond(response);
    }

    @PostMapping("/{connectionId}/respond")
    public ResponseEntity<ApiResponse> respondToConnection(
            @PathVariable Long connectionId,
            @RequestParam String patientId,
            @RequestParam boolean accept) {
        ApiResponse response = socialService.respondToConnection(connectionId, patientId, accept);
        return respond(response);
    }

    @PostMapping("/{connectionId}/caretaker-decision")
    public ResponseEntity<ApiResponse> caretakerDecision(
            @PathVariable Long connectionId,
            @RequestParam String caretakerId,
            @RequestParam boolean approve) {
        ApiResponse response = socialService.approveByCaretaker(connectionId, caretakerId, approve);
        return respond(response);
    }

    @GetMapping("/patient/{patientId}/connections")
    public ResponseEntity<List<SocialConnectionDto>> getConnectionsForPatient(@PathVariable String patientId) {
        return ResponseEntity.ok(socialService.getConnectionsForPatient(patientId));
    }

    @GetMapping("/patient/{patientId}/discover")
    public ResponseEntity<List<PatientSummaryDto>> getDiscoverablePatients(@PathVariable String patientId) {
        return ResponseEntity.ok(socialService.getDiscoverablePatients(patientId));
    }

    @GetMapping("/caretaker/{caretakerId}/pending-approvals")
    public ResponseEntity<List<SocialConnectionDto>> getPendingCaretakerApprovals(@PathVariable String caretakerId) {
        return ResponseEntity.ok(socialService.getPendingCaretakerApprovals(caretakerId));
    }

    @GetMapping("/caretaker/{caretakerId}/connections")
    public ResponseEntity<List<SocialConnectionDto>> getConnectedForCaretaker(@PathVariable String caretakerId) {
        return ResponseEntity.ok(socialService.getConnectedForCaretaker(caretakerId));
    }

    @PostMapping("/message")
    public ResponseEntity<ApiResponse> sendMessage(
            @RequestParam String senderId,
            @Valid @RequestBody SendMessageRequest request) {
        ApiResponse response = socialService.sendMessage(senderId, request);
        return respond(response);
    }

    @GetMapping("/{connectionId}/messages")
    public ResponseEntity<List<SocialMessageDto>> getMessages(
            @PathVariable Long connectionId,
            @RequestParam String userId) {
        return ResponseEntity.ok(socialService.getMessages(connectionId, userId));
    }

    @DeleteMapping("/message/{messageId}")
    public ResponseEntity<ApiResponse> deleteMessage(
            @PathVariable Long messageId,
            @RequestParam Long connectionId,
            @RequestParam String userId) {
        ApiResponse response = socialService.deleteMessage(messageId, connectionId, userId);
        return respond(response);
    }

    @PostMapping("/upload")
    public ResponseEntity<ApiResponse> uploadMedia(@RequestParam("file") MultipartFile file) {
        ApiResponse response = socialService.uploadMedia(file);
        return respond(response);
    }

    @PostMapping("/{connectionId}/cancel")
    public ResponseEntity<ApiResponse> cancelConnection(
            @PathVariable Long connectionId,
            @RequestParam String userId) {
        ApiResponse response = socialService.cancelConnection(connectionId, userId);
        return respond(response);
    }

    private ResponseEntity<ApiResponse> respond(ApiResponse response) {
        if (response.isSuccess()) {
            return ResponseEntity.ok(response);
        } else {
            return ResponseEntity.badRequest().body(response);
        }
    }
}