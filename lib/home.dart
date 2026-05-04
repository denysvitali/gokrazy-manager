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
  final Set<String> _selectedInstanceIds = {};
  String? _selectedId;
  String? _detailTabInstanceId;
  int _detailTabIndex = 0;
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
    final location =
        GoRouter.of(context).routerDelegate.currentConfiguration.uri.toString();
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
        setState(() {
          _selectedId = resolved;
          _detailTabInstanceId = resolved;
          _detailTabIndex = 0;
        });
      }
      if (_selectedInstanceIds.isNotEmpty) {
        setState(() {
          _selectedInstanceIds.clear();
        });
      }
      return;
    }

    if (_selectedId != null && !_instances.any((entry) => entry.id == _selectedId)) {
      setState(() {
        _selectedId = _instances.isEmpty ? null : _instances.first.id;
        _detailTabInstanceId = _selectedId;
        _detailTabIndex = 0;
      });
    }
    if (_selectedId == null && _instances.isNotEmpty) {
      setState(() {
        _selectedId = _instances.first.id;
        _detailTabInstanceId = _selectedId;
        _detailTabIndex = 0;
      });
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
      _selectedInstanceIds.clear();
      _selectedId = instances.isEmpty ? null : instances.first.id;
      _detailTabInstanceId = _selectedId;
      _detailTabIndex = 0;
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
    await _deleteInstances({instance.id});
  }

  Future<void> _deleteInstances(Set<String> ids) async {
    if (ids.isEmpty) {
      return;
    }
    final repo = _repo;
    if (repo == null) {
      return;
    }

    final selected = _instances.where((entry) => ids.contains(entry.id)).toList();
    if (selected.isEmpty) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final count = selected.length;
        if (count == 1) {
          return AlertDialog(
            title: Text('Delete ${selected.first.name}?'),
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
          );
        }
        return AlertDialog(
          title: Text('Delete $count instances?'),
          content: Text(
            'You are about to remove ${selected.map((entry) => entry.name).join(', ')}. '
            'Their connection details and pinned certificates will be removed.',
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
        );
      },
    );
    if (confirmed != true) {
      return;
    }

    final idSet = ids.toSet();
    final next = _instances.where((entry) => !idSet.contains(entry.id)).toList();
    for (final id in idSet) {
      await repo.deletePassword(id);
    }
    await repo.saveAll(next);

    if (!mounted) {
      return;
    }

    for (final id in idSet) {
      _statuses.remove(id);
      _errors.remove(id);
      _uploadByInstance.remove(id);
      _busyInstances.remove(id);
      _selectedInstanceIds.remove(id);
    }

    final selectedStillExists = _selectedId != null &&
        next.any((entry) => entry.id == _selectedId);
    final nextSelectedId = selectedStillExists
        ? _selectedId
        : (next.isEmpty ? null : next.first.id);

    setState(() {
      _instances = next;
      _selectedId = nextSelectedId;
    });
    if (_routeTab == 0) {
      _persistRouteForSelection();
    }
  }

  Future<void> _deleteSelectedInstances() async {
    await _deleteInstances(_selectedInstanceIds.toSet());
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

  void _toggleInstanceSelection(String id) {
    if (!_instances.any((entry) => entry.id == id)) {
      return;
    }
    setState(() {
      if (_selectedInstanceIds.contains(id)) {
        _selectedInstanceIds.remove(id);
      } else {
        _selectedInstanceIds.add(id);
      }
    });
  }

  void _clearInstanceSelection() {
    if (_selectedInstanceIds.isEmpty) {
      return;
    }
    setState(() => _selectedInstanceIds.clear());
  }

  void _selectInstance(String id) {
    if (_selectedInstanceIds.isNotEmpty) {
      _toggleInstanceSelection(id);
      return;
    }
    if (!_instances.any((entry) => entry.id == id)) {
      return;
    }
    setState(() {
      _selectedId = id;
      _detailTabInstanceId = id;
      _detailTabIndex = 0;
    });
    _navigateToRoute('/instance/$id');
  }

  void _switchTab(int index) {
    _clearInstanceSelection();
    if (index == 1) {
      _navigateToRoute('/settings');
    } else if (_selectedId != null) {
      _navigateToRoute('/instance/$_selectedId');
    } else {
      _navigateToRoute('/');
    }
  }

  void _navigateToRoute(String destination) {
    final current =
        GoRouter.of(context).routerDelegate.currentConfiguration.uri.toString();
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
    _clearInstanceSelection();
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
    final files = picked?.files ?? const <PlatformFile>[];
    if (files.isEmpty) {
      _showSnack('No file selected');
      return;
    }
    final file = files.first;
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
          final ratio = sent / total;
          // Note: progress reaches 100% when all data is buffered locally.
          // The server may still be writing the large image to disk.
          // We cap at 99% to indicate we're waiting for server response.
          final progress = ratio >= 1.0 ? 0.99 : ratio.clamp(0.0, 0.99);
          setState(() {
            _uploadByInstance[instance.id] = _UploadState(
              progress: progress.toDouble(),
              message:
                  ratio >= 1.0
                      ? 'Waiting for device to write image...'
                      : 'Uploading ${file.name}${isGzipped ? ' (decompressing)' : ''}',
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
    } on StateError catch (error) {
      _showSnack(error.message);
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
    final location =
        GoRouter.of(context).routerDelegate.currentConfiguration.uri;
    final isInstanceDetailRoute = location.pathSegments.length == 2 &&
        location.pathSegments.first == 'instance';
    final detailTabs = isInstanceDetailRoute ? _tabsForCurrentInstance(selected) : null;
    final activeDetailTabIndex = detailTabs == null || detailTabs.isEmpty
        ? 0
        : (_detailTabIndex < 0 || _detailTabIndex >= detailTabs.length
            ? 0
            : _detailTabIndex);

    final showInstanceNav = isInstanceDetailRoute && detailTabs != null;

    final body = AnimatedSwitcher(
      duration: motionDuration(context, AppMotion.fast),
      child: _loading
          ? const _ShellSkeleton()
          : _routeTab == 1
              ? const SettingsPanel()
              : _buildDashboard(context, selected, isInstanceDetailRoute),
    );

    final routedBody = WillPopScope(
      onWillPop: () async {
        if (isInstanceDetailRoute) {
          _navigateToRoute('/');
          return false;
        }
        return true;
      },
      child: body,
    );

    final scaffold = Scaffold(
      appBar: _buildAppBar(selected, isInstanceDetailRoute),
      floatingActionButton: _routeTab == 0 && !_loading && !isInstanceDetailRoute
              ? FloatingActionButton.extended(
                  onPressed: () => _openEditor(),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add appliance'),
                )
              : null,
      body: SafeArea(child: routedBody),
      bottomNavigationBar: useRail
          ? null
          : NavigationBar(
              selectedIndex: showInstanceNav
                  ? activeDetailTabIndex
                  : _routeTab,
              onDestinationSelected: (index) {
                if (showInstanceNav && detailTabs != null) {
                  if (index >= 0 && index < detailTabs.length) {
                    setState(() => _detailTabIndex = index);
                  }
                  return;
                }
                _switchTab(index);
              },
              destinations: showInstanceNav
                  ? [
                      for (final tab in detailTabs ?? const <_InstanceTab>[])
                        NavigationDestination(
                          icon: Icon(tab.icon),
                          selectedIcon: Icon(tab.icon),
                          label: tab.label,
                        ),
                    ]
                  : [
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
            selectedIndex: showInstanceNav
                ? activeDetailTabIndex
                : _routeTab,
            onDestinationSelected: (index) {
              if (showInstanceNav && detailTabs != null) {
                if (index >= 0 && index < detailTabs.length) {
                  setState(() => _detailTabIndex = index);
                }
                return;
              }
              _switchTab(index);
            },
            labelType: NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
              child: GradientIconBadge(
                icon: Icons.memory_rounded,
                size: 48,
              ),
            ),
            destinations: showInstanceNav
                ? [
                    for (final tab in detailTabs ?? const <_InstanceTab>[])
                      NavigationRailDestination(
                        icon: Icon(tab.icon),
                        selectedIcon: Icon(tab.icon),
                        label: Text(tab.label),
                      ),
                  ]
                : const [
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

  PreferredSizeWidget _buildAppBar(
    GokrazyInstance? selected,
    bool isInstanceDetailRoute,
  ) {
    final theme = Theme.of(context);
    final selectedCount = _selectedInstanceIds.length;
    final isSelectionMode = selectedCount > 0;
    GokrazyInstance? selectedForEdit;
    if (isSelectionMode && _selectedInstanceIds.length == 1) {
      final id = _selectedInstanceIds.first;
      for (final instance in _instances) {
        if (instance.id == id) {
          selectedForEdit = instance;
          break;
        }
      }
    }
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
              isSelectionMode ? '$selectedCount selected' : 'Gokrazy',
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
      leading: isSelectionMode
          ? IconButton(
              tooltip: 'Exit select mode',
              onPressed: _clearInstanceSelection,
              icon: const Icon(Icons.close_rounded),
            )
          : isInstanceDetailRoute
              ? IconButton(
                  tooltip: 'Back',
                  onPressed: () => _navigateToRoute('/'),
                  icon: const Icon(Icons.arrow_back_rounded),
                )
          : null,
      actions: [
        if (isSelectionMode && selectedForEdit != null)
          Semantics(
            button: true,
            label: 'Edit selected appliance',
            hint: 'Open edit sheet for selected appliance',
            child: IconButton(
              tooltip: 'Edit selected',
              onPressed: () => _openEditor(selectedForEdit),
              icon: const Icon(Icons.edit_rounded),
            ),
          ),
        if (isSelectionMode)
          Semantics(
            button: true,
            label: 'Delete selected appliances',
            hint: 'Delete all selected appliances',
            child: IconButton(
              tooltip: 'Delete selected',
              onPressed: _deleteSelectedInstances,
              icon: const Icon(Icons.delete_sweep_rounded),
            ),
          ),
        if (_routeTab == 0 && _instances.isNotEmpty && !isInstanceDetailRoute)
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
        const SizedBox(width: AppSpacing.xs),
      ],
    );
  }

  List<_InstanceTab>? _tabsForCurrentInstance(GokrazyInstance? selected) {
    if (selected == null) {
      return null;
    }
    final status = _statuses[selected.id];
    if (status == null) {
      return null;
    }
    return _tabsForStatus(status);
  }

  Widget _buildDashboard(BuildContext context, GokrazyInstance? selected, bool showDetail) {
    if (_instances.isEmpty) {
      return EmptyState(
        title: 'No appliances yet',
        message: 'Add your first gokrazy device to get started.',
        actionLabel: 'Add appliance',
        onAction: () => _openEditor(),
        icon: Icons.dns_rounded,
      );
    }

    if (showDetail) {
      return _buildDetail(selected);
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
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 260,
                    maxWidth: 420,
                  ),
                  child: InstanceSidebar(
                    instances: _instances,
                    statuses: _statuses,
                    errors: _errors,
                    loadingIds: _statusLoading,
                    selectedId: _selectedId,
                    onSelect: _selectInstance,
                    selectedIds: _selectedInstanceIds,
                    onLongPress: _toggleInstanceSelection,
                    onAdd: () => _openEditor(),
                    onRefresh: _refresh,
                  ),
                ),
              )
                    : isTablet
                    ? Column(
                        children: [
                          const SizedBox(height: AppSpacing.s),
                          Expanded(
                    child: InstanceStrip(
                      instances: _instances,
                      statuses: _statuses,
                      errors: _errors,
                      loadingIds: _statusLoading,
                      selectedId: _selectedId,
                      selectedIds: _selectedInstanceIds,
                      onLongPress: _toggleInstanceSelection,
                      onSelect: _selectInstance,
                    ),
                  ),
                        ],
                  )
                : Column(
                    children: [
                      const SizedBox(height: AppSpacing.s),
                      Expanded(
                        child: InstanceStrip(
                          instances: _instances,
                          statuses: _statuses,
                          errors: _errors,
                          loadingIds: _statusLoading,
                          selectedId: _selectedId,
                          selectedIds: _selectedInstanceIds,
                          onLongPress: _toggleInstanceSelection,
                          onSelect: _selectInstance,
                        ),
                      ),
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
    final tabs = status == null ? const <_InstanceTab>[] : _tabsForStatus(status);
    final tabIndex = _detailTabInstanceId != instance.id ||
            _detailTabIndex >= tabs.length
        ? 0
        : _detailTabIndex;
    if (tabIndex != _detailTabIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _detailTabIndex = tabIndex);
        }
      });
    }

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
              if (tabs.isNotEmpty) ...[
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SegmentedButton<int>(
                    segments: [
                      for (final tab in tabs)
                        ButtonSegment<int>(
                          value: tab.index,
                          label: Text(tab.label),
                          icon: Icon(tab.icon),
                        ),
                    ],
                    selected: <int>{tabs[tabIndex].index},
                    onSelectionChanged: (selected) {
                      final next = selected.first;
                      setState(() => _detailTabIndex = next);
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.m),
                AnimatedSwitcher(
                  duration: motionDuration(context, AppMotion.fast),
                    child: _detailTabBody(
                    instance: instance,
                    status: status,
                    tabIndex: tabIndex,
                    tabs: tabs,
                    busy: busy,
                    upload: upload,
                  ),
                ),
              ] else
                const EmptyState(
                  title: 'No detail sections',
                  message: 'This appliance returned no actionable status fields.',
                  icon: Icons.remove_red_eye_outlined,
                ),
            ],
          ],
        ),
      ),
    );
  }

  List<_InstanceTab> _tabsForStatus(GokrazyStatus status) {
    final tabs = <_InstanceTab>[
      _InstanceTab(
        index: 0,
        label: 'Overview',
        icon: Icons.dashboard_customize_rounded,
        builder: (context, instance, status, busy, upload) =>
            _buildOverviewSection(
              status: status,
            ),
      ),
    ];

    final hasResourceData = status.memTotal != null ||
        status.memAvailable != null ||
        status.permTotal != null ||
        status.permUsed != null;
    if (hasResourceData) {
      tabs.add(
        _InstanceTab(
          index: tabs.length,
          label: 'Resources',
          icon: Icons.tune_rounded,
          builder: (context, instance, status, busy, upload) =>
              _buildResourceSection(status: status),
        ),
      );
    }

    final hasServices = status.services.isNotEmpty;
    if (hasServices) {
      tabs.add(
        _InstanceTab(
          index: tabs.length,
          label: 'Services',
          icon: Icons.miscellaneous_services_rounded,
          builder: (context, instance, status, busy, upload) =>
              _buildServicesSection(
                instance: instance,
                services: status.services,
                busy: busy,
              ),
        ),
      );
    }

    tabs.add(
        _InstanceTab(
          index: tabs.length,
          label: 'Update',
          icon: Icons.system_update_alt_rounded,
          builder: (context, instance, status, busy, upload) =>
            _buildUpdateSection(
              instance: instance,
              busy: busy,
              progress: upload?.progress,
              message: upload?.message,
            ),
      ),
    );

    return tabs;
  }

  Widget _detailTabBody({
    required GokrazyInstance instance,
    required GokrazyStatus status,
    required int tabIndex,
    required List<_InstanceTab> tabs,
    required bool busy,
    required _UploadState? upload,
  }) {
    if (tabIndex < 0 || tabIndex >= tabs.length) {
      return const SizedBox.shrink();
    }
    final tab = tabs[tabIndex];
    return Column(
      key: ValueKey('${instance.id}-tab-${tab.index}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Builder(
          builder: (context) =>
              tab.builder(context, instance, status, busy, upload),
        ),
      ],
    );
  }

  Widget _buildOverviewSection({required GokrazyStatus status}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OverviewCard(status: status),
      ],
    );
  }

  Widget _buildResourceSection({required GokrazyStatus status}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ResourceCard(status: status),
      ],
    );
  }

  Widget _buildServicesSection({
    required GokrazyInstance instance,
    required List<GokrazyService> services,
    required bool busy,
  }) {
    final hasServices = services.isNotEmpty;
    if (!hasServices) {
      return const EmptyState(
        title: 'No services',
        message: 'This appliance has no supervised services.',
        icon: Icons.miscellaneous_services_outlined,
      );
    }

    return ServicesCard(
      services: services,
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
    );
  }

  Widget _buildUpdateSection({
    required GokrazyInstance instance,
    required bool busy,
    required double? progress,
    required String? message,
  }) {
    return UpdateCard(
      busy: busy,
      progress: progress,
      message: message,
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
    );
  }
}

class _InstanceTab {
  const _InstanceTab({
    required this.index,
    required this.label,
    required this.icon,
    required this.builder,
  });

  final int index;
  final String label;
  final IconData icon;
  final Widget Function(
    BuildContext context,
    GokrazyInstance instance,
    GokrazyStatus status,
    bool busy,
    _UploadState? upload,
  ) builder;
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
                    ConstrainedBox(
                      constraints: const BoxConstraints(
                        minWidth: 260,
                        maxWidth: 360,
                      ),
                      child: Column(
                        children: const [
                          SkeletonBlock(height: 88),
                          SizedBox(height: AppSpacing.s),
                          SkeletonBlock(height: 88),
                          SizedBox(height: AppSpacing.s),
                          SkeletonBlock(height: 88),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.l),
                    Expanded(child: _DetailSkeleton()),
                  ],
                )
              : Column(
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
