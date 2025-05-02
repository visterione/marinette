// lib/app/data/scripts/firestore_import.dart
// Этот файл можно использовать для импорта данных в Firestore

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:marinette/firebase_options.dart';

// Замените "your-project-id" на ID вашего проекта Firebase
const String PROJECT_ID = "beautymarine-6355a";

// Данные статей
final List<Map<String, dynamic>> articles = [
  {
    "id": "1",
    "titleKey": "article_1_title",
    "descriptionKey": "article_1_desc",
    "contentKey": "article_1_full",
    "imageUrl": "https://firebasestorage.googleapis.com/v0/b/beautymarine-6355a.firebasestorage.app/o/articles%2Farticle1.jpg?alt=media&token=6f121680-2516-43ae-b821-6ce9a5fa4d3d",
    "publishedAt": Timestamp.fromDate(DateTime.now().subtract(Duration(days: 2))),
    "authorNameKey": "author1",
    "authorAvatarUrl": "",
    "type": "article",
    "createdAt": FieldValue.serverTimestamp(),
  },
  {
    "id": "2",
    "titleKey": "article_2_title",
    "descriptionKey": "article_2_desc",
    "contentKey": "article_2_full",
    "imageUrl": "https://firebasestorage.googleapis.com/v0/b/beautymarine-6355a.firebasestorage.app/o/articles%2Farticle2.jpg?alt=media&token=4d8a955d-e656-4a6b-904e-da3b222fbf9a",
    "publishedAt": Timestamp.fromDate(DateTime.now().subtract(Duration(days: 5))),
    "authorNameKey": "author2",
    "authorAvatarUrl": "",
    "type": "article",
    "createdAt": FieldValue.serverTimestamp(),
  },
  {
    "id": "3",
    "titleKey": "article_3_title",
    "descriptionKey": "article_3_desc",
    "contentKey": "article_3_full",
    "imageUrl": "https://firebasestorage.googleapis.com/v0/b/beautymarine-6355a.firebasestorage.app/o/articles%2Farticle3.jpg?alt=media&token=d696c172-1eb8-4a4d-921e-0f81a7619c1b",
    "publishedAt": Timestamp.fromDate(DateTime.now().subtract(Duration(days: 7))),
    "authorNameKey": "author3",
    "authorAvatarUrl": "",
    "type": "article",
    "createdAt": FieldValue.serverTimestamp(),
  },
  {
    "id": "4",
    "titleKey": "article_4_title",
    "descriptionKey": "article_4_desc",
    "contentKey": "article_4_full",
    "imageUrl": "https://firebasestorage.googleapis.com/v0/b/beautymarine-6355a.firebasestorage.app/o/articles%2Farticle4.jpg?alt=media&token=7bd7fe0b-6799-4d57-9c67-474745379af0",
    "publishedAt": Timestamp.fromDate(DateTime.now().subtract(Duration(days: 8))),
    "authorNameKey": "author4",
    "authorAvatarUrl": "",
    "type": "article",
    "createdAt": FieldValue.serverTimestamp(),
  },
  {
    "id": "5",
    "titleKey": "article_5_title",
    "descriptionKey": "article_5_desc",
    "contentKey": "article_5_full",
    "imageUrl": "https://firebasestorage.googleapis.com/v0/b/beautymarine-6355a.firebasestorage.app/o/articles%2Farticle5.jpg?alt=media&token=e97cb5fe-dc85-4174-946d-d7bf12ee346f",
    "publishedAt": Timestamp.fromDate(DateTime.now().subtract(Duration(days: 8))),
    "authorNameKey": "author5",
    "authorAvatarUrl": "",
    "type": "article",
    "createdAt": FieldValue.serverTimestamp(),
  },
  {
    "id": "6",
    "titleKey": "article_6_title",
    "descriptionKey": "article_6_desc",
    "contentKey": "article_6_full",
    "imageUrl": "https://firebasestorage.googleapis.com/v0/b/beautymarine-6355a.firebasestorage.app/o/articles%2Farticle6.jpg?alt=media&token=034e87e5-7c94-4076-bb86-d21efb89020f",
    "publishedAt": Timestamp.fromDate(DateTime.now().subtract(Duration(days: 9))),
    "authorNameKey": "author6",
    "authorAvatarUrl": "",
    "type": "article",
    "createdAt": FieldValue.serverTimestamp(),
  },
];

