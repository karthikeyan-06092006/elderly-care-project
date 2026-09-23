package com.elderlycare.backend.controller;

import com.elderlycare.backend.service.AiChatProxyService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/ai")
@CrossOrigin(origins = "*")
public class AiCompanionController {

    @Autowired
    private AiChatProxyService aiChatProxyService;

    @PostMapping("/chat")
    public ResponseEntity<Map<String, Object>> chat(@RequestBody Map<String, Object> body) {
        return ResponseEntity.ok(aiChatProxyService.chat(body));
    }
}