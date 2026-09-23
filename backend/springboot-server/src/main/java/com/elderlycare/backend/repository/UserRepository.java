package com.elderlycare.backend.repository;

import com.elderlycare.backend.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface UserRepository extends JpaRepository<User, String> {
    
    @Query("SELECT u FROM User u WHERE LOWER(u.email) = LOWER(:email)")
    Optional<User> findByEmailIgnoreCase(@Param("email") String email);

    @Query("SELECT u FROM User u WHERE u.phoneNumber = :phone")
    Optional<User> findByPhoneNumber(@Param("phone") String phone);

    @Query("SELECT u FROM User u WHERE LOWER(u.email) = LOWER(:identifier) OR u.phoneNumber = :identifier")
    Optional<User> findByEmailOrPhone(@Param("identifier") String identifier);

    @Query("SELECT u FROM User u WHERE UPPER(u.qrCodeToken) = UPPER(:qrCodeToken)")
    Optional<User> findByQrCodeTokenIgnoreCase(@Param("qrCodeToken") String qrCodeToken);

    List<User> findByRole(String role);

    List<User> findByRoleAndVerificationStatus(String role, String verificationStatus);

    @Query("SELECT u FROM User u WHERE u.role = 'HEALTHCARE_WORKER' AND u.verificationStatus = 'APPROVED' AND (:state IS NULL OR LOWER(u.state) = LOWER(:state)) AND (:district IS NULL OR LOWER(u.district) = LOWER(:district))")
    List<User> findNearbyHealthcareWorkers(@Param("state") String state, @Param("district") String district);

    @Query("SELECT u FROM User u WHERE u.role = 'HEALTHCARE_WORKER' AND u.verificationStatus = 'APPROVED'")
    List<User> findAllVerifiedHealthcareWorkers();

    @Query("SELECT u FROM User u WHERE LOWER(u.role) = 'patient' ORDER BY u.fullName ASC")
    List<User> findAllPatients();

    long countByRole(String role);

    long countByRoleAndVerificationStatus(String role, String verificationStatus);
}