// Данные лайфхаков
final List<Map<String, dynamic>> lifehacks = [
  {
    "id": "l1",
    "titleKey": "lifehack_1_title",
    "descriptionKey": "lifehack_1_desc",
    "contentKey": "lifehack_1_full",
    "imageUrl": "https://firebasestorage.googleapis.com/v0/b/beautymarine-6355a.firebasestorage.app/o/articles%2Flifehack1.jpg?alt=media&token=0b1da5d6-4cb7-43fe-8ad8-5cef9a22588d",
    "publishedAt": Timestamp.fromDate(DateTime.now().subtract(Duration(days: 3))),
    "authorNameKey": "author2",
    "authorAvatarUrl": "",
    "type": "lifehack",
    "createdAt": FieldValue.serverTimestamp(),
  },
  {
    "id": "l2",
    "titleKey": "lifehack_2_title",
    "descriptionKey": "lifehack_2_desc",
    "contentKey": "lifehack_2_full",
    "imageUrl": "https://firebasestorage.googleapis.com/v0/b/beautymarine-6355a.firebasestorage.app/o/articles%2Flifehack2.jpg?alt=media&token=532eacd1-cfd0-45e4-95f0-ea03011723fd",
    "publishedAt": Timestamp.fromDate(DateTime.now().subtract(Duration(days: 4))),
    "authorNameKey": "author4",
    "authorAvatarUrl": "",
    "type": "lifehack",
    "createdAt": FieldValue.serverTimestamp(),
  },
  {
    "id": "l3",
    "titleKey": "lifehack_3_title",
    "descriptionKey": "lifehack_3_desc",
    "contentKey": "lifehack_3_full",
    "imageUrl": "https://firebasestorage.googleapis.com/v0/b/beautymarine-6355a.firebasestorage.app/o/articles%2Flifehack3.jpg?alt=media&token=e6a3ab26-4cab-4ecc-810f-810172b68aa9",
    "publishedAt": Timestamp.fromDate(DateTime.now().subtract(Duration(days: 6))),
    "authorNameKey": "author6",
    "authorAvatarUrl": "",
    "type": "lifehack",
    "createdAt": FieldValue.serverTimestamp(),
  },
  {
    "id": "l4",
    "titleKey": "lifehack_4_title",
    "descriptionKey": "lifehack_4_desc",
    "contentKey": "lifehack_4_full",
    "imageUrl": "https://firebasestorage.googleapis.com/v0/b/beautymarine-6355a.firebasestorage.app/o/articles%2Flifehack4.jpg?alt=media&token=ed109491-ed71-40d9-bd7f-d6c52abb5ae8",
    "publishedAt": Timestamp.fromDate(DateTime.now().subtract(Duration(days: 7))),
    "authorNameKey": "author1",
    "authorAvatarUrl": "",
    "type": "lifehack",
    "createdAt": FieldValue.serverTimestamp(),
  },
  {
    "id": "l5",
    "titleKey": "lifehack_5_title",
    "descriptionKey": "lifehack_5_desc",
    "contentKey": "lifehack_5_full",
    "imageUrl": "https://firebasestorage.googleapis.com/v0/b/beautymarine-6355a.firebasestorage.app/o/articles%2Flifehack5.jpg?alt=media&token=9a81db68-9e99-42fe-91a1-98a4b184edc5",
    "publishedAt": Timestamp.fromDate(DateTime.now().subtract(Duration(days: 7))),
    "authorNameKey": "author3",
    "authorAvatarUrl": "",
    "type": "lifehack",
    "createdAt": FieldValue.serverTimestamp(),
  },
  {
    "id": "l6",
    "titleKey": "lifehack_6_title",
    "descriptionKey": "lifehack_6_desc",
    "contentKey": "lifehack_6_full",
    "imageUrl": "https://firebasestorage.googleapis.com/v0/b/beautymarine-6355a.firebasestorage.app/o/articles%2Flifehack6.jpg?alt=media&token=45672734-f678-4c0f-bec6-630056ea7a2d",
    "publishedAt": Timestamp.fromDate(DateTime.now().subtract(Duration(days: 8))),
    "authorNameKey": "author5",
    "authorAvatarUrl": "",
    "type": "lifehack",
    "createdAt": FieldValue.serverTimestamp(),
  },
];

