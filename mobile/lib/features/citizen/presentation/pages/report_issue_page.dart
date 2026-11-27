import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/di/providers.dart';
import '../../../../../core/utils/validators.dart';
import '../../../../../shared/widgets/app_button.dart';
import '../../../../../shared/widgets/app_text_field.dart';
import '../../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../../features/issues/presentation/providers/issues_provider.dart';
import '../../../../../features/ai/presentation/widgets/ai_analysis_banner.dart';
import '../../../../../features/ai/presentation/widgets/duplicate_warning_card.dart';
import '../../../../../features/ai/presentation/widgets/spam_warning_card.dart';
import '../../../../../features/ai/presentation/widgets/smart_suggestions_panel.dart';

class ReportIssuePage extends ConsumerStatefulWidget {
  const ReportIssuePage({super.key});

  @override
  ConsumerState<ReportIssuePage> createState() => _ReportIssuePageState();
}

class _ReportIssuePageState extends ConsumerState<ReportIssuePage> {
  final _formKey    = GlobalKey<FormState>();
  final _titleCtrl  = TextEditingController();
  final _descCtrl   = TextEditingController();
  final _addrCtrl   = TextEditingController();

  String?      _selectedCategoryId;
  String?      _selectedPriority = 'MEDIUM';
  double?      _lat;
  double?      _lng;
  bool         _anonymous  = false;
  bool         _gpsLoading = false;
  final List<File> _images = [];

  // AI debounce timer
  Timer? _aiDebounce;
  bool   _spamOverride = false;   // citizen dismissed spam warning

