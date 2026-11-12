import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/db/database.dart';
import '../../../l10n/app_localizations.dart';
import '../../logbook/domain/audit_outcome.dart';
import '../data/ai_repositories.dart';
import '../data/anthropic_provider.dart';
import '../data/chat_service.dart';
import '../data/openai_compatible_provider.dart';
import '../data/secret_store.dart';
import '../domain/ai_config.dart';
import '../domain/ai_models.dart';

/// Coffre de secrets (surchargé par un coffre en mémoire dans les tests).
final secretStoreProvider = Provider<SecretStore>((ref) => OsSecretStore());

String secretKeyFor(AiProviderKind k) => 'ai.api_key.${k.code}';

final aiConfigRepositoryProvider =
    Provider((ref) => AiConfigRepository(ref.watch(databaseProvider)));

final conversationRepositoryProvider =
    Provider((ref) => ConversationRepository(ref.watch(databaseProvider)));

class AiConfigController extends AsyncNotifier<AiConfig> {
  @override
  Future<AiConfig> build() => ref.read(aiConfigRepositoryProvider).load();

  Future<void> save(AiConfig c) async {
    await ref.read(aiConfigRepositoryProvider).save(c);
    state = AsyncData(c);
    await ref.read(logbookRepositoryProvider).record(
          category: 'ia',
          action: 'Paramètres IA modifiés',
          details: '${c.kind.code}, ${c.model}, effort ${c.effort}, budget ${c.dailyTokenBudget}',
          outcome: AuditOutcome.success,
        );
  }
}

final aiConfigProvider =
    AsyncNotifierProvider<AiConfigController, AiConfig>(AiConfigController.new);

/// Indique si une clé est enregistrée, avec ses 4 derniers caractères.
final storedKeyHintProvider = FutureProvider.family<String?, AiProviderKind>((ref, kind) async {
  final k = await ref.watch(secretStoreProvider).read(secretKeyFor(kind));
  if (k == null || k.isEmpty) return null;
  return k.length <= 8 ? '••••' : '${k.substring(0, 6)}…${k.substring(k.length - 4)}';
});

/// Fabrique de fournisseur (surchargeable dans les tests).
final aiProviderFactoryProvider = Provider<AiProvider Function(AiConfig)>((ref) {
  final store = ref.watch(secretStoreProvider);
  return (c) => switch (c.kind) {
        AiProviderKind.anthropic =>
          AnthropicProvider(apiKey: () => store.read(secretKeyFor(c.kind))),
        AiProviderKind.openAiCompatible => OpenAiCompatibleProvider(
            apiKey: () => store.read(secretKeyFor(c.kind)),
            baseUrl: c.baseUrl,
          ),
      };
});

ChatService buildChatService(WidgetRef ref, AiConfig config) => ChatService(
      provider: ref.read(aiProviderFactoryProvider)(config),
      conversations: ref.read(conversationRepositoryProvider),
      logbook: ref.read(logbookRepositoryProvider),
      config: config,
    );

final conversationsProvider = StreamProvider<List<AiConversationRow>>(
  (ref) => ref.watch(conversationRepositoryProvider).watchConversations(),
);

final messagesProvider = StreamProvider.family<List<AiMessageRow>, int>(
  (ref, id) => ref.watch(conversationRepositoryProvider).watchMessages(id),
);

final tokensTodayProvider = FutureProvider.autoDispose<int>((ref) {
  ref.watch(conversationsProvider);
  return ref.watch(conversationRepositoryProvider).tokensToday();
});

/// Message d'erreur concret et localisé.
String describeAiError(AppLocalizations l, AiException e) => switch (e.kind) {
      AiErrorKind.noKey => l.aiErrNoKey,
      AiErrorKind.authentication => l.aiErrAuth,
      AiErrorKind.permission => l.aiErrPermission,
      AiErrorKind.billing => l.aiErrBilling,
      AiErrorKind.notFound => l.aiErrNotFound,
      AiErrorKind.invalidRequest => l.aiErrInvalid(e.message),
      AiErrorKind.tooLarge => l.aiErrTooLarge,
      AiErrorKind.rateLimited => l.aiErrRate,
      AiErrorKind.overloaded => l.aiErrOverloaded,
      AiErrorKind.server => l.aiErrServer('${e.statusCode ?? '5xx'}'),
      AiErrorKind.network => l.aiErrNetwork,
      AiErrorKind.timeout => l.aiErrTimeout,
      AiErrorKind.refusal => l.aiErrRefusal,
      AiErrorKind.budgetExceeded => l.aiErrBudget,
      AiErrorKind.cancelled => l.aiErrCancelled,
      AiErrorKind.unknown => l.aiErrUnknown(e.message),
    };
