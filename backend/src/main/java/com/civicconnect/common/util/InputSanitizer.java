package com.civicconnect.common.util;

import org.jsoup.Jsoup;
import org.jsoup.safety.Safelist;
import org.springframework.util.StringUtils;

/**
 * Utility for sanitizing free-text input fields to prevent XSS attacks.
 *
 * <p>Uses Jsoup's HTML parser with a strict whitelist to strip all tags and
 * attributes from user-supplied text. This is a defence-in-depth measure
 * on top of the Content-Security-Policy header.
 *
 * <h2>Usage</h2>
 * <pre>
 * issue.setTitle(InputSanitizer.sanitize(request.getTitle()));
 * issue.setDescription(InputSanitizer.sanitizeMultiline(request.getDescription()));
 * </pre>
 */
public final class InputSanitizer {

    private InputSanitizer() {}

    /**
     * Strips all HTML tags and returns plain text.
     * Safe for single-line fields (title, address, name).
     */
    public static String sanitize(String input) {
        if (!StringUtils.hasText(input)) return input;
        return Jsoup.clean(input.trim(), Safelist.none());
    }

    /**
     * Strips all HTML tags while preserving line breaks.
     * Safe for multi-line fields (description, notes, comments).
     */
    public static String sanitizeMultiline(String input) {
        if (!StringUtils.hasText(input)) return input;
        // Replace <br> and block-level tags with newlines before stripping
        String normalized = input
            .replaceAll("(?i)<br\\s*/?>", "\n")
            .replaceAll("(?i)<p[^>]*>", "\n")
            .replaceAll("(?i)</p>", "\n")
            .replaceAll("(?i)<div[^>]*>", "\n")
            .replaceAll("(?i)</div>", "\n");
        String cleaned = Jsoup.clean(normalized.trim(), Safelist.none());
        // Collapse more than two consecutive blank lines
        return cleaned.replaceAll("\\n{3,}", "\n\n").trim();
    }

    /**
     * Validates that a string contains no HTML tags.
     * Returns {@code true} if the input is safe (no tags found).
     */
    public static boolean isClean(String input) {
        if (!StringUtils.hasText(input)) return true;
        return Jsoup.isValid(input, Safelist.none());
    }
}
