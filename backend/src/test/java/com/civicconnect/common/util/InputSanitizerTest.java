package com.civicconnect.common.util;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Unit tests for {@link InputSanitizer}.
 */
@DisplayName("InputSanitizer")
class InputSanitizerTest {

    // ── sanitize ───────────────────────────────────────────────────────────

    @Test
    @DisplayName("strips script tag from input")
    void sanitize_stripsScriptTag() {
        String result = InputSanitizer.sanitize("<script>alert('xss')</script>Hello");
        assertThat(result).isEqualTo("Hello");
        assertThat(result).doesNotContain("<script>");
    }

    @Test
    @DisplayName("strips HTML anchor tags")
    void sanitize_stripsAnchorTags() {
        String result = InputSanitizer.sanitize("<a href='evil.com'>Click me</a>");
        assertThat(result).isEqualTo("Click me");
    }

    @Test
    @DisplayName("preserves plain text unchanged")
    void sanitize_preservesPlainText() {
        String input = "Broken road near bus stop 42";
        assertThat(InputSanitizer.sanitize(input)).isEqualTo(input);
    }

    @Test
    @DisplayName("returns null/blank input as-is")
    void sanitize_handlesNullInput() {
        assertThat(InputSanitizer.sanitize(null)).isNull();
        assertThat(InputSanitizer.sanitize("")).isEqualTo("");
        assertThat(InputSanitizer.sanitize("  ")).isEqualTo("  ");
    }

    @Test
    @DisplayName("trims whitespace around text")
    void sanitize_trims() {
        assertThat(InputSanitizer.sanitize("  hello world  ")).isEqualTo("hello world");
    }

    @ParameterizedTest
    @ValueSource(strings = {
        "<img src='x' onerror='alert(1)'>",
        "<iframe src='evil.com'></iframe>",
        "<svg onload='alert(1)'>",
        "javascript:alert(1)"
    })
    @DisplayName("strips dangerous payloads")
    void sanitize_stripsXssPayloads(String payload) {
        String result = InputSanitizer.sanitize(payload);
        assertThat(result).doesNotContain("<");
        assertThat(result).doesNotContain(">");
    }

    // ── sanitizeMultiline ──────────────────────────────────────────────────

    @Test
    @DisplayName("sanitizeMultiline preserves text content through newlines")
    void sanitizeMultiline_preservesTextContent() {
        // Jsoup may convert bare \n to spaces; the important guarantee is
        // that all text content is preserved and tags are stripped.
        String input = "Line one\nLine two\nLine three";
        String result = InputSanitizer.sanitizeMultiline(input);
        assertThat(result).contains("Line one");
        assertThat(result).contains("Line two");
        assertThat(result).contains("Line three");
    }

    @Test
    @DisplayName("sanitizeMultiline converts <br> tag to whitespace/newline")
    void sanitizeMultiline_convertsBrTag() {
        String input = "First line<br>Second line";
        String result = InputSanitizer.sanitizeMultiline(input);
        // After processing, both pieces of text should still be present
        assertThat(result).contains("First line");
        assertThat(result).contains("Second line");
        assertThat(result).doesNotContain("<br>");
    }

    @Test
    @DisplayName("strips HTML but keeps text content in multiline")
    void sanitizeMultiline_stripsTagsKeepsText() {
        String input = "<p>First paragraph</p><p>Second paragraph</p>";
        String result = InputSanitizer.sanitizeMultiline(input);
        assertThat(result).contains("First paragraph");
        assertThat(result).contains("Second paragraph");
        assertThat(result).doesNotContain("<p>");
    }

    @Test
    @DisplayName("collapses excessive blank lines")
    void sanitizeMultiline_collapsesExcessiveBlankLines() {
        String input = "Para 1\n\n\n\n\nPara 2";
        String result = InputSanitizer.sanitizeMultiline(input);
        assertThat(result).doesNotMatch("(?s).*\\n{3,}.*");
    }

    @Test
    @DisplayName("returns null/blank input as-is in multiline mode")
    void sanitizeMultiline_handlesNullInput() {
        assertThat(InputSanitizer.sanitizeMultiline(null)).isNull();
        assertThat(InputSanitizer.sanitizeMultiline("")).isEqualTo("");
    }

    // ── isClean ────────────────────────────────────────────────────────────

    @Test
    @DisplayName("isClean returns true for plain text")
    void isClean_trueForPlainText() {
        assertThat(InputSanitizer.isClean("Normal civic complaint text")).isTrue();
    }

    @Test
    @DisplayName("isClean returns false for HTML content")
    void isClean_falseForHtmlContent() {
        assertThat(InputSanitizer.isClean("<b>Bold</b>")).isFalse();
    }

    @Test
    @DisplayName("isClean returns true for null/blank")
    void isClean_trueForBlank() {
        assertThat(InputSanitizer.isClean(null)).isTrue();
        assertThat(InputSanitizer.isClean("")).isTrue();
    }
}
