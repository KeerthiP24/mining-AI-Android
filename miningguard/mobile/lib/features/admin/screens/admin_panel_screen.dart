import 'dart:convert';
import 'dart:io';

import 'package:fl_chart/fl_chart.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/education/domain/safety_video.dart';
import '../../../shared/models/mine_model.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/providers/firebase_providers.dart';
import '../../../shared/widgets/dashboard/stat_card.dart';
import '../providers/admin_provider.dart';

class AdminPanelScreen extends ConsumerWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Panel'),
          actions: [
            IconButton(
              icon: const Icon(Icons.person_outline),
              onPressed: () => context.go(AppRoutes.workerProfile),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.people_outline), text: 'Users'),
              Tab(icon: Icon(Icons.video_library_outlined), text: 'Content'),
              Tab(icon: Icon(Icons.bar_chart_outlined), text: 'Analytics'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _UsersTab(),
            _ContentTab(),
            _AnalyticsTab(),
          ],
        ),
      ),
    );
  }
}

// ── Tab 1: Users ────────────────────────────────────────────────────────────

class _UsersTab extends ConsumerWidget {
  const _UsersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(filteredAdminUsersProvider);
    final loading = ref.watch(allUsersProvider).isLoading;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              labelText: 'Search by name, email, or mine',
            ),
            onChanged: (v) =>
                ref.read(adminUserSearchProvider.notifier).state = v,
          ),
        ),
        if (loading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else
          Expanded(
            child: users.isEmpty
                ? const Center(child: Text('No users match this search.'))
                : ListView.separated(
                    itemCount: users.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 0, indent: 72),
                    itemBuilder: (_, i) => _UserAdminTile(user: users[i]),
                  ),
          ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _importCsv(context, ref),
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Import CSV'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _showAddUserSheet(context, ref),
                  icon: const Icon(Icons.person_add),
                  label: const Text('Add user'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _importCsv(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (result == null || result.files.isEmpty) return;
    final bytes = result.files.first.bytes;
    final path = result.files.first.path;
    String content;
    if (bytes != null) {
      content = utf8.decode(bytes);
    } else if (path != null) {
      content = await File(path).readAsString();
    } else {
      return;
    }

    final rows = _parseCsv(content);
    if (rows.isEmpty || !context.mounted) return;
    final svc = ref.read(userManagementServiceProvider);
    final skipped = await svc.bulkImportWorkers(rows);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Imported ${rows.length - skipped} users (skipped $skipped).')),
      );
    }
  }

  /// Naive CSV parser: handles plain comma-separated rows + a header line
  /// containing the column names. Returns one Map per data row.
  List<Map<String, String>> _parseCsv(String content) {
    final lines = const LineSplitter().convert(content)
      ..removeWhere((l) => l.trim().isEmpty);
    if (lines.length < 2) return const [];
    final headers = lines.first.split(',').map((s) => s.trim()).toList();
    return lines.skip(1).map((line) {
      final cells = line.split(',').map((s) => s.trim()).toList();
      return {
        for (var i = 0; i < headers.length && i < cells.length; i++)
          headers[i]: cells[i],
      };
    }).toList();
  }

  Future<void> _showAddUserSheet(
      BuildContext context, WidgetRef ref) async {
    final nameC = TextEditingController();
    final emailC = TextEditingController();
    final mineC = TextEditingController();
    String role = 'worker';
    String shift = 'morning';
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Add user', style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 12),
              TextField(
                controller: nameC,
                decoration: const InputDecoration(labelText: 'Full name'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: emailC,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: mineC,
                decoration: const InputDecoration(labelText: 'Mine ID'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: role,
                decoration: const InputDecoration(labelText: 'Role'),
                items: const [
                  DropdownMenuItem(value: 'worker', child: Text('Worker')),
                  DropdownMenuItem(
                      value: 'supervisor', child: Text('Supervisor')),
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                ],
                onChanged: (v) => setState(() => role = v ?? role),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: shift,
                decoration: const InputDecoration(labelText: 'Shift'),
                items: const [
                  DropdownMenuItem(value: 'morning', child: Text('Morning')),
                  DropdownMenuItem(
                      value: 'afternoon', child: Text('Afternoon')),
                  DropdownMenuItem(value: 'night', child: Text('Night')),
                ],
                onChanged: (v) => setState(() => shift = v ?? shift),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  final svc = ref.read(userManagementServiceProvider);
                  await svc.bulkImportWorkers([
                    {
                      'name': nameC.text,
                      'email': emailC.text,
                      'mineId': mineC.text,
                      'role': role,
                      'shift': shift,
                    },
                  ]);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserAdminTile extends ConsumerWidget {
  const _UserAdminTile({required this.user});
  final UserModel user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppTheme.primaryYellow.withValues(alpha: 0.2),
        child: Text(_initials(user.fullName)),
      ),
      title: Row(
        children: [
          Expanded(child: Text(user.fullName)),
          _RoleChip(role: user.role.name),
        ],
      ),
      subtitle: Text('${user.mineId} · ${user.shift}'),
      trailing: Switch(
        value: user.isActive,
        onChanged: (v) => ref
            .read(userManagementServiceProvider)
            .setActive(user.uid, v),
      ),
      onTap: () => _showEditSheet(context, ref, user),
    );
  }

  Future<void> _showEditSheet(
      BuildContext context, WidgetRef ref, UserModel user) async {
    String role = user.role.name;
    String mineId = user.mineId;
    bool active = user.isActive;
    final mines = ref.read(allMinesProvider).valueOrNull ?? const <MineModel>[];

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(user.fullName,
                  style: Theme.of(ctx).textTheme.titleLarge),
              if ((user.email ?? '').isNotEmpty)
                Text(user.email!,
                    style: Theme.of(ctx).textTheme.bodySmall),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: role,
                decoration: const InputDecoration(labelText: 'Role'),
                items: const [
                  DropdownMenuItem(value: 'worker', child: Text('Worker')),
                  DropdownMenuItem(
                      value: 'supervisor', child: Text('Supervisor')),
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                ],
                onChanged: (v) => setState(() => role = v ?? role),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: mines.any((m) => m.id == mineId) ? mineId : null,
                decoration: const InputDecoration(labelText: 'Mine'),
                items: mines
                    .map((m) =>
                        DropdownMenuItem(value: m.id, child: Text(m.name)))
                    .toList(),
                onChanged: (v) => setState(() => mineId = v ?? mineId),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                value: active,
                onChanged: (v) => setState(() => active = v),
                title: const Text('Active'),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  final svc = ref.read(userManagementServiceProvider);
                  await svc.updateRole(user.uid, role);
                  if (mineId != user.mineId) {
                    await svc.reassignMine(user.uid, mineId);
                  }
                  if (active != user.isActive) {
                    await svc.setActive(user.uid, active);
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.role});
  final String role;
  @override
  Widget build(BuildContext context) {
    final color = switch (role) {
      'admin' => AppTheme.severityCritical,
      'supervisor' => AppTheme.statusInProgress,
      _ => AppTheme.statusAcknowledged,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        role.toUpperCase(),
        style: TextStyle(
            color: color, fontWeight: FontWeight.w700, fontSize: 11),
      ),
    );
  }
}

