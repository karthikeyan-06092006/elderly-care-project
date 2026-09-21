package com.elderlycare.backend.service;

import com.elderlycare.backend.dto.ApiResponse;
import com.elderlycare.backend.entity.OtpToken;
import com.elderlycare.backend.repository.OtpTokenRepository;
import jakarta.mail.MessagingException;
import jakarta.mail.internet.MimeMessage;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.SecureRandom;
import java.time.LocalDateTime;
import java.util.Optional;

@Service
public class OtpService {

    private static final Logger log = LoggerFactory.getLogger(OtpService.class);

    @Autowired
    private OtpTokenRepository otpTokenRepository;

    @Autowired
    private JavaMailSender mailSender;

    @Value("${spring.mail.username:alonewarrior123456@gmail.com}")
    private String senderEmail;

    private final SecureRandom secureRandom = new SecureRandom();

    /**
     * Generates a 6-digit OTP and sends it via JavaMail SMTP.
     */
    @Transactional
    public ApiResponse generateAndSendOtp(String email) {
        String cleanEmail = email.trim().toLowerCase();

        // 1. Generate 6-digit cryptographic OTP
        int otpInt = 100000 + secureRandom.nextInt(900000);
        String otpCode = String.valueOf(otpInt);

        // 2. Set 5-minute expiration
        LocalDateTime expiresAt = LocalDateTime.now().plusMinutes(5);

        // 3. Save to database
        OtpToken token = new OtpToken(cleanEmail, otpCode, expiresAt);
        otpTokenRepository.save(token);

        // 4. Send Email via JavaMail SMTP
        boolean sent = sendOtpEmail(cleanEmail, otpCode);
        if (!sent) {
            log.warn("⚠️ SMTP dispatch failed for {}, fallback console log: OTP = {}", cleanEmail, otpCode);
            return ApiResponse.ok("OTP generated (logged to console for dev): " + otpCode);
        }

        log.info("✅ OTP dispatched successfully to {}", cleanEmail);
        return ApiResponse.ok("Verification code sent to " + cleanEmail);
    }

    /**
     * Verifies an OTP code against stored tokens with exact error messages.
     */
    @Transactional
    public ApiResponse verifyOtp(String email, String inputOtp) {
        String cleanEmail = email.trim().toLowerCase();
        String cleanOtp = inputOtp.trim();

        java.util.List<OtpToken> tokens = otpTokenRepository.findByEmailIgnoreCaseOrderByCreatedAtDesc(cleanEmail);

        if (tokens.isEmpty()) {
            return ApiResponse.error("Email not found. Please request a new OTP first.");
        }

        OtpToken token = tokens.get(0);

        if (LocalDateTime.now().isAfter(token.getExpiresAt())) {
            return ApiResponse.error("OTP has expired. Please request a new verification code.");
        }

        if (!token.getOtpCode().equals(cleanOtp)) {
            return ApiResponse.error("Invalid OTP. Please enter the correct 6-digit code.");
        }

        token.setVerified(true);
        otpTokenRepository.save(token);

        return ApiResponse.ok("Email verified successfully!");
    }

    public boolean isEmailVerified(String email) {
        String cleanEmail = email.trim().toLowerCase();
        java.util.List<OtpToken> tokens = otpTokenRepository.findByEmailIgnoreCaseOrderByCreatedAtDesc(cleanEmail);
        return !tokens.isEmpty() && tokens.get(0).isVerified();
    }

    private boolean sendOtpEmail(String recipientEmail, String otpCode) {
        try {
            MimeMessage message = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");

            helper.setFrom(senderEmail, "CognitiveCare Support");
            helper.setTo(recipientEmail);
            helper.setSubject("Your CognitiveCare Verification Code: " + otpCode);

            String htmlContent = """
                <!DOCTYPE html>
                <html>
                <head>
                    <meta charset="UTF-8">
                    <style>
                        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f7f9fc; margin: 0; padding: 20px; }
                        .card { max-width: 500px; margin: 0 auto; background: #ffffff; border-radius: 16px; padding: 30px; box-shadow: 0 4px 15px rgba(0,0,0,0.08); border-top: 6px solid #00796B; }
                        .logo { text-align: center; font-size: 24px; font-weight: bold; color: #00796B; margin-bottom: 10px; }
                        .subtitle { text-align: center; color: #607D8B; font-size: 14px; margin-bottom: 25px; }
                        .otp-box { background: #E0F2F1; border: 2px dashed #00796B; border-radius: 12px; padding: 18px; text-align: center; margin: 25px 0; }
                        .otp-code { font-size: 36px; font-weight: bold; color: #004D40; letter-spacing: 8px; }
                        .warning { font-size: 13px; color: #78909C; text-align: center; margin-top: 20px; }
                        .footer { text-align: center; font-size: 12px; color: #B0BEC5; margin-top: 30px; }
                    </style>
                </head>
                <body>
                    <div class="card">
                        <div class="logo">🧠 CognitiveCare</div>
                        <div class="subtitle">AI Cognitive Support & Redressal System</div>
                        <p style="font-size: 16px; color: #263238;">Hello,</p>
                        <p style="font-size: 15px; color: #37474F; line-height: 1.5;">
                            Use the verification code below to verify your email address and proceed with registration.
                        </p>
                        <div class="otp-box">
                            <div class="otp-code">%s</div>
                        </div>
                        <p class="warning">⏱️ This code is valid for <strong>5 minutes</strong>. Do not share this code with anyone.</p>
                        <div class="footer">© 2026 CognitiveCare System • All Rights Reserved</div>
                    </div>
                </body>
                </html>
                """.formatted(otpCode);

            helper.setText(htmlContent, true);
            mailSender.send(message);
            return true;
        } catch (Exception e) {
            log.error("❌ Failed to dispatch email via SMTP: {}", e.getMessage());
            return false;
        }
    }
}
