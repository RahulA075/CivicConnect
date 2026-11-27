import '../../domain/entities/ai_analysis.dart';

class ImageLabelModel extends ImageLabel {
  const ImageLabelModel({required super.label, required super.confidence});

  factory ImageLabelModel.fromJson(Map<String, dynamic> json) =>
      ImageLabelModel(
        label: json['label'] as String? ?? '',
        confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      );
}

class AiAnalysisModel extends AiAnalysis {
  const AiAnalysisModel({
    super.suggestedCategoryId,
    super.suggestedCategoryName,
    super.categoryConfidence,
    super.suggestedPriority,
    super.severityConfidence,
    super.severityReasoning,
    super.potentialDuplicate,
    super.duplicateOfIssueId,
    super.duplicateOfTrackingId,
    super.duplicateOfTitle,
    super.duplicateSimilarity,
    super.spamFlagged,
    super.spamConfidence,
    super.spamReason,
    super.imageLabels,
    super.imageCategoryHint,
    super.complaintSummary,
    super.smartSuggestions,
    super.modelUsed,
    super.analysisDurationMs,
  });

  factory AiAnalysisModel.fromJson(Map<String, dynamic> json) {
    final labelsJson = json['imageLabels'] as List<dynamic>? ?? [];
    final suggestionsJson = json['smartSuggestions'] as List<dynamic>? ?? [];

    return AiAnalysisModel(
      suggestedCategoryId: json['suggestedCategoryId'] as String?,
      suggestedCategoryName: json['suggestedCategoryName'] as String?,
      categoryConfidence: (json['categoryConfidence'] as num?)?.toDouble(),
      suggestedPriority: json['suggestedPriority'] as String?,
      severityConfidence: (json['severityConfidence'] as num?)?.toDouble(),
      severityReasoning: json['severityReasoning'] as String?,
      potentialDuplicate: json['potentialDuplicate'] as bool? ?? false,
      duplicateOfIssueId: json['duplicateOfIssueId'] as String?,
      duplicateOfTrackingId: json['duplicateOfTrackingId'] as String?,
      duplicateOfTitle: json['duplicateOfTitle'] as String?,
      duplicateSimilarity: (json['duplicateSimilarity'] as num?)?.toDouble(),
      spamFlagged: json['spamFlagged'] as bool? ?? false,
      spamConfidence: (json['spamConfidence'] as num?)?.toDouble(),
      spamReason: json['spamReason'] as String?,
      imageLabels: labelsJson
          .map((e) => ImageLabelModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      imageCategoryHint: json['imageCategoryHint'] as String?,
      complaintSummary: json['complaintSummary'] as String?,
      smartSuggestions: suggestionsJson.map((e) => e as String).toList(),
      modelUsed: json['modelUsed'] as String?,
      analysisDurationMs: json['analysisDurationMs'] as int? ?? 0,
    );
  }

  factory AiAnalysisModel.empty() => const AiAnalysisModel();
}
