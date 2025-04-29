// lib/app/modules/admin/migration_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:marinette/app/data/services/storage_migration_service.dart';
import 'package:marinette/app/data/services/storage_service.dart';

class MigrationScreen extends StatefulWidget {
  const MigrationScreen({Key? key}) : super(key: key);

  @override
  State<MigrationScreen> createState() => _MigrationScreenState();
}

class _MigrationScreenState extends State<MigrationScreen> {
  final StorageMigrationService _migrationService = Get.find<StorageMigrationService>();
  Map<String, dynamic> _migrationStats = {};
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _verifyMigration();
  }

  Future<void> _verifyMigration() async {
    setState(() {
      _isVerifying = true;
    });

    try {
      final stats = await _migrationService.verifyMigration();
      setState(() {
        _migrationStats = stats;
        _isVerifying = false;
      });
    } catch (e) {
      debugPrint('Error verifying migration: $e');
      setState(() {
        _isVerifying = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Storage Migration'),
      ),
      body: Obx(() {
        final isInProgress = _migrationService.isMigrationInProgress.value;
        final total = _migrationService.totalItems.value;
        final processed = _migrationService.processedItems.value;
        final operation = _migrationService.currentOperation.value;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Storage Migration Tool',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'This tool will migrate all images from Google Drive to Firebase Storage. '
                    'This process may take some time depending on the number of images.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 24),

              // Migration Statistics
              if (_isVerifying)
                const Center(
                  child: CircularProgressIndicator(),
                )
              else
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Migration Statistics',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildStatRow('Articles Total:', _migrationStats['articlesTotal'] ?? 0),
                        _buildStatRow('Articles Migrated:', _migrationStats['articlesMigrated'] ?? 0),
                        _buildStatRow('Stories Total:', _migrationStats['storiesTotal'] ?? 0),
                        _buildStatRow('Stories Migrated:', _migrationStats['storiesMigrated'] ?? 0),
                        const SizedBox(height: 8),
                        const Text(
                          'Google Drive URLs:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: 100,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: ListView.builder(
                            itemCount: (_migrationStats['googleDriveUrls'] as List<String>?)?.length ?? 0,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                child: Text(
                                  (_migrationStats['googleDriveUrls'] as List<String>)[index],
                                  style: const TextStyle(fontSize: 12),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: _verifyMigration,
                              child: const Text('Refresh Statistics'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              // Migration Controls
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Migration Controls',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Progress indicator
                      if (isInProgress)
                        Column(
                          children: [
                            Text(
                              'Operation: $operation',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: total > 0 ? processed / total : 0,
                            ),
                            const SizedBox(height: 4),
                            Text('$processed / $total'),
                            const SizedBox(height: 16),
                          ],
                        ),

                      // Migration buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isInProgress
                                  ? null
                                  : () async {
                                await _migrationService.migrateArticleImages();
                                _verifyMigration();
                              },
                              child: const Text('Migrate Articles'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isInProgress
                                  ? null
                                  : () async {
                                await _migrationService.migrateStoryImages();
                                _verifyMigration();
                              },
                              child: const Text('Migrate Stories'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: isInProgress
                            ? null
                            : () async {
                          await _migrationService.migrateAllImages();
                          _verifyMigration();
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(40),
                        ),
                        child: const Text('Migrate All Images'),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
              const Text(
                'Note: Migration process will run in the background. You can close this screen and check back later.',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStatRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Text(value.toString()),
        ],
      ),
    );
  }
}