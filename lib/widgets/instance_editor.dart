import 'package:flutter/material.dart';

import '../api.dart';
import '../models.dart';
import '../theme.dart';
import 'common.dart';

class InstanceEditor extends StatefulWidget {
  const InstanceEditor({
    required this.instance,
    required this.password,
    required this.onSave,
    super.key,
  });

  final GokrazyInstance? instance;
  final String password;
  final Future<void> Function(GokrazyInstance instance, String password) onSave;

  @override
  State<InstanceEditor> createState() => _InstanceEditorState();
}

class _InstanceEditorState extends State<InstanceEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _url;
  late final TextEditingController _username;
  late final TextEditingController _password;
  bool _saving = false;
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.instance?.name ?? '');
    _url = TextEditingController(text: widget.instance?.baseUrl ?? 'https://');
    _username = TextEditingController(
      text: widget.instance?.username ?? 'gokrazy',
    );
    _password = TextEditingController(text: widget.password);
  }

  @override
  void dispose() {
    _name.dispose();
    _url.dispose();
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _saving = true);
    final current = widget.instance;
    final instance = GokrazyInstance(
      id: current?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      name: _name.text.trim(),
      baseUrl: normalizeUrl(_url.text),
      username: _username.text.trim(),
      pinnedFingerprint: current?.pinnedFingerprint,
      lastSeen: current?.lastSeen,
    );
    try {
      await widget.onSave(instance, _password.text);
      if (mounted) {
        Navigator.pop(context);
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final inset = MediaQuery.of(context).viewInsets.bottom;
    final editing = widget.instance != null;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.l,
        AppSpacing.s,
        AppSpacing.l,
        inset + AppSpacing.l,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                GradientIconBadge(
                  icon: editing ? Icons.edit_rounded : Icons.add_rounded,
                  size: 48,
                ),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        editing ? 'Edit instance' : 'Add appliance',
                        style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        editing
                            ? 'Update the connection details for ${widget.instance!.name}.'
                            : 'Point the manager at a gokrazy device.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.l),
            TextFormField(
              controller: _name,
              autofocus: !editing,
              decoration: const InputDecoration(
                labelText: 'Display name',
                hintText: 'e.g. Pi 5 NAS',
                prefixIcon: Icon(Icons.label_important_outline_rounded),
              ),
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Required' : null,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppSpacing.s + 2),
            TextFormField(
              controller: _url,
              decoration: const InputDecoration(
                labelText: 'Appliance URL',
                hintText: 'https://gokrazy.local',
                prefixIcon: Icon(Icons.public_rounded),
              ),
              keyboardType: TextInputType.url,
              autocorrect: false,
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Required';
                }
                final uri = Uri.tryParse(normalizeUrl(value));
                if (uri == null || !uri.hasAuthority) {
                  return 'Invalid URL';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.s + 2),
            TextFormField(
              controller: _username,
              decoration: const InputDecoration(
                labelText: 'Username',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              autocorrect: false,
              textInputAction: TextInputAction.next,
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: AppSpacing.s + 2),
            TextFormField(
              controller: _password,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.key_rounded),
                suffixIcon: IconButton(
                  tooltip: _showPassword ? 'Hide password' : 'Show password',
                  onPressed: () =>
                      setState(() => _showPassword = !_showPassword),
                  icon: Icon(
                    _showPassword
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                  ),
                ),
              ),
              obscureText: !_showPassword,
              validator: (value) =>
                  value == null || value.isEmpty ? 'Required' : null,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _saving ? null : _save(),
            ),
            const SizedBox(height: AppSpacing.s),
            Container(
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: scheme.primary.withValues(alpha: 0.22),
                ),
              ),
              padding: const EdgeInsets.all(AppSpacing.s + 2),
              child: Row(
                children: [
                  Icon(
                    Icons.lock_rounded,
                    size: 18,
                    color: scheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.s),
                  Expanded(
                    child: Text(
                      'Credentials are stored in the platform secure keystore. '
                      'A self-signed certificate prompt will appear on first connect.',
                      style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.l),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        _saving ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: AppSpacing.s),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : Icon(
                            editing ? Icons.save_rounded : Icons.add_rounded,
                          ),
                    label: Text(_saving
                        ? 'Saving...'
                        : (editing ? 'Save changes' : 'Add appliance')),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