// Данные гайдов
final List<Map<String, dynamic>> guides = [
  {
    "id": "g1",
    "titleKey": "guide_1_title",
    "descriptionKey": "guide_1_desc",
    "contentKey": "guide_1_full",
    "imageUrl": "https://firebasestorage.googleapis.com/v0/b/beautymarine-6355a.firebasestorage.app/o/articles%2Fguide1.jpg?alt=media&token=f687a163-9446-4e1e-a728-cfb626fc4e4b",
    "publishedAt": Timestamp.fromDate(DateTime.now().subtract(Duration(days: 1))),
    "authorNameKey": "author6",
    "authorAvatarUrl": "",
    "type": "guide",
    "createdAt": FieldValue.serverTimestamp(),
  },
  {
    "id": "g2",
    "titleKey": "guide_2_title",
    "descriptionKey": "guide_2_desc",
    "contentKey": "guide_2_full",
    "imageUrl": "https://firebasestorage.googleapis.com/v0/b/beautymarine-6355a.firebasestorage.app/o/articles%2Fguide2.jpg?alt=media&token=e002b440-ef6e-4ec1-809f-88e2a94948d4",
    "publishedAt": Timestamp.fromDate(DateTime.now().subtract(Duration(days: 4))),
    "authorNameKey": "author5",
    "authorAvatarUrl": "",
    "type": "guide",
    "createdAt": FieldValue.serverTimestamp(),
  },
  {
    "id": "g3",
    "titleKey": "guide_3_title",
    "descriptionKey": "guide_3_desc",
    "contentKey": "guide_3_full",
    "imageUrl": "https://firebasestorage.googleapis.com/v0/b/beautymarine-6355a.firebasestorage.app/o/articles%2Fguide3.jpg?alt=media&token=7b27fa96-f63a-4310-9b83-d5efc678e275",
    "publishedAt": Timestamp.fromDate(DateTime.now().subtract(Duration(days: 6))),
    "authorNameKey": "author4",
    "authorAvatarUrl": "",
    "type": "guide",
    "createdAt": FieldValue.serverTimestamp(),
  },
  {
    "id": "g4",
    "titleKey": "guide_4_title",
    "descriptionKey": "guide_4_desc",
    "contentKey": "guide_4_full",
    "imageUrl": "https://firebasestorage.googleapis.com/v0/b/beautymarine-6355a.firebasestorage.app/o/articles%2Fguide4.jpg?alt=media&token=88286ba5-e8c0-4fee-8c40-bce06c79f431",
    "publishedAt": Timestamp.fromDate(DateTime.now().subtract(Duration(days: 7))),
    "authorNameKey": "author3",
    "authorAvatarUrl": "",
    "type": "guide",
    "createdAt": FieldValue.serverTimestamp(),
  },
  {
    "id": "g5",
    "titleKey": "guide_5_title",
    "descriptionKey": "guide_5_desc",
    "contentKey": "guide_5_full",
    "imageUrl": "https://firebasestorage.googleapis.com/v0/b/beautymarine-6355a.firebasestorage.app/o/articles%2Fguide5.jpg?alt=media&token=bbbcb6d3-dbdc-4d02-a700-ad35a80cc4f7",
    "publishedAt": Timestamp.fromDate(DateTime.now().subtract(Duration(days: 8))),
    "authorNameKey": "author2",
    "authorAvatarUrl": "",
    "type": "guide",
    "createdAt": FieldValue.serverTimestamp(),
  },
  {
    "id": "g6",
    "titleKey": "guide_6_title",
    "descriptionKey": "guide_6_desc",
    "contentKey": "guide_6_full",
    "imageUrl": "https://firebasestorage.googleapis.com/v0/b/beautymarine-6355a.firebasestorage.app/o/articles%2Fguide6.jpg?alt=media&token=c39c6a0e-f529-495d-8f25-ded2474d95ed",
    "publishedAt": Timestamp.fromDate(DateTime.now().subtract(Duration(days: 9))),
    "authorNameKey": "author1",
    "authorAvatarUrl": "",
    "type": "guide",
    "createdAt": FieldValue.serverTimestamp(),
  },
];

