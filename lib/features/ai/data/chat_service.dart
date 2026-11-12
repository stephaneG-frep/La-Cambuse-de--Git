import 'dart:async';

import '../../../core/logging/redactor.dart';
import '../../logbook/data/logbook_repository.dart';
import '../../logbook/domain/audit_outcome.dart';
import '../domain/ai_config.dart';
import '../domain/ai_models.dart';
import 'ai_repositories.dart';
import 'anthropic_provider.dart';

/// Résultat d'un envoi, pour l'interface.
class ChatOutcome {
  const ChatOutcome({this.secretMasked = false, this.usage, this.model});

  final bool secretMasked;
  final AiUsage? usage;
  final String? model;
}

/// Orchestration d'un tour de conversation : budget, masquage des secrets,
/// persistance, refus, récupération de l'historique et journal (métadonnées
/// seulement, jamais le contenu des messages).
class ChatService {
  ChatService({
    required this.provider,
    required this.conversations,
    required this.logbook,
    required this.config,
  });

  final AiProvider provider;
  final ConversationRepository conversations;
  final LogbookRepository logbook;
  final AiConfig config;
  static const _redactor = Redactor();

  /// Envoie [rawText] et diffuse les événements. [onEvent] reçoit les deltas.
  Future<ChatOutcome> send(
    int conversationId,
    String rawText, {
    required void Function(AiEvent) onEvent,
    Completer<void>? cancel,
  }) async {
    final conv = await conversations.conversation(conversationId);
    if (conv == null) throw StateError('Conversation introuvable');
    final budget = config.dailyTokenBudget;
    if (budget > 0 && await conversations.tokensToday() >= budget) {
      throw AiException(AiErrorKind.budgetExceeded,
          'Budget quotidien atteint ($budget jetons). Modifiable dans Paramètres → Professeur IA.');
    }
    final text = _redactor.redact(rawText.trim());
    final masked = text != rawText.trim();
    final userId = await conversations.add(conversationId, AiMessage.userText(text));

    var repaired = false;
    while (true) {
      final history = await conversations.messages(conversationId);
      final request = AiRequest(
        model: conv.model,
        system: conv.systemPrompt,
        messages: history,
        effort: config.kind == AiProviderKind.anthropic ? config.effort : null,
      );
      try {
        AiDone? done;
        final sub = provider.stream(request).listen(null);
        final finished = Completer<void>();
        sub
          ..onData((e) {
            if (e is AiDone) done = e;
            onEvent(e);
          })
          ..onError((Object e, StackTrace s) {
            if (!finished.isCompleted) finished.completeError(e, s);
          })
          ..onDone(() {
            if (!finished.isCompleted) finished.complete();
          });
        if (cancel != null) {
          unawaited(cancel.future.then((_) async {
            await sub.cancel();
            if (!finished.isCompleted) {
              finished.completeError(const AiException(AiErrorKind.cancelled, 'Réponse annulée.'));
            }
          }));
        }
        await finished.future;
        final d = done;
        if (d == null) throw const AiException(AiErrorKind.network, 'Réponse incomplète.');
        if (d.stopReason == 'refusal') {
          await conversations.deleteMessage(userId);
          await _log('Réponse refusée par le modèle', d.model, d.usage, AuditOutcome.failure);
          throw const AiException(AiErrorKind.refusal,
              'Le modèle a refusé de répondre à cette demande. Reformulez la question.');
        }
        await conversations.add(conversationId, d.message, usage: d.usage, model: d.model);
        await _log('Réponse du professeur IA', d.model, d.usage, AuditOutcome.success);
        return ChatOutcome(secretMasked: masked, usage: d.usage, model: d.model);
      } on AiException catch (e) {
        if (!repaired && AnthropicProvider.isThinkingMismatch(e)) {
          repaired = true;
          await conversations.stripThinking(conversationId);
          continue;
        }
        if (e.kind != AiErrorKind.refusal) {
          await conversations.deleteMessage(userId);
          if (e.kind != AiErrorKind.cancelled) {
            await logbook.record(
              category: 'ia',
              action: 'Échec de la requête IA',
              details: '${conv.model} : ${e.kind.name}${e.statusCode == null ? '' : ' (HTTP ${e.statusCode})'}',
              outcome: AuditOutcome.failure,
            );
          }
        }
        throw AiException(e.kind, e.message,
            statusCode: e.statusCode, retryAfter: e.retryAfter);
      }
    }
  }

  Future<void> _log(String action, String model, AiUsage u, AuditOutcome outcome) {
    final cost = AiConfig.estimateCost(model, u);
    return logbook.record(
      category: 'ia',
      action: action,
      details: '$model : ${u.inputTokens} jetons en entrée, ${u.outputTokens} en sortie'
          '${cost == null ? '' : ' (≈ ${cost.toStringAsFixed(4)} \$)'}',
      outcome: outcome,
    );
  }
}
