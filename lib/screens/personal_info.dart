import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hybstockadvisor/theme/tokens.dart';
import 'package:hybstockadvisor/widgets/ui.dart';
import 'package:image_picker/image_picker.dart';

/// Name and photo, stored on this phone.
class PersonalInfo extends StatefulWidget {
  const PersonalInfo({super.key});

  @override
  State<PersonalInfo> createState() => _PersonalInfoState();
}

class _PersonalInfoState extends State<PersonalInfo> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  bool _isLoading = false;
  String? _avatarPath;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final box = await Hive.openBox('user');
    if (!mounted) return;
    setState(() {
      _firstNameController.text = box.get('first_name', defaultValue: '');
      _lastNameController.text = box.get('last_name', defaultValue: '');
      _avatarPath = box.get('avatar_path');
    });
  }

  Future<void> _pickImage() async {
    await showAppSheet<void>(
      context,
      (ctx) => SheetFrame(
        title: 'Profile photo',
        padding: const EdgeInsets.only(bottom: Gap.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SheetOption(
              icon: Icons.photo_library_outlined,
              label: 'Choose from library',
              onTap: () async {
                Navigator.pop(ctx);
                await _pickFromSource(ImageSource.gallery);
              },
            ),
            _SheetOption(
              icon: Icons.photo_camera_outlined,
              label: 'Take a photo',
              onTap: () async {
                Navigator.pop(ctx);
                await _pickFromSource(ImageSource.camera);
              },
            ),
            if (_avatarPath != null)
              _SheetOption(
                icon: Icons.delete_outline,
                label: 'Remove photo',
                destructive: true,
                onTap: () async {
                  Navigator.pop(ctx);
                  final box = await Hive.openBox('user');
                  await box.delete('avatar_path');
                  if (mounted) setState(() => _avatarPath = null);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFromSource(ImageSource source) async {
    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 600,
    );
    if (picked != null) {
      final box = await Hive.openBox('user');
      await box.put('avatar_path', picked.path);
      if (mounted) setState(() => _avatarPath = picked.path);
    }
  }

  Future<void> _saveChanges() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    if (firstName.isEmpty) {
      showNotice(context, 'Enter a first name.');
      return;
    }

    setState(() => _isLoading = true);
    // Let the spinner render before Hive completes synchronously.
    await Future.delayed(Duration.zero);
    final box = await Hive.openBox('user');
    await box.put('first_name', firstName);
    await box.put('last_name', lastName);
    if (!mounted) return;
    setState(() => _isLoading = false);
    showNotice(context, 'Saved.');
    Navigator.pop(context, true);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final t = context.text;
    final initials = [_firstNameController.text, _lastNameController.text]
        .where((w) => w.trim().isNotEmpty)
        .map((w) => w.trim()[0].toUpperCase())
        .join();
    final fallback = Center(
      child: Text(initials.isEmpty ? '?' : initials, style: AppType.serif(size: 30, color: p.inkMuted)),
    );

    return Scaffold(
      backgroundColor: p.paper,
      appBar: AppBar(title: const Text('Personal info')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(Gap.page, Gap.md, Gap.page, Gap.xxl),
          children: [
            Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: p.surface,
                    border: Border.all(color: p.rule),
                  ),
                  child: ClipOval(
                    child: _avatarPath == null
                        ? fallback
                        : Image.file(
                            File(_avatarPath!),
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => fallback,
                          ),
                  ),
                ),
                const SizedBox(width: Gap.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LinkText(_avatarPath == null ? 'Add a photo' : 'Change photo', arrow: false, onTap: _pickImage),
                      Text('Your photo stays on this phone.', style: t.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: Gap.xl),
            const HeavyRule(),
            const SizedBox(height: Gap.xl),
            TextField(
              controller: _firstNameController,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(labelText: 'First name'),
            ),
            const SizedBox(height: Gap.md),
            TextField(
              controller: _lastNameController,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _saveChanges(),
              decoration: const InputDecoration(labelText: 'Last name'),
            ),
            const SizedBox(height: Gap.xl),
            PrimaryButton('Save changes', onPressed: _saveChanges, loading: _isLoading),
          ],
        ),
      ),
    );
  }
}

class _SheetOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;
  const _SheetOption({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final color = destructive ? p.down : p.ink;
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: Gap.lg),
                Text(label, style: context.text.bodyLarge?.copyWith(color: color)),
              ],
            ),
          ),
          const Hairline(),
        ],
      ),
    );
  }
}