// Данные историй
final List<Map<String, dynamic>> stories = [
  {
    "id": "story1",
    "title": "stories_A",
    "imageUrls": [
      "https://firebasestorage.googleapis.com/v0/b/beautymarine-6355a.firebasestorage.app/o/stories%2Fstory1%2F00.png?alt=media&token=a08530be-2d8a-4a7c-a17c-a0c555d9bd0e",
      "https://firebasestorage.googleapis.com/v0/b/beautymarine-6355a.firebasestorage.app/o/stories%2Fstory1%2F01.png?alt=media&token=b566fe3a-90ea-4987-84ff-d96aa39f737b",
      "https://firebasestorage.googleapis.com/v0/b/beautymarine-6355a.firebasestorage.app/o/stories%2Fstory1%2F02.png?alt=media&token=867722a7-58b2-4249-8c8f-5bb9947d0ec7",
      "https://firebasestorage.googleapis.com/v0/b/beautymarine-6355a.firebasestorage.app/o/stories%2Fstory1%2F03.png?alt=media&token=d2b4fddf-7e8b-4472-930e-653d5fb17703",
      "https://firebasestorage.googleapis.com/v0/b/beautymarine-6355a.firebasestorage.app/o/stories%2Fstory1%2F04.png?alt=media&token=aa3e9c52-0e44-416c-b70e-cb61f7d413d4",
      "https://firebasestorage.googleapis.com/v0/b/beautymarine-6355a.firebasestorage.app/o/stories%2Fstory1%2F05.png?alt=media&token=feec1595-e78e-4f90-abd8-ba9dcd2802c5",
      "https://firebasestorage.googleapis.com/v0/b/beautymarine-6355a.firebasestorage.app/o/stories%2Fstory1%2F06.png?alt=media&token=baf22240-8d26-4049-b7e1-3e89ec159239",
      "https://firebasestorage.googleapis.com/v0/b/beautymarine-6355a.firebasestorage.app/o/stories%2Fstory1%2F07.png?alt=media&token=46798cb2-8763-4868-871c-f19d5c2b7261",
      "https://firebasestorage.googleapis.com/v0/b/beautymarine-6355a.firebasestorage.app/o/stories%2Fstory1%2F08.png?alt=media&token=8ce5ad3e-7000-4675-9037-8f5e1ea34f42",
    ],
    "captions": ["", "", "", "", "", "", "", "", ""],
    "category": "makeup",
    "previewImageUrl": "https://firebasestorage.googleapis.com/v0/b/beautymarine-6355a.firebasestorage.app/o/stories%2Fstory1%2Fpreview.png?alt=media&token=d5fef15b-469c-4797-955a-a274bc58610c",
    "order": 1,
    "createdAt": FieldValue.serverTimestamp(),
  },
  {
    "id": "story2",
    "title": "stories_B",
    "imageUrls": [
      "https://firebasestorage.googleapis.com/v0/b/beautymarine-6355a.firebasestorage.app/o/stories%2Fstory2%2F00.png?alt=media&token=78452484-51ad-4ae1-926a-1e483d481e95",
      "https://firebasestorage.googleapis.com/v0/b/beautymarine-6355a.firebasestorage.app/o/stories%2Fstory2%2F01.png?alt=media&token=57ec3646-1687-4473-89cf-4364b9a465ba",
      "https://firebasestorage.googleapis.com/v0/b/beautymarine-6355a.firebasestorage.app/o/stories%2Fstory2%2F02.png?alt=media&token=67bf09f9-8963-49eb-8e1d-dfc225815015",
      "https://firebasestorage.googleapis.com/v0/b/beautymarine-6355a.firebasestorage.app/o/stories%2Fstory2%2F03.png?alt=media&token=4778444d-d9da-4682-b4b7-e188ef2fed13",
      "https://firebasestorage.googleapis.com/v0/b/beautymarine-6355a.firebasestorage.app/o/stories%2Fstory2%2F04.png?alt=media&token=b46cb210-a1fe-4911-b565-203e9aac2864",
      "https://firebasestorage.googleapis.com/v0/b/beautymarine-6355a.firebasestorage.app/o/stories%2Fstory2%2F05.png?alt=media&token=347c0b19-0fe8-4715-9fcf-1578e269aaf4",
      "https://firebasestorage.googleapis.com/v0/b/beautymarine-6355a.firebasestorage.app/o/stories%2Fstory2%2F06.png?alt=media&token=9e6990cf-c604-4cc4-aecd-e6c7c40c373c",
      "https://firebasestorage.googleapis.com/v0/b/beautymarine-6355a.firebasestorage.app/o/stories%2Fstory2%2F07.png?alt=media&token=72bc878f-cd2d-40a5-abd6-6efd50a48ca8",
      "https://firebasestorage.googleapis.com/v0/b/beautymarine-6355a.firebasestorage.app/o/stories%2Fstory2%2F08.png?alt=media&token=d1dc4210-17bf-4c6f-a36d-273df84ea8d5",
    ],
    "captions": ["", "", "", "", "", "", "", "", ""],
    "category": "skincare",
    "previewImageUrl": "https://firebasestorage.googleapis.com/v0/b/beautymarine-6355a.firebasestorage.app/o/stories%2Fstory2%2Fpreview.png?alt=media&token=38f3ef04-991d-4359-a7f3-313b52f9143b",
    "order": 2,
    "createdAt": FieldValue.serverTimestamp(),
  },
  {
    "id": "story3",
    "title": "stories_C",
    "imageUrls": [
      "https://firebasestorage.googleapis.com/v0/b/beautymarine-6355a.firebasestorage.app/o/stories%2Fstory3%2F00.png?alt=media&token=79dcd6e2-859e-4117-942d-61c7de7e667e",
      "https://firebasestorage.googleapis.com/v0/b/beautymarine-6355a.firebasestorage.app/o/stories%2Fstory3%2F01.png?alt=media&token=bff2978d-3f32-4a48-8c90-64a707323768",
      "https://firebasestorage.googleapis.com/v0/b/beautymarine-6355a.firebasestorage.app/o/stories%2Fstory3%2F02.png?alt=media&token=d7b3fc17-5979-4b02-98cb-a844ff835618",
      "https://firebasestorage.googleapis.com/v0/b/beautymarine-6355a.firebasestorage.app/o/stories%2Fstory3%2F03.png?alt=media&token=0486b2cb-43a3-4861-8292-2085a2360f4b",
      "https://firebasestorage.googleapis.com/v0/b/beautymarine-6355a.firebasestorage.app/o/stories%2Fstory3%2F04.png?alt=media&token=fbf2dd1e-776e-4e6d-af10-1bf0491ec420",
      "https://firebasestorage.googleapis.com/v0/b/beautymarine-6355a.firebasestorage.app/o/stories%2Fstory3%2F05.png?alt=media&token=e39f30b7-023d-40cc-908a-381c3e2fdad0",
    ],
    "captions": ["", "", "", "", "", ""],
    "category": "makeup",
    "previewImageUrl": "https://firebasestorage.googleapis.com/v0/b/beautymarine-6355a.firebasestorage.app/o/stories%2Fstory3%2Fpreview.png?alt=media&token=8dfefa67-3456-4c5d-985a-33de283e0162",
    "order": 3,
    "createdAt": FieldValue.serverTimestamp(),
  },
  {
    "id": "story4",
    "title": "stories_D",
    "imageUrls": [
      "https://firebasestorage.googleapis.com/v0/b/beautymarine-6355a.firebasestorage.app/o/stories%2Fstory4%2F00.png?alt=media&token=bdfb4aa2-f10a-4dfe-b986-3c531085bba6",
      "https://firebasestorage.googleapis.com/v0/b/beautymarine-6355a.firebasestorage.app/o/stories%2Fstory4%2F01.png?alt=media&token=6c026b2f-4d09-4651-8f61-3bb3bb59adb5",
      "https://firebasestorage.googleapis.com/v0/b/beautymarine-6355a.firebasestorage.app/o/stories%2Fstory4%2F02.png?alt=media&token=9b097112-49a1-49ed-a48d-36d6164c1bd8",
      "https://firebasestorage.googleapis.com/v0/b/beautymarine-6355a.firebasestorage.app/o/stories%2Fstory4%2F03.png?alt=media&token=e68dbfbc-7dc6-4251-9e37-cd907a7f6366",
      "https://firebasestorage.googleapis.com/v0/b/beautymarine-6355a.firebasestorage.app/o/stories%2Fstory4%2F04.png?alt=media&token=25c4b26f-6006-46d4-88db-5f888c0dd97b",
      "https://firebasestorage.googleapis.com/v0/b/beautymarine-6355a.firebasestorage.app/o/stories%2Fstory4%2F05.png?alt=media&token=1c2e4491-b118-49b7-96c2-c6fb4d4eca4b",
      "https://firebasestorage.googleapis.com/v0/b/beautymarine-6355a.firebasestorage.app/o/stories%2Fstory4%2F06.png?alt=media&token=3e070e5b-c9ac-4fdc-a1c0-abdf57a5386a",
    ],
    "captions": ["", "", "", "", "", "", ""],
    "category": "skincare",
    "previewImageUrl": "https://firebasestorage.googleapis.com/v0/b/beautymarine-6355a.firebasestorage.app/o/stories%2Fstory4%2Fpreview.png?alt=media&token=c881c096-0b55-4438-8742-ae8fb33ecc62",
    "order": 4,
    "createdAt": FieldValue.serverTimestamp(),
  },
  {
    "id": "story5",
    "title": "stories_E",
    "imageUrls": [
      "https://firebasestorage.googleapis.com/v0/b/beautymarine-6355a.firebasestorage.app/o/stories%2Fstory5%2F00.png?alt=media&token=7d5deb05-dd3d-4938-b670-c44782de4d0b",
      "https://firebasestorage.googleapis.com/v0/b/beautymarine-6355a.firebasestorage.app/o/stories%2Fstory5%2F01.png?alt=media&token=48ccb9e8-f64a-4d40-9667-0b507aa35a5b",
      "https://firebasestorage.googleapis.com/v0/b/beautymarine-6355a.firebasestorage.app/o/stories%2Fstory5%2F02.png?alt=media&token=6a49460b-7a13-4858-82b3-1de386d77e74",
      "https://firebasestorage.googleapis.com/v0/b/beautymarine-6355a.firebasestorage.app/o/stories%2Fstory5%2F03.png?alt=media&token=a0ab33c5-357e-48ae-8a52-34371877c077",
      "https://firebasestorage.googleapis.com/v0/b/beautymarine-6355a.firebasestorage.app/o/stories%2Fstory5%2F04.png?alt=media&token=2fd42f4a-ada8-42ca-8b47-da3d6d676e2b",
    ],
    "captions": ["", "", "", "", ""],
    "category": "makeup",
    "previewImageUrl": "https://firebasestorage.googleapis.com/v0/b/beautymarine-6355a.firebasestorage.app/o/stories%2Fstory5%2Fpreview.png?alt=media&token=72994c90-ae67-4cc2-8e4e-66dea2a1baf3",
    "order": 5,
    "createdAt": FieldValue.serverTimestamp(),
  },
];

// Функция для импорта данных в Firestore
Future<void> importDataToFirestore() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  // Импорт статей
  for (var article in articles) {
    await firestore.collection('articles').doc(article['id']).set(article);
    print('Imported article: ${article['id']}');
  }

  // Импорт лайфхаков
  for (var lifehack in lifehacks) {
    await firestore.collection('articles').doc(lifehack['id']).set(lifehack);
    print('Imported lifehack: ${lifehack['id']}');
  }

  // Импорт гайдов
  for (var guide in guides) {
    await firestore.collection('articles').doc(guide['id']).set(guide);
    print('Imported guide: ${guide['id']}');
  }

  // Импорт историй
  for (var story in stories) {
    await firestore.collection('stories').doc(story['id']).set(story);
    print('Imported story: ${story['id']}');
  }

  print('All data imported successfully!');
}

// Вызовите эту функцию для импорта данных
// importDataToFirestore();