// ── Tab 2: Content ──────────────────────────────────────────────────────────

class _ContentTab extends ConsumerWidget {
  const _ContentTab();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videos = ref.watch(allVideosProvider);
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              const Text('Safety videos',
                  style: TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 16)),
              const Spacer(),
              FilledButton.tonalIcon(
                icon: const Icon(Icons.add),
                label: const Text('Add'),
                onPressed: () => _addVideoSheet(context, ref),
              ),
            ],
          ),
        ),
        videos.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Padding(
              padding: const EdgeInsets.all(16), child: Text('Error: $e')),
          data: (vids) => Column(
            children: vids.map((v) => _VideoAdminTile(video: v)).toList(),
          ),
        ),
        const Divider(height: 32),
        const _AnnouncementSection(),
      ],
    );
  }

  Future<void> _addVideoSheet(BuildContext context, WidgetRef ref) async {
    final titleC = TextEditingController();
    final youtubeC = TextEditingController();
    final descC = TextEditingController();
    final tagsC = TextEditingController();
    String category = VideoCategory.ppe;
    final roles = <String>{'worker'};
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: EdgeInsets.only(
            left: 16, right: 16, top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Add safety video',
                    style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: 12),
                TextField(
                    controller: titleC,
                    decoration:
                        const InputDecoration(labelText: 'Title (English)')),
                const SizedBox(height: 8),
                TextField(
                    controller: youtubeC,
                    decoration:
                        const InputDecoration(labelText: 'YouTube ID')),
                const SizedBox(height: 8),
                TextField(
                    controller: descC,
                    minLines: 2,
                    maxLines: 4,
                    decoration:
                        const InputDecoration(labelText: 'Description')),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: const [
                    DropdownMenuItem(value: 'ppe', child: Text('PPE')),
                    DropdownMenuItem(
                        value: 'gas_ventilation',
                        child: Text('Gas & Ventilation')),
                    DropdownMenuItem(
                        value: 'roof_support', child: Text('Roof Support')),
                    DropdownMenuItem(
                        value: 'emergency', child: Text('Emergency')),
                    DropdownMenuItem(
                        value: 'machinery', child: Text('Machinery')),
                  ],
                  onChanged: (v) => setState(() => category = v ?? category),
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  value: roles.contains('worker'),
                  onChanged: (v) => setState(() => v ?? false
                      ? roles.add('worker')
                      : roles.remove('worker')),
                  title: const Text('Workers'),
                ),
                CheckboxListTile(
                  value: roles.contains('supervisor'),
                  onChanged: (v) => setState(() => v ?? false
                      ? roles.add('supervisor')
                      : roles.remove('supervisor')),
                  title: const Text('Supervisors'),
                ),
                const SizedBox(height: 8),
                TextField(
                    controller: tagsC,
                    decoration: const InputDecoration(
                      labelText: 'Tags (comma-separated)',
                    )),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () async {
                    if (titleC.text.trim().isEmpty ||
                        youtubeC.text.trim().isEmpty) return;
                    await addSafetyVideo(
                      firestore: ref.read(firestoreProvider),
                      title: titleC.text.trim(),
                      description: descC.text.trim(),
                      youtubeId: youtubeC.text.trim(),
                      category: category,
                      targetRoles: roles.toList(),
                      tags: tagsC.text
                          .split(',')
                          .map((s) => s.trim())
                          .where((s) => s.isNotEmpty)
                          .toList(),
                    );
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VideoAdminTile extends ConsumerWidget {
  const _VideoAdminTile({required this.video});
  final SafetyVideo video;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = localizeMap(video.title, 'en');
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.network(
          video.thumbnailUrl,
          width: 64,
          height: 36,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.broken_image_outlined),
        ),
      ),
      title: Text(title),
      subtitle: Text(video.category),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        onPressed: () async {
          final ok = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Delete video?'),
              content: Text(title),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Delete'),
                ),
              ],
            ),
          );
          if (ok == true) {
            await deleteSafetyVideo(
                ref.read(firestoreProvider), video.videoId);
          }
        },
      ),
    );
  }
}

