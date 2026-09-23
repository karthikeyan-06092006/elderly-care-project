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

import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import jakarta.mail.internet.MimeMessage;

@Service
public class OtpService {

    private static final Logger log = LoggerFactory.getLogger(OtpService.class);

    @Autowired
    private OtpTokenRepository otpTokenRepository;

    @Autowired(required = false)
    private JavaMailSender mailSender;

    private final SecureRandom secureRandom = new SecureRandom();

    /**
     * Generates a 6-digit Email OTP.
     * Dispatches via JavaMailSender (free Gmail SMTP) and records cryptographic token.
     */
    @Transactional
    public ApiResponse generateAndSendEmailOtp(SendOtpRequest req) {
        String email = req.getEmail() != null && !req.getEmail().trim().isEmpty()
                ? req.getEmail().trim()
                : (req.getPhone() != null ? req.getPhone().trim() : "");

        if (email.isEmpty()) {
            return ApiResponse.error("Email address is required to receive OTP");
        }

        // 1. Statutory IMR / Council Pre-Check for Healthcare Workers
        if (req.getRole() != null && req.getRole().toUpperCase().contains("HEALTH")) {
            String regNo = req.getRegistrationNumber() != null ? req.getRegistrationNumber().trim() : "";
            String council = req.getStateCouncil() != null ? req.getStateCouncil().trim() : "";

            if (regNo.isEmpty() || regNo.length() < 3) {
                return ApiResponse.error("Invalid IMR / Registration Number. Please provide your statutory medical license number before requesting OTP.");
            }
            if (council.isEmpty()) {
                return ApiResponse.error("Please select your State Medical / Nursing Council.");
            }

            log.info("🩺 [IMR Pre-Check] Professional registration {} with Council {}", regNo, council);
        }

        // 2. Generate 6-digit cryptographic OTP
        int otpInt = 100000 + secureRandom.nextInt(900000);
        String otpCode = String.valueOf(otpInt);

        // 3. Set 5-minute expiration
        LocalDateTime expiresAt = LocalDateTime.now().plusMinutes(5);

        // 4. Save token (using email as recipient key)
        OtpToken token = new OtpToken(email.toLowerCase(), otpCode, expiresAt);
        otpTokenRepository.save(token);

        log.info("📧 [Email OTP Gateway] Dispatching verification code {} to {}", otpCode, email);

        // 5. Dispatch real Email via JavaMailSender asynchronously
        dispatchEmailAsync(email, otpCode);

        return ApiResponse.success("Email verification code sent to " + email, otpCode);
    }

    public ApiResponse generateAndSendPhoneOtp(SendOtpRequest req) {
        return generateAndSendEmailOtp(req);
    }

    private void dispatchEmailAsync(String toEmail, String otpCode) {
        if (mailSender == null) {
            log.info("ℹ️ JavaMailSender bean not initialized; OTP logged to console: {}", otpCode);
            return;
        }

        new Thread(() -> {
            try {
                MimeMessage message = mailSender.createMimeMessage();
                MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");
                helper.setFrom("alonewarrior123456@gmail.com", "CognitiveCare Support");
                helper.setTo(toEmail);
                helper.setSubject("CognitiveCare - Your Verification Code is " + otpCode);

                String html = "<div style='font-family: Arial, sans-serif; max-width: 500px; margin: 0 auto; padding: 20px; border: 1px solid #e2e8f0; border-radius: 12px; background: #ffffff;'>"
                        + "<div style='text-align: center; margin-bottom: 20px;'>"
                        + "<h2 style='color: #0d9488; margin: 0;'>CognitiveCare</h2>"
                        + "<p style='color: #64748b; font-size: 13px; margin-top: 4px;'>AI-Powered Healthcare & Cognitive Support</p>"
                        + "</div>"
                        + "<p style='color: #334155; font-size: 15px;'>Hello,</p>"
                        + "<p style='color: #334155; font-size: 15px;'>Your 6-digit verification code is:</p>"
                        + "<div style='background: #f0fdf4; border: 2px dashed #0d9488; border-radius: 8px; padding: 16px; text-align: center; margin: 20px 0;'>"
                        + "<span style='font-size: 32px; font-weight: bold; letter-spacing: 8px; color: #0f766e;'>" + otpCode + "</span>"
                        + "</div>"
                        + "<p style='color: #64748b; font-size: 13px;'>This code is valid for <strong>5 minutes</strong>. Please do not share it with anyone.</p>"
                        + "<hr style='border: none; border-top: 1px solid #e2e8f0; margin: 20px 0;'/>"
                        + "<p style='color: #94a3b8; font-size: 11px; text-align: center;'>CognitiveCare Redressal & Healthcare System • Free & Open Access</p>"
                        + "</div>";

                helper.setText(html, true);
                mailSender.send(message);
                log.info("✅ [Email Sent Successfully] OTP delivered to {}", toEmail);
            } catch (Exception e) {
                log.warn("⚠️ Failed to deliver email to {}: {}. Token {} is available for verification.", toEmail, e.getMessage(), otpCode);
            }
        }).start();
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
            return ApiResponse.error("Incorrect OTP code. Please enter the valid 6-digit code sent to your email.");
        }

        token.setVerified(true);
        otpTokenRepository.save(token);

        return ApiResponse.success("Email verified successfully!");
    }

    public boolean isEmailVerified(String email) {
        if (email == null || email.trim().isEmpty()) return false;
        List<OtpToken> tokens = otpTokenRepository.findByEmailIgnoreCaseOrderByCreatedAtDesc(email.trim().toLowerCase());
        return !tokens.isEmpty() && tokens.get(0).isVerified();
    }

    public boolean isPhoneVerified(String phone) {
        return isEmailVerified(phone);
    }
}
