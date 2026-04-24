import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:miningguard/core/router/app_router.dart';
import 'package:miningguard/core/theme/app_theme.dart';
import 'package:miningguard/features/auth/providers/auth_providers.dart';
import 'package:miningguard/shared/models/user_model.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserModelProvider);

    return userAsync.when(
      loading: () => const _LoadingProfile(),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('profile.title')),
        body: Center(
          child: Text('profile.error: $e',
              style: const TextStyle(color: Colors.redAccent)),
        ),
      ),
      data: (user) {
        if (user == null) return const SizedBox.shrink();
        return _ProfileBody(user: user);
      },
    );
  }
}

// ── Loading state ─────────────────────────────────────────────────────────────

class _LoadingProfile extends StatelessWidget {
  const _LoadingProfile();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('profile.title')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: List.generate(
            5,
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.grey.shade800,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Profile body ──────────────────────────────────────────────────────────────

class _ProfileBody extends ConsumerWidget {
  const _ProfileBody({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('profile.title')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _IdentitySection(user: user),
            const SizedBox(height: 24),
            _SafetyStatsSection(user: user),
            const SizedBox(height: 24),
            _SettingsSection(user: user),
          ],
        ),
      ),
    );
  }
}

// ── Section 1: Identity ───────────────────────────────────────────────────────

class _IdentitySection extends StatelessWidget {
  const _IdentitySection({required this.user});

  final UserModel user;

  String get _initials {
    final parts = user.fullName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return parts.first.isNotEmpty ? parts.first[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: const Color(0xFFF5A623),
          child: Text(
            _initials,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          user.fullName,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        _RoleBadge(role: user.role),
        const SizedBox(height: 8),
        Text(
          'Mine ID: ${user.mineId}',
          style: const TextStyle(fontSize: 16, color: Colors.white70),
        ),
        const SizedBox(height: 4),
        Text(
          '${user.department} · ${_shiftLabel(user.shift)}',
          style: const TextStyle(fontSize: 16, color: Colors.white54),
        ),
      ],
    );
  }

  String _shiftLabel(String shift) {
    switch (shift) {
      case 'morning':
        return 'Morning 🌅';
      case 'afternoon':
        return 'Afternoon 🌇';
      case 'night':
        return 'Night 🌙';
      default:
        return shift;
    }
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});

  final UserRole role;

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (role) {
      case UserRole.admin:
        color = Colors.red;
        label = 'Admin';
      case UserRole.supervisor:
        color = Colors.orange;
        label = 'Supervisor';
      case UserRole.worker:
        color = Colors.blue;
        label = 'Worker';
    }
    return Chip(
      label: Text(label,
          style: const TextStyle(color: Colors.white, fontSize: 14)),
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}

// ── Section 2: Safety Stats ───────────────────────────────────────────────────

class _SafetyStatsSection extends StatelessWidget {
  const _SafetyStatsSection({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'profile.riskLevel',
            value: user.riskLevel.toUpperCase(),
            color: _riskColor(user.riskLevel),
            icon: _riskIcon(user.riskLevel),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'profile.compliance',
            value: '${(user.complianceRate * 100).toStringAsFixed(0)}%',
            color: Colors.greenAccent,
            icon: Icons.verified_user,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'profile.reports',
            value: user.totalHazardReports.toString(),
            color: Colors.blueAccent,
            icon: Icons.report_problem,
          ),
        ),
      ],
    );
  }

  Color _riskColor(String level) {
    switch (level) {
      case 'high':
        return AppTheme.riskHigh;
      case 'medium':
        return AppTheme.riskMedium;
      default:
        return AppTheme.riskLow;
    }
  }

  IconData _riskIcon(String level) {
    switch (level) {
      case 'high':
        return Icons.warning;
      case 'medium':
        return Icons.warning_amber;
      default:
        return Icons.check_circle;
    }
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF252545),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ── Section 3: Settings ───────────────────────────────────────────────────────

class _SettingsSection extends ConsumerWidget {
  const _SettingsSection({required this.user});

  final UserModel user;