class _AnnouncementSection extends ConsumerStatefulWidget {
  const _AnnouncementSection();
  @override
  ConsumerState<_AnnouncementSection> createState() =>
      _AnnouncementSectionState();
}

class _AnnouncementSectionState extends ConsumerState<_AnnouncementSection> {
  final _msgC = TextEditingController();
  String _mineId = '*';

  @override
  Widget build(BuildContext context) {
    final mines = ref.watch(allMinesProvider).valueOrNull ?? const <MineModel>[];
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Send announcement',
              style:
                  TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _mineId,
            decoration: const InputDecoration(labelText: 'Audience'),
            items: [
              const DropdownMenuItem(value: '*', child: Text('All mines')),
              ...mines.map((m) =>
                  DropdownMenuItem(value: m.id, child: Text(m.name))),
            ],
            onChanged: (v) => setState(() => _mineId = v ?? '*'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _msgC,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
                labelText: 'Message', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            icon: const Icon(Icons.send),
            label: const Text('Send to all workers'),
            onPressed: () async {
              if (_msgC.text.trim().isEmpty) return;
              final n = await sendMineAnnouncement(
                firestore: ref.read(firestoreProvider),
                mineId: _mineId,
                message: _msgC.text.trim(),
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Sent $n alerts.')),
                );
                _msgC.clear();
              }
            },
          ),
        ],
      ),
    );
  }
}

