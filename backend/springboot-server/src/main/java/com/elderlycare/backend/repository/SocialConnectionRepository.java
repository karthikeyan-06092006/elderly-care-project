package com.elderlycare.backend.repository;

import com.elderlycare.backend.entity.SocialConnection;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface SocialConnectionRepository extends JpaRepository<SocialConnection, Long> {

    List<SocialConnection> findByRequesterPatientIdOrReceiverPatientIdOrderByRequestedAtDesc(
            String requesterPatientId, String receiverPatientId);

    @Query("SELECT c FROM SocialConnection c WHERE c.requesterPatientId = :requesterId " +
            "AND c.receiverPatientId = :receiverId AND c.status <> 'REJECTED'")
    List<SocialConnection> findActiveBetween(@Param("requesterId") String requesterId,
                                             @Param("receiverId") String receiverId);

    @Query("SELECT c FROM SocialConnection c WHERE c.requesterPatientId = :receiverId " +
            "AND c.receiverPatientId = :requesterId AND c.status <> 'REJECTED'")
    List<SocialConnection> findActiveReverseBetween(@Param("requesterId") String requesterId,
                                                    @Param("receiverId") String receiverId);

    @Query("SELECT c FROM SocialConnection c WHERE c.receiverPatientId IN :patientIds " +
            "AND c.caretakerApproved = false AND c.status = 'PENDING' ORDER BY c.requestedAt DESC")
    List<SocialConnection> findPendingCaretakerApprovals(@Param("patientIds") List<String> patientIds);
}