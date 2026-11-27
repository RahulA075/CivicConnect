package com.civicconnect.modules.media.dto;

import lombok.Builder;
import lombok.Data;

import java.util.UUID;

/** Response returned after a successful file upload. */
@Data
@Builder
public class UploadResponse {
    private UUID   imageId;
    private String storageKey;
    private String cdnUrl;
    private String mimeType;
    private long   fileSizeBytes;
    private String imageType;
}
