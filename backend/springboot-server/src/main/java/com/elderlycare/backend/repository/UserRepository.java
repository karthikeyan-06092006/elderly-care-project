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

    @Query("SELECT u FROM User u WHERE UPPER(u.qrCodeToken) = UPPER(:qrCodeToken)")
    Optional<User> findByQrCodeTokenIgnoreCase(@Param("qrCodeToken") String qrCodeToken);

    @Query("SELECT u FROM User u WHERE LOWER(u.role) = 'patient' ORDER BY u.fullName ASC")
    List<User> findAllPatients();
}
