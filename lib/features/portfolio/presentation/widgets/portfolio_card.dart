import 'package:flutter/material.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../documents/data/models/document_model.dart';
import '../../data/datasources/portfolio_remote_datasource.dart';
import '../../data/models/portfolio_model.dart';
import 'comments_bottom_sheet.dart';

class PortfolioCard extends StatefulWidget {
  final String token;
  final PortfolioModel portfolio;
  final String currentUserId;
  final VoidCallback? onPortfolioUpdated;

  const PortfolioCard({
    super.key,
    required this.token,
    required this.portfolio,
    required this.currentUserId,
    this.onPortfolioUpdated,
  });

  @override
  State<PortfolioCard> createState() => _PortfolioCardState();
}

class _PortfolioCardState extends State<PortfolioCard> {
  final _dataSource = PortfolioRemoteDataSourceImpl();
  late bool _isLiked;
  late int _likesCount;
  late int _commentsCount;
  bool _isLiking = false;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.portfolio.isLiked;
    _likesCount = widget.portfolio.likesCount;
    _commentsCount = widget.portfolio.commentsCount;
  }

  @override
  void didUpdateWidget(covariant PortfolioCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.portfolio.id != widget.portfolio.id) {
      _isLiked = widget.portfolio.isLiked;
      _likesCount = widget.portfolio.likesCount;
      _commentsCount = widget.portfolio.commentsCount;
    }
  }

  Future<void> _toggleLike() async {
    if (_isLiking) return;
    final previousState = _isLiked;
    final previousCount = _likesCount;

    // Optimistic update
    setState(() {
      _isLiked = !_isLiked;
      _likesCount += _isLiked ? 1 : -1;
      _isLiking = true;
    });

    try {
      if (_isLiked) {
        await _dataSource.likePortfolio(
          token: widget.token,
          portfolioId: widget.portfolio.id,
        );
      } else {
        await _dataSource.unlikePortfolio(
          token: widget.token,
          portfolioId: widget.portfolio.id,
        );
      }
    } catch (_) {
      // Rollback on network failure
      if (mounted) {
        setState(() {
          _isLiked = previousState;
          _likesCount = previousCount;
        });
      }
    } finally {
      if (mounted) setState(() => _isLiking = false);
    }
  }

  void _openComments() {
    CommentsBottomSheet.show(
      context,
      token: widget.token,
      portfolioId: widget.portfolio.id,
      currentUserId: widget.currentUserId,
      onCommentAdded: () {
        setState(() => _commentsCount += 1);
        widget.onPortfolioUpdated?.call();
      },
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  String? _resolvePhotoUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    return '${ApiConstants.baseUrl}$url';
  }

  @override
  Widget build(BuildContext context) {
    final authorAvatar = _resolvePhotoUrl(widget.portfolio.authorPhotoUrl);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.primaryGradient,
                  ),
                  child: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surface,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: authorAvatar != null
                        ? Image.network(
                            authorAvatar,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _avatarFallback(),
                          )
                        : _avatarFallback(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              widget.portfolio.authorUsername,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Portfolio',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _timeAgo(widget.portfolio.createdAt),
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.public_rounded,
                          size: 11, color: AppColors.accent),
                      SizedBox(width: 4),
                      Text(
                        'Public',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Caption
          if (widget.portfolio.caption.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                widget.portfolio.caption,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14.5,
                  height: 1.45,
                ),
              ),
            ),

          const SizedBox(height: 14),

          // Attached documents showcases
          if (widget.portfolio.documents.isNotEmpty ||
              widget.portfolio.documentIds.isNotEmpty)
            _buildAttachedDocuments(),

          const SizedBox(height: 8),

          // Divider
          Divider(
            color: AppColors.border.withValues(alpha: 0.5),
            height: 1,
          ),

          // Interaction Bar (Likes, Comments, Share)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                // Like Button
                InkWell(
                  onTap: _toggleLike,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    child: Row(
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            _isLiked
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            key: ValueKey(_isLiked),
                            color:
                                _isLiked ? AppColors.error : AppColors.textMuted,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$_likesCount',
                          style: TextStyle(
                            color: _isLiked
                                ? AppColors.error
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Comment Button
                InkWell(
                  onTap: _openComments,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline_rounded,
                          color: AppColors.textMuted,
                          size: 19,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$_commentsCount',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                // Share button
                IconButton(
                  icon: const Icon(Icons.share_outlined,
                      color: AppColors.textMuted, size: 19),
                  tooltip: 'Share Portfolio',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Portfolio link copied to clipboard!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachedDocuments() {
    final docs = widget.portfolio.documents;
    final docIds = widget.portfolio.documentIds;
    final count = docs.isNotEmpty ? docs.length : docIds.length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.attachment_rounded,
                  size: 15, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                'Attached Showcase Documents ($count)',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (docs.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: docs.map((doc) => _buildDocChip(doc)).toList(),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: docIds.map((id) => _buildDocIdChip(id)).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildDocChip(DocumentModel doc) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: doc.accentColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: doc.accentColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(doc.icon, size: 14, color: doc.accentColor),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 160),
            child: Text(
              doc.displayName,
              style: TextStyle(
                color: doc.accentColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocIdChip(String id) {
    final displayId = id.length > 8 ? id.substring(0, 8) : id;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.insert_drive_file_outlined,
              size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            'Document #$displayId',
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarFallback() {
    final initial = widget.portfolio.authorUsername.isNotEmpty
        ? widget.portfolio.authorUsername[0].toUpperCase()
        : 'U';
    return Center(
      child: Text(
        initial,
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}
