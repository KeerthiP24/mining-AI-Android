import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:miningguard/core/router/app_router.dart';
import 'package:miningguard/features/auth/providers/auth_providers.dart';

class LanguageSelectionScreen extends ConsumerStatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  ConsumerState<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState
    extends ConsumerState<LanguageSelectionScreen> {
  String _selected = 'en';
  bool _loading = false;

  static const _languages = [
    _Language(code: 'en', name: 'English', script: 'English'),
    _Language(code: 'hi', name: 'Hindi', script: 'हिन्दी'),
    _Language(code: 'bn', name: 'Bengali', script: 'বাংলা'),
    _Language(code: 'te', name: 'Telugu', script: 'తెలుగు'),
    _Language(code: 'mr', name: 'Marathi', script: 'मराठी'),
    _Language(code: 'or', name: 'Odia', script: 'ଓଡ଼ିଆ'),
  ];

  Future<void> _confirm() async {
    setState(() => _loading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      await ref
          .read(userRepositoryProvider)
          .updateUser(uid, {'preferredLanguage': _selected});
      if (mounted) context.go(AppRoutes.workerHome);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('language.error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF1A1A2E);
    const amber = Color(0xFFF5A623);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              const Text(
                'Choose your language\nअपनी भाषा चुनें',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.5,
                  children: _languages
                      .map((lang) => _LanguageCard(
                            language: lang,
                            selected: _selected == lang.code,
                            onTap: () =>
                                setState(() => _selected = lang.code),
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _loading ? null : _confirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: amber,
                    foregroundColor: const Color(0xFF1A1A2E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Color(0xFF1A1A2E),
                          ),
                        )
                      : const Text(
                          'language.continue',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  const _LanguageCard({
    required this.language,
    required this.selected,
    required this.onTap,
  });

  final _Language language;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFF5A623).withValues(alpha: 0.15)
              : const Color(0xFF252545),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? const Color(0xFFF5A623) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Text(
                language.script,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (selected)
              const Positioned(
                top: 8,
                right: 8,
                child: Icon(
                  Icons.check_circle,
                  color: Color(0xFFF5A623),
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Language {
  const _Language({
    required this.code,
    required this.name,
    required this.script,
  });

  final String code;
  final String name;
  final String script;
}
