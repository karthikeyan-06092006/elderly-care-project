package com.elderlycare.backend.service;

import com.elderlycare.backend.dto.ApiResponse;
import com.elderlycare.backend.dto.PatientSummaryDto;
import com.elderlycare.backend.dto.SendConnectionRequest;
import com.elderlycare.backend.dto.SendMessageRequest;
import com.elderlycare.backend.dto.SocialConnectionDto;
import com.elderlycare.backend.dto.SocialMessageDto;
import com.elderlycare.backend.entity.PatientCaretakerMapping;
import com.elderlycare.backend.entity.SocialConnection;
import com.elderlycare.backend.entity.SocialMessage;
import com.elderlycare.backend.entity.User;
import com.elderlycare.backend.repository.PatientCaretakerRepository;
import com.elderlycare.backend.repository.SocialConnectionRepository;
import com.elderlycare.backend.repository.SocialMessageRepository;
import com.elderlycare.backend.repository.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.Optional;
import java.util.UUID;

@Service
public class SocialService {

    private static final Logger log = LoggerFactory.getLogger(SocialService.class);
    private static final DateTimeFormatter DATE_FORMATTER = DateTimeFormatter.ofPattern("dd MMMM yyyy, hh:mm a");
    private static final String STATUS_PENDING = "PENDING";
    private static final String STATUS_CONNECTED = "CONNECTED";
    private static final String STATUS_REJECTED = "REJECTED";
    private static final long MAX_MEDIA_BYTES = 10L * 1024 * 1024;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private SocialConnectionRepository connectionRepository;

    @Autowired
    private SocialMessageRepository messageRepository;

    @Autowired
    private PatientCaretakerRepository patientCaretakerRepository;

    @Transactional
    public ApiResponse sendConnectionRequest(String requesterPatientId, SendConnectionRequest req) {
        String receiverId = req.getReceiverPatientId().trim();

        Optional<User> requesterOpt = userRepository.findById(requesterPatientId);
        if (requesterOpt.isEmpty() || !"PATIENT".equalsIgnoreCase(requesterOpt.get().getRole())) {
            return ApiResponse.error("Requester account not found or is not a patient.");
        }
        Optional<User> receiverOpt = userRepository.findById(receiverId);
        if (receiverOpt.isEmpty() || !"PATIENT".equalsIgnoreCase(receiverOpt.get().getRole())) {
            return ApiResponse.error("Receiver account not found or is not a patient.");
        }
        User requester = requesterOpt.get();
        User receiver = receiverOpt.get();

        if (requester.getUserId().equals(receiver.getUserId())) {
            return ApiResponse.error("You cannot send a connection request to yourself.");
        }

        boolean alreadyActive = !connectionRepository
                .findActiveBetween(requester.getUserId(), receiver.getUserId()).isEmpty()
                || !connectionRepository
                .findActiveReverseBetween(requester.getUserId(), receiver.getUserId()).isEmpty();
        if (alreadyActive) {
            return ApiResponse.error("A connection request already exists or you are already connected with this patient.");
        }

        String message = (req.getRequestMessage() != null && !req.getRequestMessage().trim().isEmpty())
                ? req.getRequestMessage().trim().substring(0, Math.min(req.getRequestMessage().trim().length(), 500))
                : null;

        SocialConnection connection = new SocialConnection(
                requester.getUserId(),
                receiver.getUserId(),
                STATUS_PENDING,
                message,
                LocalDateTime.now()
        );
        connectionRepository.save(connection);
        log.info("💬 Social connection request: {} -> {} \"{}\"", requester.getFullName(), receiver.getFullName(), message);
        return ApiResponse.ok("Connection request sent to " + receiver.getFullName() + ". It becomes active after both the patient and the caregiver approve.", toDto(connection));
    }

    @Transactional
    public ApiResponse respondToConnection(Long connectionId, String patientId, boolean accept) {
        SocialConnection connection = connectionRepository.findById(connectionId).orElse(null);
        if (connection == null) {
            return ApiResponse.error("Connection request not found.");
        }
        if (!connection.getReceiverPatientId().equals(patientId)) {
            return ApiResponse.error("Only the receiving patient can accept or reject this request.");
        }
        if (STATUS_CONNECTED.equals(connection.getStatus())) {
            return ApiResponse.error("This connection is already active.");
        }

        if (accept) {
            connection.setPatientApproved(true);
            connection.setPatientApprovedAt(LocalDateTime.now());
            if (connection.isCaretakerApproved()) {
                connection.setStatus(STATUS_CONNECTED);
                connection.setConnectedAt(LocalDateTime.now());
            } else {
                connection.setStatus(STATUS_PENDING);
            }
            connectionRepository.save(connection);
            String msg = connection.isCaretakerApproved()
                    ? "You accepted the request. Caregiver had already approved. You are now connected!"
                    : "You accepted the request. Awaiting caregiver approval to complete the connection.";
            return ApiResponse.ok(msg, toDto(connection));
        } else {
            connection.setStatus(STATUS_REJECTED);
            connectionRepository.save(connection);
            return ApiResponse.ok("Connection request rejected.", toDto(connection));
        }
    }

