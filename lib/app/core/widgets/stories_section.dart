import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:marinette/app/data/models/story.dart';

class StoriesSection extends StatelessWidget {
  final List<Story> stories;
  final Function(Story) onStoryTap;

  const StoriesSection({
    super.key,
    required this.stories,
    required this.onStoryTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: stories.length,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          final story = stories[index];
          return _StoryItem(
            story: story,
            onTap: () => onStoryTap(story),
          );
        },
      ),
    );
  }
}

class _StoryItem extends StatelessWidget {
  final Story story;
  final VoidCallback onTap;

  const _StoryItem({
    required this.story,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Container(
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: story.isViewed
                    ? null
                    : const LinearGradient(
                  colors: [Colors.pink, Colors.purple],
                ),
              ),
              padding: const EdgeInsets.all(2),
              child: CircleAvatar(
                backgroundImage: NetworkImage(story.previewImageUrl.tr),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              story.title.tr,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}