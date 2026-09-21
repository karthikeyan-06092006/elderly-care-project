package com.elderlycare.backend.repository;

import com.elderlycare.backend.entity.OtpToken;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface OtpTokenRepository extends JpaRepository<OtpToken, Long> {
    List<OtpToken> findByEmailIgnoreCaseOrderByCreatedAtDesc(String email);
    List<OtpToken> findByEmailIgnoreCase(String email);
}
