package com.elderlycare.backend.controller;

import com.elderlycare.backend.dto.ApiResponse;
import com.elderlycare.backend.dto.LinkPatientRequest;
import com.elderlycare.backend.dto.LinkedCaretakerDto;
import com.elderlycare.backend.dto.LinkedPatientDto;
import com.elderlycare.backend.service.CaretakerService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api")
@CrossOrigin(origins = "*")
public class CaretakerController {

    @Autowired
    private CaretakerService caretakerService;

    @PostMapping("/caretaker/link-patient")
    public ResponseEntity<ApiResponse> linkPatient(@Valid @RequestBody LinkPatientRequest request) {
        ApiResponse response = caretakerService.linkPatient(request);
        if (response.isSuccess()) {
            return ResponseEntity.ok(response);
        } else {
            return ResponseEntity.badRequest().body(response);
        }
    }

    @GetMapping("/caretaker/{caretakerId}/patients")
    public ResponseEntity<List<LinkedPatientDto>> getPatientsForCaretaker(@PathVariable String caretakerId) {
        List<LinkedPatientDto> list = caretakerService.getPatientsForCaretaker(caretakerId);
        return ResponseEntity.ok(list);
    }

    @GetMapping("/patient/{patientId}/caretakers")
    public ResponseEntity<List<LinkedCaretakerDto>> getCaretakersForPatient(@PathVariable String patientId) {
        List<LinkedCaretakerDto> list = caretakerService.getCaretakersForPatient(patientId);
        return ResponseEntity.ok(list);
    }
}