  String _languageName(String code) {
    const names = {
      'en': 'English',
      'hi': 'हिन्दी',
      'bn': 'বাংলা',
      'te': 'తెలుగు',
      'mr': 'मराठी',
      'or': 'ଓଡ଼ିଆ',
    };
    return names[code] ?? code;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        // Language
        ListTile(
          tileColor: const Color(0xFF252545),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          leading: const Icon(Icons.language, color: Colors.white70),
          title: const Text('profile.language',
              style: TextStyle(color: Colors.white, fontSize: 16)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _languageName(user.preferredLanguage),
                style:
                    const TextStyle(color: Colors.white54, fontSize: 15),
              ),
              const Icon(Icons.chevron_right, color: Colors.white38),
            ],
          ),
          onTap: () => context.go(AppRoutes.languageSelect),
        ),
        const SizedBox(height: 8),

        // Shift
        ListTile(
          tileColor: const Color(0xFF252545),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          leading: const Icon(Icons.access_time, color: Colors.white70),
          title: const Text('profile.shift',
              style: TextStyle(color: Colors.white, fontSize: 16)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _shiftLabel(user.shift),
                style:
                    const TextStyle(color: Colors.white54, fontSize: 15),
              ),
              const Icon(Icons.chevron_right, color: Colors.white38),
            ],
          ),
          onTap: () => _showShiftPicker(context, ref),
        ),
        const SizedBox(height: 8),

        // Notification Preferences (Phase 8 placeholder)
        ListTile(
          tileColor: const Color(0xFF252545),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          leading:
              const Icon(Icons.notifications, color: Colors.white70),
          title: const Text('profile.notifications',
              style: TextStyle(color: Colors.white, fontSize: 16)),
          trailing:
              const Icon(Icons.chevron_right, color: Colors.white38),
          onTap: () {}, // Phase 8
        ),
        const SizedBox(height: 8),

        // Sign Out
        ListTile(
          tileColor: const Color(0xFF252545),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          leading: const Icon(Icons.logout, color: Colors.redAccent),
          title: const Text(
            'profile.signOut',
            style: TextStyle(color: Colors.redAccent, fontSize: 16),
          ),
          onTap: () => _confirmSignOut(context, ref),
        ),
      ],
    );
  }

  String _shiftLabel(String shift) {
    switch (shift) {
      case 'morning':
        return 'Morning 🌅';
      case 'afternoon':
        return 'Afternoon 🌇';
      case 'night':
        return 'Night 🌙';
      default:
        return shift;
    }
  }

  void _showShiftPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF252545),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ShiftPickerSheet(
        current: user.shift,
        uid: user.uid,
        ref: ref,
      ),
    );
  }

  void _confirmSignOut(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF252545),
        title: const Text('profile.signOut.confirm.title',
            style: TextStyle(color: Colors.white)),
        content: const Text('profile.signOut.confirm.body',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('profile.cancel',
                style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(authServiceProvider).signOut();
              if (context.mounted) context.go(AppRoutes.login);
            },
            child: const Text('profile.signOut',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}

class _ShiftPickerSheet extends StatefulWidget {
  const _ShiftPickerSheet({
    required this.current,
    required this.uid,
    required this.ref,
  });

  final String current;
  final String uid;
  final WidgetRef ref;

  @override
  State<_ShiftPickerSheet> createState() => _ShiftPickerSheetState();
}

class _ShiftPickerSheetState extends State<_ShiftPickerSheet> {
  late String _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.current;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'profile.shift.pick',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          RadioGroup<String>(
            groupValue: _selected,
            onChanged: (v) { if (v != null) setState(() => _selected = v); },
            child: Column(
              children: ['morning', 'afternoon', 'night'].map((shift) {
                return GestureDetector(
                  onTap: () => setState(() => _selected = shift),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Radio<String>(
                          value: shift,
                          activeColor: const Color(0xFFF5A623),
                        ),
                        Text(
                          _label(shift),
                          style:
                              const TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () async {
                await widget.ref
                    .read(userRepositoryProvider)
                    .updateUser(widget.uid, {'shift': _selected});
                if (context.mounted) Navigator.of(context).pop();
              },
              child: const Text('profile.confirm',
                  style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  String _label(String shift) {
    switch (shift) {
      case 'morning':
        return 'Morning 🌅';
      case 'afternoon':
        return 'Afternoon 🌇';
      case 'night':
        return 'Night 🌙';
      default:
        return shift;
    }
  }
}