    @Transactional
    public ApiResponse approveByCaretaker(Long connectionId, String caretakerId, boolean approve) {
        SocialConnection connection = connectionRepository.findById(connectionId).orElse(null);
        if (connection == null) {
            return ApiResponse.error("Connection request not found.");
        }
        if (STATUS_CONNECTED.equals(connection.getStatus())) {
            return ApiResponse.error("This connection is already active.");
        }
        if (!isCaretakerLinkedTo(connection, caretakerId)) {
            return ApiResponse.error("Your caregiving account is not linked to either patient in this request.");
        }

        if (approve) {
            connection.setCaretakerApproved(true);
            connection.setCaretakerId(caretakerId);
            connection.setCaretakerApprovedAt(LocalDateTime.now());
            if (connection.isPatientApproved()) {
                connection.setStatus(STATUS_CONNECTED);
                connection.setConnectedAt(LocalDateTime.now());
            } else {
                connection.setStatus(STATUS_PENDING);
            }
            connectionRepository.save(connection);
            String msg = connection.isPatientApproved()
                    ? "Approved. Both parties approved — the patients are now connected."
                    : "Approved by caregiver. Waiting for the patient to accept the request.";
            return ApiResponse.ok(msg, toDto(connection));
        } else {
            connection.setStatus(STATUS_REJECTED);
            connectionRepository.save(connection);
            return ApiResponse.ok("Connection request rejected by caregiver.", toDto(connection));
        }
    }

    public List<PatientSummaryDto> getDiscoverablePatients(String patientId) {
        List<User> allPatients = userRepository.findAllPatients();
        List<SocialConnection> myConnections = connectionRepository
                .findByRequesterPatientIdOrReceiverPatientIdOrderByRequestedAtDesc(patientId, patientId);

        List<PatientSummaryDto> result = new ArrayList<>();
        for (User u : allPatients) {
            if (u.getUserId().equals(patientId)) {
                continue;
            }
            boolean alreadyRequested = false;
            for (SocialConnection c : myConnections) {
                boolean involves = c.getRequesterPatientId().equals(patientId) && c.getReceiverPatientId().equals(u.getUserId())
                        || c.getRequesterPatientId().equals(u.getUserId()) && c.getReceiverPatientId().equals(patientId);
                if (involves && !STATUS_REJECTED.equals(c.getStatus())) {
                    alreadyRequested = true;
                    break;
                }
            }
            if (!alreadyRequested) {
                result.add(new PatientSummaryDto(u.getUserId(), u.getFullName(), u.getEmail(), u.getPhoneNumber()));
            }
        }
        return result;
    }

    public List<SocialConnectionDto> getConnectionsForPatient(String patientId) {
        List<SocialConnection> connections = connectionRepository
                .findByRequesterPatientIdOrReceiverPatientIdOrderByRequestedAtDesc(patientId, patientId);
        List<SocialConnectionDto> result = new ArrayList<>();
        for (SocialConnection c : connections) {
            if (!STATUS_REJECTED.equals(c.getStatus())) {
                result.add(toDto(c));
            }
        }
        return result;
    }

    public List<SocialConnectionDto> getPendingCaretakerApprovals(String caretakerId) {
        List<String> patientIds = new ArrayList<>();
        List<PatientCaretakerMapping> mappings = patientCaretakerRepository.findByCaretakerId(caretakerId);
        for (PatientCaretakerMapping m : mappings) {
            patientIds.add(m.getPatientId());
        }
        if (patientIds.isEmpty()) {
            return List.of();
        }
        List<SocialConnection> connections = connectionRepository.findPendingCaretakerApprovals(patientIds);
        List<SocialConnectionDto> result = new ArrayList<>();
        for (SocialConnection c : connections) {
            result.add(toDto(c));
        }
        return result;
    }

    public List<SocialConnectionDto> getConnectedForCaretaker(String caretakerId) {
        List<String> patientIds = new ArrayList<>();
        List<PatientCaretakerMapping> mappings = patientCaretakerRepository.findByCaretakerId(caretakerId);
        for (PatientCaretakerMapping m : mappings) {
            patientIds.add(m.getPatientId());
        }
        if (patientIds.isEmpty()) {
            return List.of();
        }
        List<SocialConnection> connections = connectionRepository.findAll();
        List<SocialConnectionDto> result = new ArrayList<>();
        for (SocialConnection c : connections) {
            if (STATUS_CONNECTED.equals(c.getStatus())
                    && (patientIds.contains(c.getRequesterPatientId()) || patientIds.contains(c.getReceiverPatientId()))) {
                result.add(toDto(c));
            }
        }
        return result;
    }

