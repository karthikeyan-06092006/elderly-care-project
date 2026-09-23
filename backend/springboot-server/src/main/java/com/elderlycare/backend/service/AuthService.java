package com.elderlycare.backend.service;

import com.elderlycare.backend.dto.AuthResponse;
import com.elderlycare.backend.dto.LoginRequest;
import com.elderlycare.backend.dto.RegisterRequest;
import com.elderlycare.backend.entity.User;
import com.elderlycare.backend.repository.UserRepository;
import jakarta.annotation.PostConstruct;
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

    @PostConstruct
    public void seedDefaultAdmin() {
        try {
            String adminEmail = "admin@cognitivecare.com";
            if (userRepository.findByEmailIgnoreCase(adminEmail).isEmpty()) {
                User admin = new User();
                admin.setUserId("ADMIN-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase());
                admin.setEmail(adminEmail);
                admin.setPasswordHash(passwordEncoder.encode("admin123"));
                admin.setRole("ADMIN");
                admin.setFullName("Super Administrator (NER Health)");
                admin.setPhoneNumber("+919876543210");
                admin.setState("Assam");
                admin.setDistrict("Kamrup Metro");
                admin.setVerificationStatus("APPROVED");
                admin.setQrCodeToken("ADMIN-ROOT");
                admin.setCreatedAt(LocalDateTime.now());
                userRepository.save(admin);
                System.out.println("✅ [Seed] Default Primary Admin user seeded: admin@cognitivecare.com / admin123");
            }
        } catch (Exception e) {
            System.err.println("⚠️ Could not seed admin user: " + e.getMessage());
        }
    }

    @Transactional
    public AuthResponse register(RegisterRequest req) {
        String cleanEmail = (req.getEmail() != null && !req.getEmail().trim().isEmpty())
                ? req.getEmail().trim().toLowerCase()
                : "";
        if (cleanEmail.isEmpty()) {
            return AuthResponse.error("Email address is required for registration.");
        }

        String cleanPhone = req.getPhone() != null ? req.getPhone().trim() : "";

        // 1. Check if email already exists
        if (userRepository.findByEmailIgnoreCase(cleanEmail).isPresent()) {
            return AuthResponse.error("Email " + cleanEmail + " is already registered. Please log in.");
        }
        if (!cleanPhone.isEmpty() && userRepository.findByPhoneNumber(cleanPhone).isPresent()) {
            return AuthResponse.error("Phone number " + cleanPhone + " is already registered. Please log in.");
        }

        // 2. Format role
        String rawRole = req.getRole() != null ? req.getRole().trim().toUpperCase() : "PATIENT";
        String role;
        if (rawRole.contains("HEALTH") || rawRole.contains("DOCTOR") || rawRole.contains("NURSE")) {
            role = "HEALTHCARE_WORKER";
        } else if (rawRole.contains("CARE")) {
            role = "CARETAKER";
        } else if (rawRole.contains("ADMIN")) {
            role = "ADMIN";
        } else {
            role = "PATIENT";
        }

        // 3. Generate IDs
        String userId = UUID.randomUUID().toString();
        String prefix = role.equals("PATIENT") ? "PATIENT" : (role.equals("HEALTHCARE_WORKER") ? "MED" : "CARETAKER");
        String qrCodeToken = prefix + "-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase();

        // 4. Hash password with BCrypt
        String passwordHash = passwordEncoder.encode(req.getPassword().trim());

        // 5. Verification status (Healthcare workers must be manually verified by Admin)
        String verificationStatus = role.equals("HEALTHCARE_WORKER") ? "PENDING" : "APPROVED";

        // 6. Compute age if dateOfBirth is given
        Integer computedAge = req.getAge();
        String dob = req.getDateOfBirth() != null ? req.getDateOfBirth().trim() : null;
        if ((computedAge == null || computedAge == 0) && dob != null && !dob.isEmpty()) {
            try {
                // Support yyyy-MM-dd or dd-MM-yyyy or dd/MM/yyyy
                java.time.LocalDate birthDate;
                if (dob.contains("/")) {
                    String[] parts = dob.split("/");
                    if (parts.length == 3) {
                        birthDate = java.time.LocalDate.of(Integer.parseInt(parts[2]), Integer.parseInt(parts[1]), Integer.parseInt(parts[0]));
                    } else {
                        birthDate = java.time.LocalDate.parse(dob);
                    }
                } else {
                    birthDate = java.time.LocalDate.parse(dob);
                }
                computedAge = java.time.Period.between(birthDate, java.time.LocalDate.now()).getYears();
            } catch (Exception ignored) {
            }
        }

        // 7. Create and save user
        LocalDateTime now = LocalDateTime.now();
        User user = new User();
        user.setUserId(userId);
        user.setEmail(cleanEmail);
        user.setPasswordHash(passwordHash);
        user.setRole(role);
        user.setFullName(req.getName().trim());
        user.setPhoneNumber(cleanPhone);
        user.setDateOfBirth(dob);
        user.setAge(computedAge);
        user.setGender(req.getGender());
        user.setState(req.getState());
        user.setDistrict(req.getDistrict());
        user.setPincode(req.getPincode());
        user.setProfession(req.getProfession());
        user.setSpecialization(req.getSpecialization());
        user.setHospitalName(req.getHospitalName());
        user.setStateCouncil(req.getStateCouncil());
        user.setRegistrationNumber(req.getRegistrationNumber());
        user.setNuid(req.getNuid());
        user.setIdProofUrl(req.getIdProofUrl());
        user.setVerificationStatus(verificationStatus);
        user.setQrCodeToken(qrCodeToken);
        user.setCreatedAt(now);

        userRepository.save(user);

        String dummyJwtToken = "JWT-" + UUID.randomUUID().toString();
        String formattedDate = now.format(DATE_FORMATTER);

        AuthResponse resp = new AuthResponse();
        resp.setSuccess(true);
        resp.setMessage(role.equals("HEALTHCARE_WORKER")
                ? "Registration submitted for manual Admin verification! Your credentials will be reviewed by the Administrator."
                : "Account created successfully!");
        resp.setToken(dummyJwtToken);
        resp.setUserId(user.getUserId());
        resp.setEmail(user.getEmail());
        resp.setName(user.getFullName());
        resp.setPhone(user.getPhoneNumber());
        resp.setRole(user.getRole());
        resp.setDateOfBirth(user.getDateOfBirth());
        resp.setAge(user.getAge());
        resp.setGender(user.getGender());
        resp.setState(user.getState());
        resp.setDistrict(user.getDistrict());
        resp.setPincode(user.getPincode());
        resp.setProfession(user.getProfession());
        resp.setSpecialization(user.getSpecialization());
        resp.setHospitalName(user.getHospitalName());
        resp.setStateCouncil(user.getStateCouncil());
        resp.setRegistrationNumber(user.getRegistrationNumber());
        resp.setVerificationStatus(user.getVerificationStatus());
        resp.setQrCodeToken(user.getQrCodeToken());
        resp.setRegisteredDate(formattedDate);

        return resp;
    }

    public AuthResponse login(LoginRequest req) {
        String identifier = req.getIdentifier();

        // 1. Find user by phone number OR email
        Optional<User> userOpt = userRepository.findByEmailOrPhone(identifier);
        if (userOpt.isEmpty()) {
            // Also try exact phone lookup if formatted
            userOpt = userRepository.findByPhoneNumber(identifier);
        }

        if (userOpt.isEmpty()) {
            return AuthResponse.error("No account found with phone/email: " + identifier + ". Please register.");
        }

        User user = userOpt.get();

        // 2. Validate password
        if (!passwordEncoder.matches(req.getPassword().trim(), user.getPasswordHash())) {
            return AuthResponse.error("Incorrect password. Please try again.");
        }

        // 3. Return role-based auth response with all demographic and verification details
        String dummyJwtToken = "JWT-" + UUID.randomUUID().toString();
        String formattedDate = (user.getCreatedAt() != null)
                ? user.getCreatedAt().format(DATE_FORMATTER)
                : "15 September 2026";

        AuthResponse resp = new AuthResponse();
        resp.setSuccess(true);
        resp.setMessage("Login successful!");
        resp.setToken(dummyJwtToken);
        resp.setUserId(user.getUserId());
        resp.setEmail(user.getEmail());
        resp.setName(user.getFullName());
        resp.setPhone(user.getPhoneNumber());
        resp.setRole(user.getRole());
        resp.setDateOfBirth(user.getDateOfBirth());
        resp.setAge(user.getAge());
        resp.setGender(user.getGender());
        resp.setState(user.getState());
        resp.setDistrict(user.getDistrict());
        resp.setPincode(user.getPincode());
        resp.setProfession(user.getProfession());
        resp.setSpecialization(user.getSpecialization());
        resp.setHospitalName(user.getHospitalName());
        resp.setStateCouncil(user.getStateCouncil());
        resp.setRegistrationNumber(user.getRegistrationNumber());
        resp.setVerificationStatus(user.getVerificationStatus() != null ? user.getVerificationStatus() : "APPROVED");
        resp.setQrCodeToken(user.getQrCodeToken());
        resp.setRegisteredDate(formattedDate);

        return resp;
    }
}
