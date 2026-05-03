import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'api.dart';
import 'models.dart';
import 'theme.dart';
import 'widgets/common.dart';
import 'widgets/hero_card.dart';
import 'widgets/instance_editor.dart';
import 'widgets/instance_picker.dart';
import 'widgets/log_viewer.dart';
import 'widgets/overview_card.dart';
import 'widgets/resource_card.dart';
import 'widgets/services_card.dart';
import 'widgets/settings_panel.dart';
import 'widgets/update_card.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({
    required this.navigationShell,
    super.key,
  });

  final StatefulNavigationShell navigationShell;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  InstanceRepository? _repo;
  List<GokrazyInstance> _instances = [];
  final Map<String, GokrazyStatus> _statuses = {};
  final Map<String, String> _errors = {};
  final Set<String> _statusLoading = {};
  final Set<String> _busyInstances = {};
  String? _selectedId;
  bool _loading = true;
  String _lastLocation = '';

  final Map<String, _UploadState> _uploadByInstance = {};
  int get _routeTab => widget.navigationShell.currentIndex;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(HomeShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncFromRoute();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncFromRoute();
  }

  void _syncFromRoute() {
    if (!mounted) {
      return;
    }
    final location = GoRouter.of(context).location;
    if (location == _lastLocation) {
      return;
    }
    _lastLocation = location;

    final parsed = Uri.tryParse(location);
    if (parsed == null) {
      return;
    }
    final segments = parsed.pathSegments;

    if (segments.isNotEmpty && segments.first == 'instance') {
      if (segments.length < 2) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            return;
          }
          context.go('/');
        });
        return;
      }
      final requested = segments[1];
      final resolved = _resolveSelectedId(requested);
      if (resolved == null) {
        if (!_loading && _instances.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) {
              return;
            }
            _showSnack('The selected appliance no longer exists');
            context.go('/');
          });
        }
        return;
      }
      if (resolved != _selectedId) {
        setState(() => _selectedId = resolved);
      }
      return;
    }

    if (_selectedId != null && !_instances.any((entry) => entry.id == _selectedId)) {
      setState(() => _selectedId = _instances.isEmpty ? null : _instances.first.id);
    }
    if (_selectedId == null && _instances.isNotEmpty) {
      setState(() => _selectedId = _instances.first.id);
    }
  }

  String? _resolveSelectedId(String? requestedId) {
    if (requestedId != null &&
        _instances.any((entry) => entry.id == requestedId)) {
      return requestedId;
    }
    if (_selectedId != null &&
        _instances.any((entry) => entry.id == _selectedId)) {
      return _selectedId;
    }
    return _instances.isEmpty ? null : _instances.first.id;
  }

  Future<void> _load() async {
    final repo = await InstanceRepository.open();
    final instances = repo.load();
    if (!mounted) {
      return;
    }
    setState(() {
      _repo = repo;
      _instances = instances;
      _selectedId = instances.isEmpty ? null : instances.first.id;
      _loading = false;
    });
    unawaited(_refreshAll());
    _syncFromRoute();
  }

  Future<void> _refreshAll() async {
    for (final instance in _instances) {
      unawaited(_refresh(instance));
    }
  }

  Future<void> _refresh(GokrazyInstance instance) async {
    final repo = _repo;
    if (repo == null) {
      return;
    }
    setState(() {
      _statusLoading.add(instance.id);
      _errors.remove(instance.id);
    });
    final password = await repo.passwordFor(instance.id);
    if (password == null) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errors[instance.id] = 'Missing password';
        _statusLoading.remove(instance.id);
      });
      return;
    }
    try {
      final status = await GokrazyClient(
        instance: instance,
        password: password,
      ).fetchStatus();
      if (!mounted) {
        return;
      }
      setState(() {
        _statuses[instance.id] = status;
        _errors.remove(instance.id);
      });
      await _markSeen(instance);
    } on CertificatePinRequired catch (error) {
      if (!mounted) {
        return;
      }
      final accepted = await _confirmCertificate(error.fingerprint);
      if (accepted) {
        await _saveInstance(
          instance.copyWith(pinnedFingerprint: error.fingerprint),
          password: password,
          stayOnPage: true,
        );
      } else if (mounted) {
        setState(() => _errors[instance.id] = 'Certificate not trusted');
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _errors[instance.id] = error.toString());
    } finally {
      if (mounted) {
        setState(() => _statusLoading.remove(instance.id));
      }
    }
  }

  Future<void> _markSeen(GokrazyInstance instance) async {
    final updated = instance.copyWith(lastSeen: DateTime.now());
    final next = _instances
        .map((entry) => entry.id == updated.id ? updated : entry)
        .toList();
    await _repo?.saveAll(next);
    if (mounted) {
      setState(() => _instances = next);
    }
  }

  Future<void> _saveInstance(
    GokrazyInstance instance, {
    required String password,
    bool stayOnPage = false,
  }) async {
    final repo = _repo;
    if (repo == null) {
      return;
    }
    final exists = _instances.any((entry) => entry.id == instance.id);
    final next = exists
        ? _instances
            .map((entry) => entry.id == instance.id ? instance : entry)
            .toList()
        : [..._instances, instance];
    await repo.saveAll(next);
    await repo.upsertPassword(instance.id, password);
    if (!mounted) {
      return;
    }
    setState(() {
      _instances = next;
      if (!stayOnPage) {
        _selectedId = instance.id;
      }
    });
    if (!stayOnPage) {
      _persistRouteForSelection();
    }
    await _refresh(instance);
  }

  Future<void> _deleteInstance(GokrazyInstance instance) async {
    final repo = _repo;
    if (repo == null) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${instance.name}?'),
        content: const Text(
          'The connection details and pinned certificate will be removed '
          'from this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    final next = _instances.where((entry) => entry.id != instance.id).toList();
    await repo.saveAll(next);
    await repo.deletePassword(instance.id);
    if (!mounted) {
      return;
    }
    setState(() {
      _instances = next;
      _statuses.remove(instance.id);
      _errors.remove(instance.id);
      _uploadByInstance.remove(instance.id);
      _busyInstances.remove(instance.id);
      _selectedId = next.isEmpty ? null : next.first.id;
    });
    if (_routeTab == 0) {
      _persistRouteForSelection();
    }
  }

  Future<bool> _confirmCertificate(String fingerprint) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Trust certificate?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This appliance is using a self-signed certificate. '
                'Verify the SHA-256 fingerprint matches the expected one.',
              ),
              const SizedBox(height: AppSpacing.s),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.22),
                  ),
                ),
                padding: const EdgeInsets.all(AppSpacing.s),
                child: SelectableText(
                  fingerprint,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.verified_user_rounded),
              label: const Text('Trust'),
            ),
          ],
        );
      },
    );
    return accepted == true;
  }

  void _persistRouteForSelection() {
    if (!mounted) {
      return;
    }
    if (_routeTab == 1) {
      return;
    }
    if (_selectedId == null) {
      _navigateToRoute('/');
    } else {
      _navigateToRoute('/instance/$_selectedId');
    }
  }

  void _selectInstance(String id) {
    if (!_instances.any((entry) => entry.id == id)) {
      return;
    }
    setState(() => _selectedId = id);
    _navigateToRoute('/instance/$id');
  }

  void _switchTab(int index) {
    if (index == 1) {
      _navigateToRoute('/settings');
    } else if (_selectedId != null) {
      _navigateToRoute('/instance/$_selectedId');
    } else {
      _navigateToRoute('/');
    }
  }

  void _navigateToRoute(String destination) {
    final current = GoRouter.of(context).location;
    if (current == destination) {
      return;
    }
    if (destination == '/settings' || destination == '/') {
      context.go(destination);
    } else {
      context.go(destination);
    }
  }

  Future<void> _openEditor([GokrazyInstance? instance]) async {
    final password = instance == null
        ? ''
        : await _repo?.passwordFor(instance.id) ?? '';
    if (!mounted) {
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => InstanceEditor(
        instance: instance,
        password: password,
        onSave: (next, pwd) =>
            _saveInstance(next, password: pwd),
      ),
    );
  }

  Future<void> _runAction(
    GokrazyInstance instance,
    String successLabel,
    Future<void> Function(GokrazyClient client) action,
  ) async {
    final repo = _repo ?? await InstanceRepository.open();
    final password = await repo.passwordFor(instance.id);
    if (password == null) {
      _showSnack('Missing password');
      return;
    }
    setState(() => _busyInstances.add(instance.id));
    try {
      await action(GokrazyClient(instance: instance, password: password));
      _showSnack(successLabel);
    } on CertificatePinRequired catch (error) {
      final accepted = await _confirmCertificate(error.fingerprint);
      if (accepted) {
        await _saveInstance(
          instance.copyWith(pinnedFingerprint: error.fingerprint),
          password: password,
          stayOnPage: true,
        );
        _showSnack('Certificate trusted. Try the action again.');
      }
    } catch (error) {
      _showSnack(error.toString());
    } finally {
      if (mounted) {
        setState(() => _busyInstances.remove(instance.id));
      }
    }
  }

  Future<void> _runServiceAction(
    GokrazyInstance instance,
    String successLabel,
    GokrazyService service,
    Future<void> Function(GokrazyClient client) action,
  ) async {
    await _runAction(instance, successLabel, action);
    if (mounted) {
      unawaited(_refresh(instance));
    }
  }

  Future<void> _showServiceArgs(GokrazyService service) async {
    if (!mounted) {
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.l,
            AppSpacing.s,
            AppSpacing.l,
            AppSpacing.l,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const GradientIconBadge(
                    icon: Icons.tune_rounded,
                    size: 44,
                  ),
                  const SizedBox(width: AppSpacing.s),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service.name,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4,
                              ),
                        ),
                        Text(
                          'Process arguments',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 420),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: service.args.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final arg = service.args[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white.withValues(alpha: 0.04)
                            : Colors.black.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.s,
                        vertical: AppSpacing.xs,
                      ),
                      child: SelectableText(
                        arg,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontFamily: 'monospace'),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openServiceLogs(
    GokrazyInstance instance,
    GokrazyService service,
  ) async {
    final repo = _repo ?? await InstanceRepository.open();
    final password = await repo.passwordFor(instance.id);
    if (password == null) {
      _showSnack('Missing password');
      return;
    }
    if (!mounted) {
      return;
    }
    final stream = GokrazyClient(instance: instance, password: password)
        .serviceLogStream(path: service.path, stream: 'both');
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => LogViewer(
        service: service,
        stream: stream,
      ),
    );
  }

  Future<void> _uploadSquashfs(GokrazyInstance instance) async {
    final repo = _repo ?? await InstanceRepository.open();
    final password = await repo.passwordFor(instance.id);
    if (password == null) {
      _showSnack('Missing password');
      return;
    }
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['squashfs', 'gz', 'img', 'bin'],
      withReadStream: true,
    );
    final file = picked?.files.single;
    if (file == null) {
      return;
    }
    final stream = file.readStream ??
        (file.path == null ? null : File(file.path!).openRead());
    if (stream == null) {
      _showSnack('Cannot read selected file');
      return;
    }
    if (!mounted) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Flash root squashfs?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(file.name,
                style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(
              'The new image will be uploaded and verified. Use Test boot '
              'before switching the active root.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.system_update_alt_rounded),
            label: const Text('Flash'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    final isGzipped = file.name.endsWith('.gz');
    setState(() {
      _busyInstances.add(instance.id);
      _uploadByInstance[instance.id] = const _UploadState(
        progress: 0,
        message: 'Starting upload...',
      );
    });
    try {
      await GokrazyClient(instance: instance, password: password).uploadRoot(
        stream: stream,
        size: file.size,
        decompress: isGzipped,
        onProgress: (sent, total) {
          if (!mounted || total <= 0) {
            return;
          }
          setState(() {
            _uploadByInstance[instance.id] = _UploadState(
              progress: sent / total,
              message:
                  'Uploading ${file.name}${isGzipped ? ' (decompressing)' : ''}',
            );
          });
        },
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _uploadByInstance[instance.id] = const _UploadState(
          progress: null,
          message: 'Upload verified. Run Test boot next.',
        );
      });
    } on CertificatePinRequired catch (error) {
      final accepted = await _confirmCertificate(error.fingerprint);
      if (accepted) {
        await _saveInstance(
          instance.copyWith(pinnedFingerprint: error.fingerprint),
          password: password,
          stayOnPage: true,
        );
        _showSnack('Certificate trusted. Try uploading again.');
      }
      if (mounted) {
        setState(() => _uploadByInstance.remove(instance.id));
      }
    } catch (error) {
      _showSnack(error.toString());
      if (mounted) {
        setState(() => _uploadByInstance.remove(instance.id));
      }
    } finally {
      if (mounted) {
        setState(() => _busyInstances.remove(instance.id));
      }
    }
  }

  void _showSnack(String text) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final useRail = width >= AppBreakpoints.desktop;
    final selected = _instances
        .where((entry) => entry.id == _selectedId)
        .cast<GokrazyInstance?>()
        .firstWhere((entry) => true, orElse: () => null);

    final body = AnimatedSwitcher(
      duration: motionDuration(context, AppMotion.fast),
      child: _loading
          ? const _ShellSkeleton()
          : _routeTab == 1
              ? const SettingsPanel()
              : _buildDashboard(context, selected),
    );

    final scaffold = Scaffold(
      appBar: _buildAppBar(selected),
      floatingActionButton: _routeTab == 0 && !_loading
              ? FloatingActionButton.extended(
                  onPressed: () => _openEditor(),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add appliance'),
                )
              : null,
      body: SafeArea(child: body),
      bottomNavigationBar: useRail
          ? null
          : NavigationBar(
              selectedIndex: _routeTab,
              onDestinationSelected: _switchTab,
              destinations: [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard_rounded),
                  label: 'Dashboard',
                ),
                NavigationDestination(
                  icon: Icon(Icons.tune_outlined),
                  selectedIcon: Icon(Icons.tune_rounded),
                  label: 'Settings',
                ),
              ],
            ),
    );

    if (!useRail) {
      return scaffold;
    }
    return Row(
      children: [
        SafeArea(
        child: NavigationRail(
            selectedIndex: _routeTab,
            onDestinationSelected: _switchTab,
            labelType: NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
              child: GradientIconBadge(
                icon: Icons.memory_rounded,
                size: 48,
              ),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard_rounded),
                label: Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.tune_outlined),
                selectedIcon: Icon(Icons.tune_rounded),
                label: Text('Settings'),
              ),
            ],
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(child: scaffold),
      ],
    );
  }

  PreferredSizeWidget _buildAppBar(GokrazyInstance? selected) {
    final theme = Theme.of(context);
    return AppBar(
      titleSpacing: AppSpacing.m,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GradientIconBadge(
            icon: Icons.developer_board_rounded,
            size: 36,
          ),
          const SizedBox(width: AppSpacing.s),
          Flexible(
            child: Text(
              'Gokrazy',
              style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      actions: [
        if (_routeTab == 0 && _instances.isNotEmpty)
          Semantics(
            button: true,
            label: 'Refresh selected appliance',
            hint: 'Fetch latest status for the selected appliance',
            child: IconButton(
            tooltip: 'Refresh selected',
            onPressed: selected == null ? null : () => _refresh(selected),
            icon: const Icon(Icons.refresh_rounded),
            ),
          ),
        if (_routeTab == 0 && _instances.isNotEmpty)
          Semantics(
            button: true,
            label: 'Refresh all appliances',
            hint: 'Fetch latest status from all appliances',
            child: IconButton(
            tooltip: 'Refresh all',
            onPressed: _loading ? null : _refreshAll,
            icon: const Icon(Icons.sync_rounded),
            ),
          ),
        const SizedBox(width: AppSpacing.xs),
      ],
    );
  }

  Widget _buildDashboard(BuildContext context, GokrazyInstance? selected) {
    if (_instances.isEmpty) {
      return EmptyState(
        title: 'No appliances yet',
        message: 'Add your first gokrazy device to get started.',
        actionLabel: 'Add appliance',
        onAction: () => _openEditor(),
        icon: Icons.dns_rounded,
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= AppBreakpoints.desktop;
        final isTablet = constraints.maxWidth >= AppBreakpoints.tablet;
        return isDesktop
            ? Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.l,
                  AppSpacing.m,
                  AppSpacing.l,
                  AppSpacing.l,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(
                        minWidth: 260,
                        maxWidth: 360,
                      ),
                      child: InstanceSidebar(
                        instances: _instances,
                        statuses: _statuses,
                        errors: _errors,
                        loadingIds: _statusLoading,
                        selectedId: _selectedId,
                        onSelect: _selectInstance,
                        onAdd: () => _openEditor(),
                        onRefresh: _refresh,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.l),
                    Expanded(child: _buildDetail(selected)),
                  ],
                ),
              )
            : isTablet
                ? Column(
                    children: [
                      const SizedBox(height: AppSpacing.s),
                      InstanceStrip(
                        instances: _instances,
                        statuses: _statuses,
                        errors: _errors,
                        loadingIds: _statusLoading,
                        selectedId: _selectedId,
                        onSelect: _selectInstance,
                        onAdd: () => _openEditor(),
                      ),
                      const SizedBox(height: AppSpacing.s),
                      Expanded(child: _buildDetail(selected)),
                    ],
                  )
                : Column(
                    children: [
                      const SizedBox(height: AppSpacing.s),
                      InstanceStrip(
                        instances: _instances,
                        statuses: _statuses,
                        errors: _errors,
                        loadingIds: _statusLoading,
                        selectedId: _selectedId,
                        onSelect: _selectInstance,
                        onAdd: () => _openEditor(),
                      ),
                      const SizedBox(height: AppSpacing.s),
                      Expanded(child: _buildDetail(selected)),
                    ],
                  );
      },
    );
  }

  Widget _buildDetail(GokrazyInstance? instance) {
    if (instance == null) {
      return const _NoSelection();
    }
    final status = _statuses[instance.id];
    final error = _errors[instance.id];
    final loading = _statusLoading.contains(instance.id) && status == null;
    final busy = _busyInstances.contains(instance.id);
    final upload = _uploadByInstance[instance.id];

    return RefreshIndicator(
      onRefresh: () => _refresh(instance),
      child: AsyncSurface(
        isLoading: loading,
        isEmpty: status == null && error == null,
        isError: error != null && status == null,
        loading: const _DetailSkeleton(),
        empty: const _DetailSkeleton(),
        error: ErrorBanner(
          message: error ?? 'Unable to load status',
          onRetry: () => _refresh(instance),
        ),
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            MediaQuery.sizeOf(context).width >= AppBreakpoints.tablet
                ? 0
                : AppSpacing.m,
            AppSpacing.xs,
            MediaQuery.sizeOf(context).width >= AppBreakpoints.tablet
                ? 0
                : AppSpacing.m,
            AppSpacing.xxl,
          ),
          children: [
            HeroHeaderCard(
              instance: instance,
              status: status,
              hasError: error != null,
              onRefresh: () => _refresh(instance),
              onEdit: () => _openEditor(instance),
              onDelete: () => _deleteInstance(instance),
            ),
            if (error != null) ...[
              const SizedBox(height: AppSpacing.m),
              Semantics(
                liveRegion: true,
                child: ErrorBanner(
                  message: error,
                  onRetry: () => _refresh(instance),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.m),
            if (status != null) ...[
              OverviewCard(status: status),
              const SizedBox(height: AppSpacing.m),
              ResourceCard(status: status),
              const SizedBox(height: AppSpacing.m),
              UpdateCard(
                busy: busy,
                progress: upload?.progress,
                message: upload?.message,
                onUpload: () => _uploadSquashfs(instance),
                onTestboot: () => _runAction(
                  instance,
                  'Test boot marked',
                  (client) => client.testboot(),
                ),
                onSwitch: () => _runAction(
                  instance,
                  'Root switched',
                  (client) => client.switchRoot(),
                ),
                onReboot: () => _runAction(
                  instance,
                  'Reboot requested',
                  (client) => client.reboot(),
                ),
              ),
              const SizedBox(height: AppSpacing.m),
              ServicesCard(
                services: status.services,
                busy: busy,
                onStart: (svc) => _runServiceAction(
                  instance,
                  'Service started',
                  svc,
                  (client) => client.startService(svc.path),
                ),
                onStop: (svc) => _runServiceAction(
                  instance,
                  'Service stopped',
                  svc,
                  (client) => client.stopService(svc.path),
                ),
                onRestart: (svc) => _runServiceAction(
                  instance,
                  'Service restarted',
                  svc,
                  (client) => client.restartService(svc.path),
                ),
                onLogs: (svc) => _openServiceLogs(instance, svc),
                onArgs: _showServiceArgs,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _UploadState {
  const _UploadState({this.progress, this.message});

  final double? progress;
  final String? message;
}

class _NoSelection extends StatelessWidget {
  const _NoSelection();

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      title: 'Pick an appliance',
      message: 'Select a device from the list to see its status, services and '
          'update controls.',
      icon: Icons.dns_outlined,
    );
  }
}

class _ShellSkeleton extends StatelessWidget {
  const _ShellSkeleton();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= AppBreakpoints.desktop;
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.m),
          child: isDesktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: 260,
                        maxWidth: 360,
                      ),
                      child: Column(
                        children: [
                          SkeletonBlock(height: 88),
                          SizedBox(height: AppSpacing.s),
                          SkeletonBlock(height: 88),
                          SizedBox(height: AppSpacing.s),
                          SkeletonBlock(height: 88),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.l),
                    const Expanded(child: _DetailSkeleton()),
                  ],
                )
              : const Column(
                  children: [
                    SkeletonBlock(height: 96),
                    SizedBox(height: AppSpacing.s),
                    Expanded(child: _DetailSkeleton()),
                  ],
                ),
        );
      },
    );
  }
}

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: const [
        SkeletonBlock(height: 200, radius: AppRadius.xl),
        SizedBox(height: AppSpacing.m),
        SkeletonBlock(height: 160),
        SizedBox(height: AppSpacing.m),
        SkeletonBlock(height: 220),
        SizedBox(height: AppSpacing.m),
        SkeletonBlock(height: 280),
      ],
    );
  }
}