    @Transactional
    public ApiResponse sendMessage(String senderId, SendMessageRequest req) {
        String type = req.getType() != null ? req.getType().trim().toUpperCase(Locale.ROOT) : "";
        if (!List.of("TEXT", "VOICE", "PHOTO").contains(type)) {
            return ApiResponse.error("Message type must be TEXT, VOICE or PHOTO.");
        }

        SocialConnection connection = connectionRepository.findById(req.getConnectionId()).orElse(null);
        if (connection == null) {
            return ApiResponse.error("Connection not found.");
        }
        if (!STATUS_CONNECTED.equals(connection.getStatus())) {
            return ApiResponse.error("Communication opens only after both the patient and the caregiver approve.");
        }
        if (!connection.getRequesterPatientId().equals(senderId)
                && !connection.getReceiverPatientId().equals(senderId)) {
            return ApiResponse.error("You are not part of this connection.");
        }

        String content = (type.equals("TEXT") && req.getContent() != null)
                ? req.getContent().trim().substring(0, Math.min(req.getContent().trim().length(), 2000))
                : (req.getContent() != null ? req.getContent().trim() : null);

        SocialMessage message = new SocialMessage(
                connection.getId(),
                senderId,
                type,
                content,
                req.getMediaUrl(),
                req.getDurationMs(),
                LocalDateTime.now()
        );
        if ("TEXT".equals(type) && (content == null || content.isEmpty())) {
            return ApiResponse.error("Text message content cannot be empty.");
        }
        if (("VOICE".equals(type) || "PHOTO".equals(type)) && (req.getMediaUrl() == null || req.getMediaUrl().isEmpty())) {
            return ApiResponse.error("Media URL is required for " + type + " messages.");
        }
        messageRepository.save(message);
        log.info("💬 Social message from {} (type={})", senderId, type);
        return ApiResponse.ok("Message sent.", toMessageDto(message));
    }

    public List<SocialMessageDto> getMessages(Long connectionId, String userId) {
        SocialConnection connection = connectionRepository.findById(connectionId).orElse(null);
        if (connection == null) {
            return List.of();
        }
        if (!connection.getRequesterPatientId().equals(userId)
                && !connection.getReceiverPatientId().equals(userId)) {
            return List.of();
        }

        List<SocialMessage> messages = messageRepository.findByConnectionIdOrderBySentAtAsc(connectionId);
        List<SocialMessageDto> result = new ArrayList<>();
        for (SocialMessage m : messages) {
            result.add(toMessageDto(m));
        }
        markMessagesRead(messages, userId);
        return result;
    }

    @Transactional
    public ApiResponse uploadMedia(MultipartFile file) {
        if (file == null || file.isEmpty()) {
            return ApiResponse.error("Please select a file to upload.");
        }
        if (file.getSize() > MAX_MEDIA_BYTES) {
            return ApiResponse.error("File is too large. Maximum allowed size is 10 MB.");
        }
        String original = file.getOriginalFilename() != null ? file.getOriginalFilename() : "file";
        String ext = "";
        int dot = original.lastIndexOf('.');
        if (dot >= 0 && dot < original.length() - 1) {
            ext = original.substring(dot).toLowerCase(Locale.ROOT);
        }
        String safeExt = isAllowedExtension(ext) ? ext : "";
        String filename = UUID.randomUUID().toString() + safeExt;

        try {
            Path uploadDir = Paths.get("uploads", "social").toAbsolutePath().normalize();
            Files.createDirectories(uploadDir);
            Path target = uploadDir.resolve(filename);
            file.transferTo(target.toFile());
            String url = "/uploads/social/" + filename;
            log.info("📎 Uploaded media {} -> {}", original, url);
            return ApiResponse.ok("File uploaded successfully.", url);
        } catch (IOException e) {
            log.error("Failed to save uploaded media.", e);
            return ApiResponse.error("Failed to save uploaded file. Please try again.");
        }
    }

