package com.elderlycare.backend.service;

import com.elderlycare.backend.dto.AuthResponse;
import com.elderlycare.backend.dto.LoginRequest;
import com.elderlycare.backend.dto.RegisterRequest;
import com.elderlycare.backend.entity.User;
import com.elderlycare.backend.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Optional;
import java.util.UUID;

@Service
public class AuthService {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired
    private OtpService otpService;

    private static final DateTimeFormatter DATE_FORMATTER = DateTimeFormatter.ofPattern("dd MMMM yyyy");

    @Transactional
    public AuthResponse register(RegisterRequest req) {
        String cleanEmail = req.getEmail().trim().toLowerCase();

        // 1. Check if email already exists
        if (userRepository.findByEmailIgnoreCase(cleanEmail).isPresent()) {
            return AuthResponse.error("Email is already registered. Please log in instead.");
        }

        // 2. Format role (default to PATIENT if unspecified)
        String role = (req.getRole() != null && req.getRole().trim().equalsIgnoreCase("CARETAKER"))
                ? "CARETAKER"
                : "PATIENT";

        // 3. Generate IDs
        String userId = UUID.randomUUID().toString();
        String prefix = role.equals("PATIENT") ? "PATIENT" : "CARETAKER";
        String qrCodeToken = prefix + "-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase();

        // 4. Hash password with BCrypt
        String passwordHash = passwordEncoder.encode(req.getPassword().trim());

        // 5. Create and save user
        LocalDateTime now = LocalDateTime.now();
        User user = new User(
                userId,
                cleanEmail,
                passwordHash,
                role,
                req.getName().trim(),
                req.getPhone().trim(),
                qrCodeToken,
                now
        );
        userRepository.save(user);

        String dummyJwtToken = "JWT-" + UUID.randomUUID().toString();
        String formattedDate = now.format(DATE_FORMATTER);

        return AuthResponse.success(
                "Account created successfully!",
                dummyJwtToken,
                user.getUserId(),
                user.getEmail(),
                user.getFullName(),
                user.getPhoneNumber(),
                user.getRole(),
                user.getQrCodeToken(),
                formattedDate
        );
    }

    public AuthResponse login(LoginRequest req) {
        String cleanEmail = req.getEmail().trim().toLowerCase();

        // 1. Find user by email
        Optional<User> userOpt = userRepository.findByEmailIgnoreCase(cleanEmail);
        if (userOpt.isEmpty()) {
            return AuthResponse.error("Email not found. Please check your email or register a new account.");
        }

        User user = userOpt.get();

        // 2. Validate password
        if (!passwordEncoder.matches(req.getPassword().trim(), user.getPasswordHash())) {
            return AuthResponse.error("Incorrect password. Please try again.");
        }

        // 3. Return role-based auth response
        String dummyJwtToken = "JWT-" + UUID.randomUUID().toString();
        String formattedDate = (user.getCreatedAt() != null)
                ? user.getCreatedAt().format(DATE_FORMATTER)
                : "15 September 2026";

        return AuthResponse.success(
                "Login successful!",
                dummyJwtToken,
                user.getUserId(),
                user.getEmail(),
                user.getFullName(),
                user.getPhoneNumber(),
                user.getRole(),
                user.getQrCodeToken(),
                formattedDate
        );
    }
}