  static const _priorities = ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL'];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _addrCtrl.dispose();
    _aiDebounce?.cancel();
    super.dispose();
  }

  // ── AI analysis (debounced) ───────────────────────────────────────────────

  void _onTextChanged() {
    _aiDebounce?.cancel();
    _aiDebounce = Timer(const Duration(seconds: 2), () {
      final title = _titleCtrl.text.trim();
      final desc  = _descCtrl.text.trim();
      if (title.length < 10) return;

      final aiNotifier = ref.read(aiAnalysisNotifierProvider.notifier);

      // Smart suggestions (fast, while typing)
      aiNotifier.fetchSuggestions(
        title:        title,
        description:  desc.isNotEmpty ? desc : null,
      );

      // Full analysis only when both title + description are filled
      if (desc.length >= 20) {
        aiNotifier.analyze(
          title:       title,
          description: desc,
        );

        // Duplicate check if location is available
        if (_lat != null && _lng != null) {
          final auth = ref.read(authNotifierProvider);
          final municipalityId = auth is AuthAuthenticated
              ? auth.user.municipalityId
              : null;
          if (municipalityId != null) {
            aiNotifier.checkForDuplicates(
              title:          title,
              description:    desc,
              latitude:       _lat!,
              longitude:      _lng!,
              municipalityId: municipalityId,
            );
          }
        }
      }
    });
  }

  // ── Apply AI suggestion ───────────────────────────────────────────────────

  void _applyAiCategory() {
    final analysis = ref.read(aiAnalysisNotifierProvider).analysis;
    if (analysis?.suggestedCategoryId != null) {
      setState(() => _selectedCategoryId = analysis!.suggestedCategoryId);
    }
  }

  void _applyAiPriority() {
    final analysis = ref.read(aiAnalysisNotifierProvider).analysis;
    if (analysis?.suggestedPriority != null) {
      setState(() => _selectedPriority = analysis!.suggestedPriority);
    }
  }

  // ── GPS ──────────────────────────────────────────────────────────────────

  Future<void> _getLocation() async {    setState(() => _gpsLoading = true);
    try {
      final svc = await Geolocator.isLocationServiceEnabled();
      if (!svc) {
        _showSnack('Location services are disabled.');
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        _showSnack('Location permission denied.');
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
        _addrCtrl.text =
            '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}';
      });
    } catch (e) {
      _showSnack('Could not get location: $e');
    } finally {
      setState(() => _gpsLoading = false);
    }
  }

  // ── Images ───────────────────────────────────────────────────────────────

  Future<void> _pickImage(ImageSource source) async {
    if (_images.length >= AppConstants.maxIssuePhotos) {
      _showSnack('Maximum ${AppConstants.maxIssuePhotos} photos allowed.');
      return;
    }
    final picker = ImagePicker();
    final xFile  = await picker.pickImage(source: source, imageQuality: 80);
    if (xFile != null) {
      setState(() => _images.add(File(xFile.path)));
    }
  }

  // ── Submit ───────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedCategoryId == null) {
      _showSnack('Please select a category.');
      return;
    }
    if (_lat == null || _lng == null) {
      _showSnack('Please set the issue location.');
      return;
    }

    // Block submission if AI flagged spam and citizen hasn't overridden
    final aiState = ref.read(aiAnalysisNotifierProvider);
    if (aiState.hasSpamWarning && !_spamOverride) {
      _showSnack('Please review the spam warning before submitting.');
      return;
    }

    await ref.read(reportIssueNotifierProvider.notifier).submit(
      title:       _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      categoryId:  _selectedCategoryId!,
      latitude:    _lat!,
      longitude:   _lng!,
      address:     _addrCtrl.text.trim(),
      priority:    _selectedPriority,
      anonymous:   _anonymous,
      images:      _images,
    );
  }

  void _showSnack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final state  = ref.watch(reportIssueNotifierProvider);
    final cats   = ref.watch(categoriesNotifierProvider).valueOrNull ?? [];
    final theme  = Theme.of(context);

    // Wire text controllers to AI debounce (once)
    _titleCtrl.removeListener(_onTextChanged);
    _titleCtrl.addListener(_onTextChanged);
    _descCtrl.removeListener(_onTextChanged);
    _descCtrl.addListener(_onTextChanged);

    // React to submission result
    ref.listen<ReportIssueState>(reportIssueNotifierProvider, (_, next) {
      if (next is ReportIssueSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'Issue submitted! Tracking ID: ${next.issue.trackingId}'),
          duration: const Duration(seconds: 4),
        ));
        ref.read(reportIssueNotifierProvider.notifier).reset();
        ref.read(aiAnalysisNotifierProvider.notifier).reset();
        // Refresh my issues and feed
        ref.read(myIssuesNotifierProvider.notifier).refresh();
        ref.read(feedNotifierProvider.notifier).refresh();
        context.pop();
      } else if (next is ReportIssueFailure) {
        _showSnack(next.failure.message);
        ref.read(reportIssueNotifierProvider.notifier).reset();
      }
    });

    final isLoading = state is ReportIssueLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Report Issue')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Category ────────────────────────────────────────
                Text('Category *', style: theme.textTheme.labelLarge),
                const Gap(8),
                cats.isEmpty
                    ? const LinearProgressIndicator()
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: cats.map((c) {
                          final id   = c['id']   as String;
                          final name = c['name'] as String? ?? '';
                          final sel  = _selectedCategoryId == id;
                          return ChoiceChip(
                            label:    Text(name),
                            selected: sel,
                            onSelected: (_) =>
                                setState(() => _selectedCategoryId = id),
                          );
                        }).toList(),
                      ),
                const Gap(16),

                // ── Title ────────────────────────────────────────────
                AppTextField(
                  controller:      _titleCtrl,
                  label:           'Title *',
                  hint:            'Brief description of the issue',
                  textInputAction: TextInputAction.next,
                  maxLength:       300,
                  validator: (v) =>
                      Validators.required(v, label: 'Title'),
                ),
                const Gap(12),

                // ── Description ──────────────────────────────────────
                AppTextField(
                  controller:      _descCtrl,
                  label:           'Description *',
                  hint:            'Describe the issue in detail…',
                  maxLines:        4,
                  maxLength:       2000,
                  textInputAction: TextInputAction.newline,
                  validator:       Validators.issueDescription,
                ),
                const Gap(8),

                // ── Smart suggestions (real-time) ─────────────────────
                const SmartSuggestionsPanel(),

                // ── Duplicate warning ─────────────────────────────────
                DuplicateWarningCard(
                  onViewCandidate: (candidate) =>
                      context.push('/issues/${candidate.issueId}'),
                ),

                // ── AI analysis banner ────────────────────────────────
                AiAnalysisBanner(
                  onAcceptCategory: _applyAiCategory,
                  onAcceptPriority: _applyAiPriority,
                ),

                // ── Spam warning ──────────────────────────────────────
                SpamWarningCard(
                  onProceedAnyway: () {
                    setState(() => _spamOverride = true);
                    ref.read(aiAnalysisNotifierProvider.notifier).dismissSpamWarning();
                  },
                ),

                const Gap(4),

                // ── Location ──────────────────────────────────────────
                Text('Location *', style: theme.textTheme.labelLarge),
                const Gap(8),
                Row(children: [
                  Expanded(
                    child: AppTextField(
                      controller: _addrCtrl,
                      label:      'Address',
                      hint:       'Tap GPS to auto-fill',
                      readOnly:   false,
                      prefixIcon: const Icon(Icons.location_on_outlined),
                    ),
                  ),
                  const Gap(8),
                  FilledButton.tonal(
                    onPressed: _gpsLoading ? null : _getLocation,
                    child: _gpsLoading
                        ? const SizedBox.square(
                            dimension: 20,
                            child:
                                CircularProgressIndicator(strokeWidth: 2))
                        : const Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.gps_fixed_rounded, size: 18),
                            Gap(4),
                            Text('GPS'),
                          ]),
                  ),
                ]),
                if (_lat != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'lat: ${_lat!.toStringAsFixed(5)}, '
                      'lng: ${_lng!.toStringAsFixed(5)}',
                      style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary),
                    ),
                  ),
                const Gap(16),

                // ── Priority ──────────────────────────────────────────
                Text('Priority', style: theme.textTheme.labelLarge),
                const Gap(8),
                SegmentedButton<String>(
                  segments: _priorities
                      .map((p) => ButtonSegment(value: p, label: Text(p)))
                      .toList(),
                  selected:    {_selectedPriority ?? 'MEDIUM'},
                  onSelectionChanged: (s) =>
                      setState(() => _selectedPriority = s.first),
                ),
                const Gap(16),

                // ── Photos ────────────────────────────────────────────
                Row(children: [
                  Text('Photos', style: theme.textTheme.labelLarge),
                  const Spacer(),
                  Text('${_images.length}/${AppConstants.maxIssuePhotos}',
                      style: theme.textTheme.labelSmall),
                ]),
                const Gap(8),
                SizedBox(
                  height: 90,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      // Add photo buttons
                      _AddPhotoButton(
                        icon:    Icons.camera_alt_rounded,
                        label:   'Camera',
                        onTap:   () => _pickImage(ImageSource.camera),
                      ),
                      _AddPhotoButton(
                        icon:    Icons.photo_library_rounded,
                        label:   'Gallery',
                        onTap:   () => _pickImage(ImageSource.gallery),
                      ),
                      // Preview picked images
                      ..._images.asMap().entries.map((e) => Stack(
                            children: [
                              Container(
                                width:  80,
                                height: 80,
                                margin: const EdgeInsets.only(
                                    right: 8, bottom: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  image: DecorationImage(
                                    image: FileImage(e.value),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                top:   0,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () => setState(
                                      () => _images.removeAt(e.key)),
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color:  Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close,
                                        size: 16, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          )),
                    ],
                  ),
                ),
                const Gap(16),

                // ── Anonymous toggle ─────────────────────────────────
                SwitchListTile(
                  value:    _anonymous,
                  onChanged: (v) => setState(() => _anonymous = v),
                  title:    const Text('Submit anonymously'),
                  subtitle: const Text(
                      'Your name won\'t be shown publicly'),
                  contentPadding: EdgeInsets.zero,
                ),
                const Gap(24),

                // ── Submit ────────────────────────────────────────────
                AppButton(
                  label:     'Submit Report',
                  onPressed: _submit,
                  isLoading: isLoading,
                  icon: const Icon(Icons.send_rounded, size: 18),
                ),
                const Gap(16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddPhotoButton extends StatelessWidget {
  const _AddPhotoButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData  icon;
  final String    label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width:  80,
        height: 80,
        margin: const EdgeInsets.only(right: 8, bottom: 8),
        decoration: BoxDecoration(
          border: Border.all(
              color: theme.colorScheme.outline, style: BorderStyle.solid),
          borderRadius: BorderRadius.circular(8),
          color: theme.colorScheme.surfaceContainerHighest,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: 28),
            const Gap(4),
            Text(label, style: theme.textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}
