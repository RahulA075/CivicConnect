import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/date_utils.dart';
import '../../../../../shared/widgets/status_badge.dart';
import '../../../../../features/issues/domain/entities/issue_entity.dart';

class IssueCard extends StatelessWidget {
  const IssueCard({
    super.key,
    required this.issue,
    required this.onTap,
    this.onUpvote,
    this.onBookmark,
    this.isBookmarked = false,
    this.compact       = false,
  });

  final IssueEntity  issue;
  final VoidCallback onTap;
  final VoidCallback? onUpvote;
  final VoidCallback? onBookmark;
  final bool          isBookmarked;
  final bool          compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Preview image ────────────────────────────────────────
            if (issue.imageUrls.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12)),
                child: CachedNetworkImage(
                  imageUrl:   issue.imageUrls.first,
                  height:     160,
                  width:      double.infinity,
                  fit:        BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(
                    height: 160,
                    color:  theme.colorScheme.surfaceContainerHighest,
                    child:  const Icon(Icons.broken_image_outlined, size: 40),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Category + status row ──────────────────────────
                  Row(
                    children: [
                      _CategoryChip(
                        name:  issue.categoryName,
                        color: _hexColor(issue.categoryColor),
                      ),
                      const Spacer(),
                      StatusBadge.status(issue.status),
                      if (issue.isOverdue) ...[
                        const Gap(6),
                        StatusBadge(
                            label: 'OVERDUE',
                            color: AppColors.statusOverdue),
                      ],
                    ],
                  ),
                  const Gap(8),
                  // ── Title ─────────────────────────────────────────
                  Text(
                    issue.title,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (!compact) ...[
                    const Gap(4),
                    Text(
                      issue.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const Gap(8),
                  // ── Address ───────────────────────────────────────
                  if (issue.address.isNotEmpty)
                    Row(children: [
                      Icon(Icons.location_on_outlined,
                          size: 14,
                          color: theme.colorScheme.onSurfaceVariant),
                      const Gap(4),
                      Expanded(
                        child: Text(
                          issue.address,
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ]),
                  const Gap(8),
                  // ── Footer ────────────────────────────────────────
                  Row(children: [
                    // Upvote
                    GestureDetector(
                      onTap: onUpvote,
                      child: Row(children: [
                        Icon(
                          issue.isUpvotedByMe
                              ? Icons.thumb_up_rounded
                              : Icons.thumb_up_outlined,
                          size:  16,
                          color: issue.isUpvotedByMe
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                        const Gap(4),
                        Text(
                          '${issue.upvoteCount}',
                          style: theme.textTheme.labelSmall,
                        ),
                      ]),
                    ),
                    const Gap(12),
                    Icon(Icons.comment_outlined,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant),
                    const Gap(4),
                    Text('${issue.commentCount}',
                        style: theme.textTheme.labelSmall),
                    const Spacer(),
                    // Tracking ID
                    Text(
                      issue.trackingId,
                      style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600),
                    ),
                    const Gap(8),
                    // Bookmark
                    GestureDetector(
                      onTap: onBookmark,
                      child: Icon(
                        isBookmarked
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_outline_rounded,
                        size: 18,
                        color: isBookmarked
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Gap(8),
                    // Time
                    Text(
                      AppDateUtils.timeAgo(issue.createdAt),
                      style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _hexColor(String hex) {
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return AppColors.primary;
    }
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.name, required this.color});
  final String name;
  final Color  color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color:        color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          name,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color, fontWeight: FontWeight.w600),
        ),
      );
}
