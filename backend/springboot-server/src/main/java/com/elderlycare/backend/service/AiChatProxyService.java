package com.elderlycare.backend.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Service
public class AiChatProxyService {

    private static final Logger log = LoggerFactory.getLogger(AiChatProxyService.class);
    private static final String UPSTREAM_URL = "http://127.0.0.1:8000/api/ai/chat";

    private final HttpClient client = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(5))
            .build();
    private final ObjectMapper mapper = new ObjectMapper();

    public Map<String, Object> chat(Map<String, Object> request) {
        try {
            String body = mapper.writeValueAsString(request);
            HttpRequest httpRequest = HttpRequest.newBuilder(URI.create(UPSTREAM_URL))
                    .timeout(Duration.ofSeconds(12))
                    .header("Content-Type", "application/json")
                    .POST(HttpRequest.BodyPublishers.ofString(body))
                    .build();
            HttpResponse<String> response = client.send(httpRequest, HttpResponse.BodyHandlers.ofString());
            if (response.statusCode() == 200) {
                JsonNode node = mapper.readTree(response.body());
                return mapper.convertValue(node, Map.class);
            }
            log.warn("AI chat upstream responded with status {}", response.statusCode());
        } catch (Exception e) {
            log.warn("AI chat upstream unreachable: {}", e.getMessage());
        }
        return localFallback(request);
    }

    private Map<String, Object> localFallback(Map<String, Object> request) {
        String lang = "en";
        if (request.get("language") instanceof String s) {
            lang = "bn".equals(s) ? "bn" : "en";
        }
        String lastUser = "";
        if (request.get("messages") instanceof List<?> list) {
            for (int i = list.size() - 1; i >= 0; i--) {
                if (list.get(i) instanceof Map<?, ?> m
                        && "user".equals(m.get("role"))
                        && m.get("content") != null) {
                    lastUser = m.get("content").toString();
                    break;
                }
            }
        }
        boolean bn = "bn".equals(lang);
        String msg = lastUser.toLowerCase();
        String reply;
        if (msg.contains("hello") || msg.contains("hi") || msg.contains("নমস্কার") || msg.contains("হ্যালো")) {
            reply = bn ? "নমস্কার! কেমন আছেন আপনি? আমি আপনার সাথে গল্প করতে সর্বদা প্রস্তুত।"
                    : "Hello! How are you feeling today? I am always happy to chat with you.";
        } else if (msg.contains("medicine") || msg.contains("pill") || msg.contains("ওষুধ") || msg.contains("ঔষধ")) {
            reply = bn ? "আপনার ওষুধ খাওয়ার সময় হলে যত্নশীল ব্যক্তিকে মনে করিয়ে দিন।"
                    : "Please check your daily reminders for medications, or ask your caregiver.";
        } else if (msg.contains("game") || msg.contains("play") || msg.contains("খেলা") || msg.contains("গেম")) {
            reply = bn ? "মস্তিষ্ক সতেজ রাখতে আমাদের মেমোরি গেম খেলুন, এটি খুব আনন্দদায়ক!"
                    : "Playing our memory game is a great way to keep your mind sharp and active!";
        } else if (msg.contains("time") || msg.contains("clock") || msg.contains("সময়") || msg.contains("বেলা")) {
            reply = bn ? "এখন সময় বেশ সুন্দর। আপনি কি একটু জল খেয়েছেন?"
                    : "It is a wonderful day. Have you had a glass of water recently?";
        } else {
            reply = bn ? "আমি আপনার কথা শুনতে পাচ্ছি। আপনি কেমন বোধ করছেন আমাকে বলুন।"
                    : "I am right here listening to you. Tell me more about how you feel today.";
        }
        Map<String, Object> out = new LinkedHashMap<>();
        out.put("reply", reply);
        out.put("language", bn ? "bn" : "en");
        out.put("mode", "local_fallback");
        return out;
    }
}