    @Transactional
    public ApiResponse deleteMessage(Long messageId, Long connectionId, String userId) {
        SocialConnection connection = connectionRepository.findById(connectionId).orElse(null);
        if (connection == null) {
            return ApiResponse.error("Connection not found.");
        }
        if (!connection.getRequesterPatientId().equals(userId)
                && !connection.getReceiverPatientId().equals(userId)) {
            return ApiResponse.error("You are not part of this connection.");
        }
        SocialMessage message = messageRepository.findById(messageId).orElse(null);
        if (message == null || !message.getConnectionId().equals(connectionId)) {
            return ApiResponse.error("Message not found.");
        }
        String mediaUrl = message.getMediaUrl();
        if (mediaUrl != null && !mediaUrl.isBlank()) {
            deleteMediaFile(mediaUrl);
        }
        messageRepository.delete(message);
        return ApiResponse.ok("Message deleted.");
    }

    private void deleteMediaFile(String mediaUrl) {
        try {
            String fileName = Paths.get(mediaUrl).getFileName().toString();
            if (fileName.isEmpty()) {
                return;
            }
            Path uploadDir = Paths.get("uploads", "social").toAbsolutePath().normalize();
            Path target = uploadDir.resolve(fileName).normalize();
            if (target.startsWith(uploadDir)) {
                Files.deleteIfExists(target);
                log.info("🗑 Deleted media file {}", target);
            }
        } catch (IOException e) {
            log.warn("Failed to delete media file for URL {}", mediaUrl, e);
        }
    }

    @Transactional
    public ApiResponse cancelConnection(Long connectionId, String userId) {
        SocialConnection connection = connectionRepository.findById(connectionId).orElse(null);
        if (connection == null) {
            return ApiResponse.error("Connection not found.");
        }
        if (!connection.getRequesterPatientId().equals(userId)
                && !connection.getReceiverPatientId().equals(userId)) {
            return ApiResponse.error("You are not part of this connection.");
        }
        connection.setStatus(STATUS_REJECTED);
        connectionRepository.save(connection);
        return ApiResponse.ok("Connection removed.");
    }

    private boolean isCaretakerLinkedTo(SocialConnection connection, String caretakerId) {
        List<PatientCaretakerMapping> mappings = patientCaretakerRepository.findByCaretakerId(caretakerId);
        for (PatientCaretakerMapping m : mappings) {
            if (m.getPatientId().equals(connection.getRequesterPatientId())
                    || m.getPatientId().equals(connection.getReceiverPatientId())) {
                return true;
            }
        }
        return false;
    }

    private boolean isAllowedExtension(String ext) {
        return List.of(".jpg", ".jpeg", ".png", ".gif", ".webp", ".bmp",
                ".mp3", ".wav", ".m4a", ".ogg", ".aac", ".amr").contains(ext);
    }

    @Transactional
    void markMessagesRead(List<SocialMessage> messages, String byUserId) {
        boolean changed = false;
        for (SocialMessage m : messages) {
            if (!m.isRead() && !m.getSenderId().equals(byUserId)) {
                m.setRead(true);
                changed = true;
            }
        }
        if (changed) {
            messageRepository.saveAll(messages);
        }
    }

    private SocialConnectionDto toDto(SocialConnection c) {
        SocialConnectionDto dto = new SocialConnectionDto();
        dto.setConnectionId(c.getId());
        dto.setRequesterPatientId(c.getRequesterPatientId());
        dto.setReceiverPatientId(c.getReceiverPatientId());
        dto.setStatus(c.getStatus());
        dto.setPatientApproved(c.isPatientApproved());
        dto.setCaretakerApproved(c.isCaretakerApproved());
        dto.setCaretakerId(c.getCaretakerId());
        dto.setRequestMessage(c.getRequestMessage());
        dto.setRequestedAt(c.getRequestedAt() != null ? c.getRequestedAt().format(DATE_FORMATTER) : "");
        dto.setConnectedAt(c.getConnectedAt() != null ? c.getConnectedAt().format(DATE_FORMATTER) : "");
        userRepository.findById(c.getRequesterPatientId()).ifPresent(u -> dto.setRequesterName(u.getFullName()));
        userRepository.findById(c.getReceiverPatientId()).ifPresent(u -> dto.setReceiverName(u.getFullName()));
        return dto;
    }

    private SocialMessageDto toMessageDto(SocialMessage m) {
        SocialMessageDto dto = new SocialMessageDto();
        dto.setMessageId(m.getId());
        dto.setConnectionId(m.getConnectionId());
        dto.setSenderId(m.getSenderId());
        dto.setType(m.getType());
        dto.setContent(m.getContent());
        dto.setMediaUrl(m.getMediaUrl());
        dto.setDurationMs(m.getDurationMs());
        dto.setRead(m.isRead());
        dto.setSentAt(m.getSentAt() != null ? m.getSentAt().format(DATE_FORMATTER) : "");
        userRepository.findById(m.getSenderId()).ifPresent(u -> dto.setSenderName(u.getFullName()));
        return dto;
    }
}