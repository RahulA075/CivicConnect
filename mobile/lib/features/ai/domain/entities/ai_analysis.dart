import 'package:equatable/equatable.dart';

/// Image classification label with confidence score.
class ImageLabel extends Equatable {
  final String label;
  final double confidence;

  const ImageLabel({required this.label, required this.confidence});

  @override
  List<Object?> get props => [label, confidence];
}

/// Full AI analysis result for a civic issue.
class AiAnalysis extends Equatable {
  // Category suggestion
  final String? suggestedCategoryId;
  final String? suggestedCategoryName;
  final double? categoryConfidence;

  // Severity / priority
  final String? suggestedPriority; // LOW | MEDIUM | HIGH | CRITICAL
  final double? severityConfidence;
  final String? severityReasoning;

  // Duplicate detection
  final bool potentialDuplicate;
  final String? duplicateOfIssueId;
  final String? duplicateOfTrackingId;
  final String? duplicateOfTitle;
  final double? duplicateSimilarity;

  // Spam
  final bool spamFlagged;
  final double? spamConfidence;
  final String? spamReason;

  // Image classification
  final List<ImageLabel> imageLabels;
  final String? imageCategoryHint;

  // Summary & suggestions
  final String? complaintSummary;
  final List<String> smartSuggestions;

  // Meta
  final String? modelUsed;
  final int analysisDurationMs;

  const AiAnalysis({
    this.suggestedCategoryId,
    this.suggestedCategoryName,
    this.categoryConfidence,
    this.suggestedPriority,
    this.severityConfidence,
    this.severityReasoning,
    this.potentialDuplicate = false,
    this.duplicateOfIssueId,
    this.duplicateOfTrackingId,
    this.duplicateOfTitle,
    this.duplicateSimilarity,
    this.spamFlagged = false,
    this.spamConfidence,
    this.spamReason,
    this.imageLabels = const [],
    this.imageCategoryHint,
    this.complaintSummary,
    this.smartSuggestions = const [],
    this.modelUsed,
    this.analysisDurationMs = 0,
  });

  /// Whether the category suggestion is confident enough to show in the UI.
  bool get hasCategorySuggestion =>
      suggestedCategoryId != null &&
      suggestedCategoryName != null &&
      (categoryConfidence ?? 0) >= 0.6;

  /// Whether the priority suggestion is confident enough to show in the UI.
  bool get hasPrioritySuggestion =>
      suggestedPriority != null && (severityConfidence ?? 0) >= 0.6;

  static const AiAnalysis empty = AiAnalysis();

  @override
  List<Object?> get props => [
        suggestedCategoryId,
        suggestedCategoryName,
        categoryConfidence,
        suggestedPriority,
        severityConfidence,
        potentialDuplicate,
        duplicateOfIssueId,
        spamFlagged,
        spamConfidence,
        imageLabels,
        complaintSummary,
        smartSuggestions,
        modelUsed,
        analysisDurationMs,
      ];
}
