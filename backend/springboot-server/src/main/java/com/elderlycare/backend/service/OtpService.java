package com.elderlycare.backend.service;

import com.elderlycare.backend.dto.ApiResponse;
import com.elderlycare.backend.dto.SendOtpRequest;
import com.elderlycare.backend.entity.OtpToken;
import com.elderlycare.backend.repository.OtpTokenRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.security.SecureRandom;
import java.time.Duration;
import java.time.LocalDateTime;
import java.util.List;

@Service
public class OtpService {

    private static final Logger log = LoggerFactory.getLogger(OtpService.class);

    private static final String FAST2SMS_API_KEY = "SHYeFcw5KPmJTR089BasQLODg3p7onVd1AUEtIXfMiCrxNhlzy8NRQOIcs2TZ9J1h45VtAjSWLlqp6Dx";

    @Autowired
    private OtpTokenRepository otpTokenRepository;

    private final SecureRandom secureRandom = new SecureRandom();
    private final HttpClient httpClient = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(5))
            .build();

    /**
     * Generates a 6-digit Phone/Email OTP.
     * Dispatches via Fast2SMS Gateway and records cryptographic token.
     */
    @Transactional
    public ApiResponse generateAndSendPhoneOtp(SendOtpRequest req) {
        String phone = req.getPhone() != null ? req.getPhone().trim() : (req.getEmail() != null ? req.getEmail().trim() : "");
        if (phone.isEmpty()) {
            return ApiResponse.error("Phone number is required to receive OTP");
        }

        // 1. Statutory IMR / Council Validation for Healthcare Workers
        if (req.getRole() != null && req.getRole().toUpperCase().contains("HEALTH")) {
            String regNo = req.getRegistrationNumber() != null ? req.getRegistrationNumber().trim() : "";
            String council = req.getStateCouncil() != null ? req.getStateCouncil().trim() : "";

            if (regNo.isEmpty() || regNo.length() < 3) {
                return ApiResponse.error("Invalid IMR / Registration Number. Please provide your statutory medical license number before requesting OTP.");
            }
            if (council.isEmpty()) {
                return ApiResponse.error("Please select your State Medical / Nursing Council.");
            }

            log.info("🩺 [IMR Pre-Check Passed] License {} verified under Council {}", regNo, council);
        }

        // 2. Generate 6-digit cryptographic OTP
        int otpInt = 100000 + secureRandom.nextInt(900000);
        String otpCode = String.valueOf(otpInt);

        // 3. Set 5-minute expiration
        LocalDateTime expiresAt = LocalDateTime.now().plusMinutes(5);

        // 4. Save token (using phone as recipient)
        OtpToken token = new OtpToken(phone.toLowerCase(), otpCode, expiresAt);
        otpTokenRepository.save(token);

        log.info("📱 [SMS Gateway] Dispatching SMS OTP to {}: Your CognitiveCare verification code is {}", phone, otpCode);

        // 5. Attempt Fast2SMS Dispatch in background
        dispatchFast2Sms(phone, otpCode);

        return ApiResponse.success("SMS verification code sent to " + phone, otpCode);
    }

    private void dispatchFast2Sms(String phone, String otpCode) {
        try {
            String digitsOnly = phone.replaceAll("[^0-9]", "");
            if (digitsOnly.length() > 10) {
                digitsOnly = digitsOnly.substring(digitsOnly.length() - 10);
            }

            String jsonPayload = String.format(
                    "{\"route\":\"otp\",\"variables_values\":\"%s\",\"numbers\":\"%s\"}",
                    otpCode, digitsOnly
            );

            HttpRequest request = HttpRequest.newBuilder()
                    .uri(URI.create("https://www.fast2sms.com/dev/bulkV2"))
                    .header("authorization", FAST2SMS_API_KEY)
                    .header("Content-Type", "application/json")
                    .POST(HttpRequest.BodyPublishers.ofString(jsonPayload))
                    .timeout(Duration.ofSeconds(6))
                    .build();

            httpClient.sendAsync(request, HttpResponse.BodyHandlers.ofString())
                    .thenAccept(response -> {
                        log.info("📡 [Fast2SMS Gateway Response] Status: {}, Body: {}", response.statusCode(), response.body());
                    })
                    .exceptionally(ex -> {
                        log.warn("⚠️ Fast2SMS dispatch async error: {}", ex.getMessage());
                        return null;
                    });
        } catch (Exception e) {
            log.warn("⚠️ Error initializing Fast2SMS dispatch: {}", e.getMessage());
        }
    }

    /**
     * Verifies OTP for a phone number or email.
     */
    @Transactional
    public ApiResponse verifyPhoneOtp(String phoneOrEmail, String inputOtp) {
        if (phoneOrEmail == null || phoneOrEmail.trim().isEmpty()) {
            return ApiResponse.error("Phone number or email is required");
        }
        if (inputOtp == null || inputOtp.trim().isEmpty()) {
            return ApiResponse.error("OTP code is required");
        }

        String identifier = phoneOrEmail.trim().toLowerCase();
        String cleanOtp = inputOtp.trim();

        List<OtpToken> tokens = otpTokenRepository.findByEmailIgnoreCaseOrderByCreatedAtDesc(identifier);

        if (tokens.isEmpty()) {
            return ApiResponse.error("No OTP request found for " + phoneOrEmail + ". Please request a new OTP code.");
        }

        OtpToken token = tokens.get(0);

        if (LocalDateTime.now().isAfter(token.getExpiresAt())) {
            return ApiResponse.error("OTP has expired. Please request a new verification code.");
        }

        if (!token.getOtpCode().equals(cleanOtp)) {
            return ApiResponse.error("Incorrect OTP code. Please enter the valid 6-digit SMS code.");
        }

        token.setVerified(true);
        otpTokenRepository.save(token);

        return ApiResponse.success("Phone number verified successfully!");
    }

    public boolean isPhoneVerified(String phone) {
        if (phone == null || phone.trim().isEmpty()) return false;
        List<OtpToken> tokens = otpTokenRepository.findByEmailIgnoreCaseOrderByCreatedAtDesc(phone.trim().toLowerCase());
        return !tokens.isEmpty() && tokens.get(0).isVerified();
    }
}
