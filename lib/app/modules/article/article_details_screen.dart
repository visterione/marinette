import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:marinette/app/data/models/article.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:marinette/app/data/services/auth_service.dart';
import 'package:share_plus/share_plus.dart';

class ArticleDetailsScreen extends StatefulWidget {
  final Article article;

  const ArticleDetailsScreen({
    super.key,
    required this.article,
  });

  @override
  State<ArticleDetailsScreen> createState() => _ArticleDetailsScreenState();
}

class _ArticleDetailsScreenState extends State<ArticleDetailsScreen> {
  final AuthService _authService = Get.find<AuthService>();
  bool _isFavorite = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkIfFavorite();
  }

  // Перевірка, чи є стаття в обраному
  Future<void> _checkIfFavorite() async {
    if (_authService.currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_authService.currentUser!.uid)
          .collection('favorites')
          .doc(widget.article.id)
          .get();

      setState(() {
        _isFavorite = docSnapshot.exists;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error checking if article is favorite: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Додавання/видалення статті з обраного
  Future<void> _toggleFavorite() async {
    if (_authService.currentUser == null) {
      Get.snackbar(
        'info'.tr,
        'login_to_add_favorites'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(_authService.currentUser!.uid);

      final favRef = userRef.collection('favorites').doc(widget.article.id);

      if (_isFavorite) {
        // Видалення з обраного
        await favRef.delete();

        Get.snackbar(
          'success'.tr,
          'article_removed_from_favorites'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        // Додавання до обраного
        await favRef.set({
          'articleId': widget.article.id,
          'titleKey': widget.article.titleKey,
          'descriptionKey': widget.article.descriptionKey,
          'imageUrl': widget.article.imageUrl,
          'contentKey': widget.article.contentKey,
          'publishedAt': widget.article.publishedAt.millisecondsSinceEpoch,
          'authorNameKey': widget.article.authorNameKey,
          'authorAvatarUrl': widget.article.authorAvatarUrl,
          'addedAt': DateTime.now().millisecondsSinceEpoch,
        });

        Get.snackbar(
          'success'.tr,
          'article_added_to_favorites'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
      }

      setState(() {
        _isFavorite = !_isFavorite;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
      Get.snackbar(
        'error'.tr,
        'error_updating_favorites'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getFullContent() {
    switch (widget.article.id) {
      case '1':
        return 'article_1_full'.tr;
      case '2':
        return 'article_2_full'.tr;
      case '3':
        return 'article_3_full'.tr;
      case '4':
        return 'article_4_full'.tr;
      case '5':
        return 'article_5_full'.tr;
      case '6':
        return 'article_6_full'.tr;
      case 'l1':
        return 'lifehack_2_full'.tr;
      case 'l2':
        return 'lifehack_1_full'.tr;
      case 'l3':
        return 'lifehack_3_full'.tr;
      case 'l4':
        return 'lifehack_4_full'.tr;
      case 'l5':
        return 'lifehack_5_full'.tr;
      case 'l6':
        return 'lifehack_6_full'.tr;
      case 'g1':
        return 'guide_1_full'.tr;
      case 'g2':
        return 'guide_2_full'.tr;
      case 'g3':
        return 'guide_3_full'.tr;
      case 'g4':
        return 'guide_4_full'.tr;
      case 'g5':
        return 'guide_5_full'.tr;
      case 'g6':
        return 'guide_6_full'.tr;
      default:
        return widget.article.contentKey.tr;
    }
  }

  int _calculateReadTime() {
    const wordsPerMinute = 120;
    final fullContent = _getFullContent();
    final wordCount = fullContent.split(RegExp(r'\s+')).length;
    return (wordCount / wordsPerMinute).ceil();
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) return 'today'.tr;
    if (difference == 1) return 'yesterday'.tr;
    return '$difference ${'days_ago'.tr}';
  }

  // Поділитися статтею
  Future<void> _shareArticle() async {
    final title = widget.article.titleKey.tr;
    final content = _getFullContent();

    // Ділимося коротким уривком статті
    final previewContent = content.length > 100
        ? '${content.substring(0, 100)}...'
        : content;

    await Share.share('$title\n\n$previewContent');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            floating: false,
            pinned: true,
            actions: [
              // Кнопка "Поділитися"
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: _shareArticle,
              ),
              // Кнопка "Додати до обраного"
              IconButton(
                icon: _isLoading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : Icon(_isFavorite ? Icons.bookmark : Icons.bookmark_border),
                onPressed: _isLoading ? null : _toggleFavorite,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'article_image_${widget.article.id}',
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: widget.article.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black54],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.article.titleKey.tr,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        child: ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: widget.article.authorAvatarUrl,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            ),
                            errorWidget: (context, error, stackTrace) =>
                            const Icon(Icons.person),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.article.authorNameKey.tr,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _formatDate(widget.article.publishedAt),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_calculateReadTime()} ${'min_read'.tr}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _getFullContent(),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}