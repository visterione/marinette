import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:marinette/app/data/models/face_analysis_result.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AnalysisResultScreen extends StatelessWidget {
  final String imagePath;
  final FaceAnalysisResult result;
  final String? heroTag;

  const AnalysisResultScreen({
    super.key,
    required this.imagePath,
    required this.result,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    final tag = heroTag ?? imagePath;
    final screenWidth = MediaQuery.of(context).size.width;
    final isRemoteImage = imagePath.contains('http://') ||
        imagePath.contains('https://') ||
        imagePath.contains('firebasestorage.googleapis.com');

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFDF2F8), Color(0xFFF5F3FF)],
            stops: [0.0, 1.0],
          ),
        ),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: screenWidth,
              floating: false,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'recommendations'.tr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                centerTitle: true,
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Hero(
                      tag: tag,
                      child: isRemoteImage
                          ? CachedNetworkImage(
                        imageUrl: imagePath,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(),
                        ),
                        errorWidget: (context, url, error) {
                          debugPrint('Error loading image: $error');
                          return Container(
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.broken_image,
                              size: 64,
                              color: Colors.grey,
                            ),
                          );
                        },
                      )
                          : Image.file(
                        File(imagePath),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          debugPrint('Error loading image: $error');
                          return Container(
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.broken_image,
                              size: 64,
                              color: Colors.grey,
                            ),
                          );
                        },
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
              actions: [],
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Card(
                    elevation: 8,
                    shadowColor: Colors.pink.withAlpha(76),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildTypeInfo('face_shape'.tr, result.faceShape),
                          Container(
                            height: 40,
                            width: 1,
                            color: Colors.grey.withAlpha(50),
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          _buildTypeInfo('color_type'.tr, result.colorType),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildRecommendationSection(
                    title: 'makeup_recommendations'.tr,
                    recommendations: result.makeupRecommendations,
                    icon: Icons.face,
                    color: Colors.pink,
                  ),
                  const SizedBox(height: 24),
                  _buildRecommendationSection(
                    title: 'hairstyle_recommendations'.tr,
                    recommendations: result.hairstyleRecommendations,
                    icon: Icons.content_cut,
                    color: Colors.purple,
                  ),
                  const SizedBox(height: 24),
                  _buildRecommendationSection(
                    title: 'skincare_recommendations'.tr,
                    recommendations: result.skincareRecommendations,
                    icon: Icons.spa,
                    color: Colors.pinkAccent,
                  ),
                  const SizedBox(height: 16),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeInfo(String label, String value) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationSection({
    required String title,
    required List<String> recommendations,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 8,
      shadowColor: color.withAlpha(76),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...recommendations.map((recommendation) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(top: 8, right: 12),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      recommendation,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}