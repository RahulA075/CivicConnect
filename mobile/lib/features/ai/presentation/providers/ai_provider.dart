import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/ai_analysis.dart';
import '../../domain/entities/duplicate_candidate.dart';
import '../../domain/usecases/analyze_issue_text.dart';
import '../../domain/usecases/check_duplicate.dart';
import '../../domain/usecases/get_smart_suggestions.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class AiAnalysisState {
  final AiAnalysis? analysis;
  final DuplicateCheckResult? duplicateResult;
  final List<String> smartSuggestions;
  final bool isAnalyzing;
  final bool isCheckingDuplicate;
  final bool isFetchingSuggestions;
  final String? errorMessage;

  const AiAnalysisState({
    this.analysis,
    this.duplicateResult,
    this.smartSuggestions = const [],
    this.isAnalyzing = false,
    this.isCheckingDuplicate = false,
    this.isFetchingSuggestions = false,
    this.errorMessage,
  });

  bool get hasSpamWarning => analysis?.spamFlagged == true;
  bool get hasDuplicateWarning =>
      duplicateResult?.hasPotentialDuplicates == true;
  bool get hasCategorySuggestion => analysis?.hasCategorySuggestion == true;
  bool get hasPrioritySuggestion => analysis?.hasPrioritySuggestion == true;
  bool get hasImageLabels =>
      analysis?.imageLabels != null && analysis!.imageLabels.isNotEmpty;

  AiAnalysisState copyWith({
    AiAnalysis? analysis,
    DuplicateCheckResult? duplicateResult,
    List<String>? smartSuggestions,
    bool? isAnalyzing,
    bool? isCheckingDuplicate,
    bool? isFetchingSuggestions,
    String? errorMessage,
    bool clearError = false,
  }) =>
      AiAnalysisState(
        analysis: analysis ?? this.analysis,
        duplicateResult: duplicateResult ?? this.duplicateResult,
        smartSuggestions: smartSuggestions ?? this.smartSuggestions,
        isAnalyzing: isAnalyzing ?? this.isAnalyzing,
        isCheckingDuplicate: isCheckingDuplicate ?? this.isCheckingDuplicate,
        isFetchingSuggestions:
            isFetchingSuggestions ?? this.isFetchingSuggestions,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class AiAnalysisNotifier extends StateNotifier<AiAnalysisState> {
  final AnalyzeIssueText _analyzeText;
  final CheckDuplicate _checkDuplicate;
  final GetSmartSuggestions _getSmartSuggestions;

  AiAnalysisNotifier({
    required AnalyzeIssueText analyzeText,
    required CheckDuplicate checkDuplicate,
    required GetSmartSuggestions getSmartSuggestions,
  })  : _analyzeText = analyzeText,
        _checkDuplicate = checkDuplicate,
        _getSmartSuggestions = getSmartSuggestions,
        super(const AiAnalysisState());

  // ── Full analysis ──────────────────────────────────────────────────────────

  Future<void> analyze({
    required String title,
    required String description,
    String? municipalityId,
    String? issueId,
    String? imageUrl,
  }) async {
    if (title.trim().length < 5) return;

    state = state.copyWith(isAnalyzing: true, clearError: true);

    final result = await _analyzeText(
      title: title,
      description: description,
      municipalityId: municipalityId,
      issueId: issueId,
      imageUrl: imageUrl,
    );

    result.fold(
      (failure) => state = state.copyWith(
        isAnalyzing: false,
        errorMessage: failure.message,
      ),
      (analysis) => state = state.copyWith(
        isAnalyzing: false,
        analysis: analysis,
      ),
    );
  }

  // ── Duplicate check ────────────────────────────────────────────────────────

  Future<void> checkForDuplicates({
    required String title,
    required String description,
    required double latitude,
    required double longitude,
    required String municipalityId,
    int radiusMetres = 500,
  }) async {
    if (title.trim().length < 5) return;

    state = state.copyWith(isCheckingDuplicate: true);

    final result = await _checkDuplicate(
      title: title,
      description: description,
      latitude: latitude,
      longitude: longitude,
      municipalityId: municipalityId,
      radiusMetres: radiusMetres,
    );

    result.fold(
      (_) => state = state.copyWith(isCheckingDuplicate: false),
      (dup) => state = state.copyWith(
        isCheckingDuplicate: false,
        duplicateResult: dup,
      ),
    );
  }

  // ── Smart suggestions ──────────────────────────────────────────────────────

  Future<void> fetchSuggestions({
    required String title,
    String? description,
    String? municipalityId,
  }) async {
    if (title.trim().length < 10) return;

    state = state.copyWith(isFetchingSuggestions: true);

    final result = await _getSmartSuggestions(
      title: title,
      description: description,
      municipalityId: municipalityId,
    );

    result.fold(
      (_) => state = state.copyWith(isFetchingSuggestions: false),
      (suggestions) => state = state.copyWith(
        isFetchingSuggestions: false,
        smartSuggestions: suggestions,
      ),
    );
  }

  // ── Dismiss helpers ────────────────────────────────────────────────────────

  void dismissSpamWarning() =>
      state = state.copyWith(analysis: state.analysis);

  void dismissDuplicateWarning() => state = state.copyWith(
        duplicateResult: const DuplicateCheckResult(
            hasPotentialDuplicates: false, candidates: []),
      );

  void reset() => state = const AiAnalysisState();
}
