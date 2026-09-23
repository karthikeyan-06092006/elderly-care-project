package com.elderlycare.backend.repository;

import com.elderlycare.backend.entity.SocialMessage;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface SocialMessageRepository extends JpaRepository<SocialMessage, Long> {

    @Query("SELECT m FROM SocialMessage m WHERE m.connectionId = :connectionId ORDER BY m.sentAt ASC")
    List<SocialMessage> findByConnectionIdOrderBySentAtAsc(@Param("connectionId") Long connectionId);

    @Query("SELECT m FROM SocialMessage m WHERE m.connectionId = :connectionId AND m.isRead = false")
    List<SocialMessage> findUnreadByConnectionId(@Param("connectionId") Long connectionId);
}