import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:marinette/app/data/models/story.dart';

class StoriesSection extends StatelessWidget {
  final List<Story> stories;
  final Function(Story) onStoryTap;

  // Константи для налаштування розмірів
  static const double _storySize = 75.0;
  static const double _borderWidth = 3.0;
  static const double _sectionHeight = 130.0; // Збільшили висоту секції
  static const double _horizontalPadding = 8.0; // Зменшили бокові відступи
  static const double _storySpacing = 8.0; // Зменшили відступи між кружечками
  static const double _titleSpacing = 6.0; // Зменшили відступ до тексту
  static const double _fontSize = 12.0; // Зменшили розмір шрифту

  const StoriesSection({
    super.key,
    required this.stories,
    required this.onStoryTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox( // Замінили Container на SizedBox
      height: _sectionHeight,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: stories.length,
        padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding),
        itemBuilder: (context, index) => _StoryItem(
          story: stories[index],
          onTap: () => onStoryTap(stories[index]),
        ),
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
        width: StoriesSection._storySize,
        margin: const EdgeInsets.only(right: StoriesSection._storySpacing),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Додали для уникнення overflow
          children: [
            Container(
              height: StoriesSection._storySize,
              width: StoriesSection._storySize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: story.isViewed
                    ? null
                    : const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.pink, Colors.purple],
                ),
              ),
              padding: const EdgeInsets.all(StoriesSection._borderWidth),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: story.isViewed
                      ? Border.all(
                    color: Colors.grey.shade300,
                    width: StoriesSection._borderWidth,
                  )
                      : null,
                  image: DecorationImage(
                    image: NetworkImage(story.previewImageUrl.tr),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            SizedBox(height: StoriesSection._titleSpacing),
            Flexible( // Обгорнули текст у Flexible
              child: Text(
                story.title.tr,
                style: TextStyle(
                  fontSize: StoriesSection._fontSize,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}