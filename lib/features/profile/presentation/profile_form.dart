import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../app/theme/theme.dart';
import '../../../app/theme/tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../data/profile_repository.dart';

/// Formulaire de création du profil local.
class ProfileForm extends ConsumerStatefulWidget {
  const ProfileForm({super.key});

  @override
  ConsumerState<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends ConsumerState<ProfileForm> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  Object? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(profileRepositoryProvider).save(_controller.text);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final pal = CambuseTheme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(CambuseSpacing.md),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.createProfileTitle, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: CambuseSpacing.md),
              TextFormField(
                controller: _controller,
                maxLength: ProfileRepository.maxLength,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                decoration: InputDecoration(labelText: l.createProfileHint),
                validator: (v) {
                  try {
                    ProfileRepository.validate(v ?? '');
                    return null;
                  } on InvalidProfileName {
                    return l.createProfileInvalid;
                  }
                },
              ),
              const SizedBox(height: CambuseSpacing.sm),
              Text(l.profileLocalNote, style: TextStyle(color: pal.textSecondary)),
              if (_error != null) ...[
                const SizedBox(height: CambuseSpacing.sm),
                Text(l.errorGeneric('$_error'), style: TextStyle(color: pal.alert)),
              ],
              const SizedBox(height: CambuseSpacing.md),
              FilledButton.icon(
                onPressed: _saving ? null : _submit,
                icon: const Icon(Icons.anchor),
                label: Text(l.createProfileAction),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
