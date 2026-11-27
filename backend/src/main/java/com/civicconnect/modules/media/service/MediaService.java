package com.civicconnect.modules.media.service;

import com.civicconnect.modules.media.dto.UploadResponse;
import org.springframework.web.multipart.MultipartFile;

import java.util.UUID;

public interface MediaService {
    UploadResponse uploadIssueImage(UUID issueId, UUID uploaderId,
                                    MultipartFile file, String safeFilename,
                                    String imageType);
    void deleteImage(UUID imageId, UUID requesterId);
}
