package com.elderlycare.backend.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "SOCIAL_MESSAGES")
public class SocialMessage {

    @Id
    @GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "social_msg_seq_gen")
    @SequenceGenerator(name = "social_msg_seq_gen", sequenceName = "SOCIAL_MSG_SEQ", allocationSize = 1)
    @Column(name = "ID")
    private Long id;

    @Column(name = "CONNECTION_ID", nullable = false)
    private Long connectionId;

    @Column(name = "SENDER_ID", nullable = false, length = 36)
    private String senderId;

    @Column(name = "TYPE", nullable = false, length = 20)
    private String type; // "TEXT", "VOICE", "PHOTO"

    @Column(name = "CONTENT", length = 2000)
    private String content;

    @Column(name = "MEDIA_URL", length = 500)
    private String mediaUrl;

    @Column(name = "DURATION_MS")
    private Long durationMs;

    @Column(name = "IS_READ", nullable = false)
    private boolean isRead;

    @Column(name = "SENT_AT", nullable = false)
    private LocalDateTime sentAt;

    public SocialMessage() {
    }

    public SocialMessage(Long connectionId, String senderId, String type, String content,
                         String mediaUrl, Long durationMs, LocalDateTime sentAt) {
        this.connectionId = connectionId;
        this.senderId = senderId;
        this.type = type;
        this.content = content;
        this.mediaUrl = mediaUrl;
        this.durationMs = durationMs;
        this.isRead = false;
        this.sentAt = sentAt;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public Long getConnectionId() {
        return connectionId;
    }

    public void setConnectionId(Long connectionId) {
        this.connectionId = connectionId;
    }

    public String getSenderId() {
        return senderId;
    }

    public void setSenderId(String senderId) {
        this.senderId = senderId;
    }

    public String getType() {
        return type;
    }

    public void setType(String type) {
        this.type = type;
    }

    public String getContent() {
        return content;
    }

    public void setContent(String content) {
        this.content = content;
    }

    public String getMediaUrl() {
        return mediaUrl;
    }

    public void setMediaUrl(String mediaUrl) {
        this.mediaUrl = mediaUrl;
    }

    public Long getDurationMs() {
        return durationMs;
    }

    public void setDurationMs(Long durationMs) {
        this.durationMs = durationMs;
    }

    public boolean isRead() {
        return isRead;
    }

    public void setRead(boolean read) {
        isRead = read;
    }

    public LocalDateTime getSentAt() {
        return sentAt;
    }

    public void setSentAt(LocalDateTime sentAt) {
        this.sentAt = sentAt;
    }
}