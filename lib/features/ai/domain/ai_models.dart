import 'package:flutter/foundation.dart';

/// Familles de fournisseurs prises en charge.
enum AiProviderKind {
  anthropic('anthropic'),
  openAiCompatible('openai_compatible');

  const AiProviderKind(this.code);
  final String code;

  static AiProviderKind fromCode(String? c) =>
      values.firstWhere((k) => k.code == c, orElse: () => anthropic);
}

/// Message d'une conversation. [content] est la liste brute des blocs telle que
/// renvoyée par le fournisseur (texte, réflexion signée…) : elle est rejouée
/// **sans modification** aux tours suivants.
@immutable
class AiMessage {
  const AiMessage({required this.role, required this.content});

  factory AiMessage.userText(String text) => AiMessage(role: 'user', content: [
        {'type': 'text', 'text': text},
      ]);

  final String role; // 'user' | 'assistant'
  final List<Map<String, dynamic>> content;

  /// Texte visible (concaténation des blocs « text »).
  String get text => content
      .where((b) => b['type'] == 'text')
      .map((b) => b['text'] as String? ?? '')
      .join();
}

@immutable
class AiRequest {
  const AiRequest({
    required this.model,
    required this.system,
    required this.messages,
    this.maxTokens = 16000,
    this.effort,
  });

  final String model;
  final String system;
  final List<AiMessage> messages;
  final int maxTokens;

  /// low | medium | high (null : valeur par défaut du modèle).
  final String? effort;
}

@immutable
class AiUsage {
  const AiUsage({this.inputTokens = 0, this.outputTokens = 0});
  final int inputTokens;
  final int outputTokens;
  int get total => inputTokens + outputTokens;
}

/// Catégories d'erreur présentées à l'utilisateur avec un message concret.
enum AiErrorKind {
  noKey,
  authentication, // 401
  permission, // 403
  billing, // 402
  notFound, // 404 (modèle inconnu)
  invalidRequest, // 400
  tooLarge, // 413
  rateLimited, // 429
  overloaded, // 529
  server, // 5xx
  network,
  timeout,
  refusal,
  budgetExceeded,
  cancelled,
  unknown,
}

class AiException implements Exception {
  const AiException(this.kind, this.message, {this.statusCode, this.retryAfter});

  final AiErrorKind kind;
  final String message;
  final int? statusCode;
  final Duration? retryAfter;

  bool get retryable => switch (kind) {
        AiErrorKind.rateLimited ||
        AiErrorKind.overloaded ||
        AiErrorKind.server ||
        AiErrorKind.network ||
        AiErrorKind.timeout =>
          true,
        _ => false,
      };

  @override
  String toString() => 'AiException($kind${statusCode == null ? '' : ', $statusCode'}): $message';
}

/// Événements émis pendant une réponse en flux.
sealed class AiEvent {
  const AiEvent();
}

class AiTextDelta extends AiEvent {
  const AiTextDelta(this.text);
  final String text;
}

/// Le modèle réfléchit (aucun texte visible pour l'instant).
class AiThinking extends AiEvent {
  const AiThinking();
}

class AiDone extends AiEvent {
  const AiDone({
    required this.message,
    required this.usage,
    required this.stopReason,
    required this.model,
  });

  final AiMessage message;
  final AiUsage usage;
  final String? stopReason;

  /// Modèle ayant réellement servi la réponse (peut différer en cas de repli).
  final String model;
}

/// Contrat commun à tous les fournisseurs.
abstract interface class AiProvider {
  /// Diffuse la réponse. Termine par [AiDone] ou lève une [AiException].
  Stream<AiEvent> stream(AiRequest request);

  /// Vérifie la clé et le modèle sans générer de texte (aucun coût de génération).
  Future<void> checkConnection(String model);
}