// ── Tab 3: Analytics ────────────────────────────────────────────────────────

class _AnalyticsTab extends ConsumerWidget {
  const _AnalyticsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(allUsersProvider).valueOrNull ?? const [];
    final monthly = ref.watch(monthlyIncidentTrendProvider);
    final heatmap = ref.watch(riskHeatmapProvider);

    final workerCount = users.where((u) => u.role.name == 'worker').length;
    final highRiskCount =
        users.where((u) => u.riskLevel.toLowerCase() == 'high').length;
    final mediumCount =
        users.where((u) => u.riskLevel.toLowerCase() == 'medium').length;
    final lowCount = users.where((u) => u.riskLevel.toLowerCase() == 'low').length;
    final avgCompliance = users.isEmpty
        ? 0.0
        : users.map((u) => u.complianceRate).reduce((a, b) => a + b) /
            users.length;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Wrap(
            children: [
              StatCard(
                  label: 'Total workers',
                  value: '$workerCount',
                  icon: Icons.groups_outlined),
              StatCard(
                  label: 'Avg compliance',
                  value: '${(avgCompliance * 100).toStringAsFixed(0)}%',
                  icon: Icons.task_alt_outlined),
              StatCard(
                  label: 'High risk',
                  value: '$highRiskCount',
                  icon: Icons.warning_amber_outlined,
                  color: AppTheme.riskHigh),
              StatCard(
                  label: 'Medium risk',
                  value: '$mediumCount',
                  icon: Icons.error_outline,
                  color: AppTheme.riskMedium),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Text('Monthly incidents (last 6 months)',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        ),
        SizedBox(
          height: 240,
          child: monthly.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (rows) => Padding(
              padding: const EdgeInsets.all(16),
              child: _MonthlyBarChart(data: rows),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              const Text('Risk distribution',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const Spacer(),
              Text('Total: ${highRiskCount + mediumCount + lowCount}',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        SizedBox(
          height: 220,
          child: _RiskPie(
            high: highRiskCount,
            medium: mediumCount,
            low: lowCount,
          ),
        ),
        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Text('Risk heatmap by section',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        ),
        heatmap.when(
          loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator())),
          error: (e, _) => Padding(
              padding: const EdgeInsets.all(16), child: Text('Error: $e')),
          data: (rows) => _HeatmapTable(rows: rows),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: FilledButton.icon(
            icon: const Icon(Icons.ios_share),
            label: const Text('Export DGMS report (text)'),
            onPressed: () => _exportDgmsReport(
              context,
              users,
              avgCompliance: avgCompliance,
              high: highRiskCount,
              medium: mediumCount,
              low: lowCount,
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Future<void> _exportDgmsReport(
    BuildContext context,
    List<UserModel> users, {
    required double avgCompliance,
    required int high,
    required int medium,
    required int low,
  }) async {
    final now = DateFormat('dd MMM yyyy').format(DateTime.now());
    final buf = StringBuffer()
      ..writeln('MiningGuard — DGMS Compliance Report')
      ..writeln('Generated: $now')
      ..writeln('-' * 40)
      ..writeln('Total workers:     ${users.length}')
      ..writeln(
          'Avg compliance:    ${(avgCompliance * 100).toStringAsFixed(1)}%')
      ..writeln('High risk count:   $high')
      ..writeln('Medium risk count: $medium')
      ..writeln('Low risk count:    $low')
      ..writeln('')
      ..writeln('Generated by MiningGuard admin panel.');
    await SharePlus.instance.share(
      ShareParams(text: buf.toString(), subject: 'MiningGuard DGMS Report'),
    );
  }
}

class _MonthlyBarChart extends StatelessWidget {
  const _MonthlyBarChart({required this.data});
  final List<MonthlyIncidentData> data;
  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const Center(child: Text('No data'));
    final maxY = data
        .map((d) => d.totalReports)
        .fold<int>(0, (m, v) => v > m ? v : m)
        .toDouble();
    return BarChart(
      BarChartData(
        maxY: (maxY + 2).clamp(4, double.infinity),
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= data.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(DateFormat('MMM').format(data[i].month),
                      style: const TextStyle(fontSize: 10)),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (v, _) =>
                  Text(v.toInt().toString(), style: const TextStyle(fontSize: 10)),
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: [
          for (var i = 0; i < data.length; i++)
            BarChartGroupData(x: i, barRods: [
              BarChartRodData(
                  toY: data[i].totalReports.toDouble(),
                  width: 14,
                  color: AppTheme.statusAcknowledged),
              BarChartRodData(
                  toY: data[i].criticalReports.toDouble(),
                  width: 14,
                  color: AppTheme.severityCritical),
            ]),
        ],
      ),
    );
  }
}

class _RiskPie extends StatelessWidget {
  const _RiskPie({required this.high, required this.medium, required this.low});
  final int high, medium, low;
  @override
  Widget build(BuildContext context) {
    final total = high + medium + low;
    if (total == 0) return const Center(child: Text('No risk data'));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: [
                  PieChartSectionData(
                    value: high.toDouble(),
                    color: AppTheme.riskHigh,
                    title: '${(high / total * 100).round()}%',
                    radius: 60,
                    titleStyle: const TextStyle(
                        fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                  PieChartSectionData(
                    value: medium.toDouble(),
                    color: AppTheme.riskMedium,
                    title: '${(medium / total * 100).round()}%',
                    radius: 60,
                    titleStyle: const TextStyle(
                        fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                  PieChartSectionData(
                    value: low.toDouble(),
                    color: AppTheme.riskLow,
                    title: '${(low / total * 100).round()}%',
                    radius: 60,
                    titleStyle: const TextStyle(
                        fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendRow(color: AppTheme.riskHigh, label: 'High', count: high),
              _LegendRow(
                  color: AppTheme.riskMedium, label: 'Medium', count: medium),
              _LegendRow(color: AppTheme.riskLow, label: 'Low', count: low),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow(
      {required this.color, required this.label, required this.count});
  final Color color;
  final String label;
  final int count;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 6),
        Text('$label · $count'),
      ]),
    );
  }
}

class _HeatmapTable extends StatelessWidget {
  const _HeatmapTable({required this.rows});
  final List<HeatmapRow> rows;
  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('No section data yet.'),
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Section')),
          DataColumn(label: Text('Avg risk')),
          DataColumn(label: Text('Workers')),
          DataColumn(label: Text('Reports')),
        ],
        rows: rows
            .map(
              (r) => DataRow(cells: [
                DataCell(Text(r.section)),
                DataCell(Text(r.avgRiskScore.toStringAsFixed(1))),
                DataCell(Text('${r.workerCount}')),
                DataCell(Text('${r.reportCount}')),
              ]),
            )
            .toList(),
      ),
    );
  }
}

