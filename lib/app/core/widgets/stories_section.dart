// lib/app/core/widgets/stories_section.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:marinette/app/data/models/story.dart';
import 'package:get/get.dart';

class StoriesSection extends StatelessWidget {
  final List<Story> stories;
  final Function(Story) onStoryTap;

  const StoriesSection({
    Key? key,
    required this.stories,
    required this.onStoryTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140, // Increased height to accommodate larger circles and text
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: stories.length,
        itemBuilder: (context, index) {
          final story = stories[index];
          return _buildStoryItem(context, story);
        },
      ),
    );
  }

  Widget _buildStoryItem(BuildContext context, Story story) {
    return GestureDetector(
      onTap: () => onStoryTap(story),
      child: Container(
        width: 100, // Increased width for the story item container
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          children: [
            // Story circle with larger size
            Container(
              width: 100, // Significantly larger circle
              height: 100, // Significantly larger circle
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: story.isViewed ? Colors.grey : Colors.pink,
                  width: 3, // Thicker border
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: ClipOval(
                  child: story.previewImageUrl.isNotEmpty
                      ? CachedNetworkImage(
                    imageUrl: story.previewImageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[200],
                      child: const Icon(
                        Icons.error_outline,
                        size: 30, // Larger icon
                        color: Colors.grey,
                      ),
                    ),
                  )
                      : Container(
                    color: Colors.grey[200],
                    child: const Icon(
                      Icons.image,
                      size: 30, // Larger icon
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ),

            // Added more space between circle and text
            const SizedBox(height: 8),

            // Story title with overflow handling
            Expanded(
              child: Text(
                story.title.tr,
                style: TextStyle(
                  fontSize: 13, // Slightly larger font
                  fontWeight: FontWeight.w500,
                  color: story.isViewed ? Colors.grey : null,
                ),
                textAlign: TextAlign.center,
                maxLines: 2, // Allow two lines for title
                overflow: TextOverflow.ellipsis, // Add ellipsis for text overflow
              ),
            ),
          ],
        ),
      ),
    );
  }
}