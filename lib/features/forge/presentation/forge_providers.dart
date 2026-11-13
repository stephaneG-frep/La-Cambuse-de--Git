import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../l10n/app_localizations.dart';
import '../../ai/presentation/ai_providers.dart';
import '../data/forge_client.dart';

String forgeTokenKey(ForgeKind k) => 'forge.${k.code}.token';
const gitlabUrlKey = 'forge.gitlab.url';

/// Fabrique de clients de forge (surchargeable dans les tests).
final forgeFactoryProvider = Provider<Forge Function(ForgeKind, {String? host})>((ref) {
  final secrets = ref.watch(secretStoreProvider);
  return (kind, {host}) => switch (kind) {
        ForgeKind.github => GitHubForge(token: () => secrets.read(forgeTokenKey(kind))),
        ForgeKind.gitlab => GitLabForge(
            token: () => secrets.read(forgeTokenKey(kind)),
            baseUrl: host != null ? 'https://$host' : 'https://gitlab.com',
          ),
      };
});

/// URL de l'instance GitLab enregistrée (par défaut gitlab.com).
final gitlabUrlProvider = FutureProvider<String>((ref) async {
  final db = ref.watch(databaseProvider);
  final row = await (db.select(db.appSettingsTable)..where((t) => t.key.equals(gitlabUrlKey))).getSingleOrNull();
  return row?.value ?? 'https://gitlab.com';
});

final forgeTokenPresentProvider = FutureProvider.family<bool, ForgeKind>((ref, kind) async {
  final t = await ref.watch(secretStoreProvider).read(forgeTokenKey(kind));
  return t != null && t.isNotEmpty;
});

String describeForgeError(AppLocalizations l, ForgeException e, ForgeKind kind) => switch (e.kind) {
      ForgeErrorKind.noToken => l.pbErrNoToken,
      ForgeErrorKind.authentication => l.pbErrAuth,
      ForgeErrorKind.forbidden => l.pbErrForbidden(e.message),
      ForgeErrorKind.rateLimited => l.pbErrRate,
      ForgeErrorKind.notFound => l.pbErrNotFound,
      ForgeErrorKind.validation => l.pbErrValidation(e.message),
      ForgeErrorKind.network => l.pbErrNetwork(kind.label),
      ForgeErrorKind.unknown => l.pbErrUnknown(e.message),
    };
