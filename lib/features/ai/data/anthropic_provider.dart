import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/logging/redactor.dart';
import '../domain/ai_models.dart';
import 'sse_decoder.dart';

/// Adaptateur pour l'API Messages d'Anthropic (HTTP brut : pas de SDK Dart
/// officiel). Réponses en flux SSE, nouvelles tentatives sur 429/5xx/529 avant
/// le premier jeton, repli serveur en cas de refus.
class AnthropicProvider implements AiProvider {
  AnthropicProvider({
    required this._apiKey,
    http.Client? client,
    this.baseUrl = 'https://api.anthropic.com',
    this.maxRetries = 2,
    this.idleTimeout = const Duration(seconds: 90),
    Future<void> Function(Duration)? sleep,
  })  : _client = client ?? http.Client(),
        _sleep = sleep ?? Future.delayed;

  static const apiVersion = '2026-10-21';
  static const fallbackBeta = 'server-side-fallback-2026-07-01';

  /// Modèles acceptant le repli serveur `fallbacks: "default"`.
  static const fallbackModels = {
    'claude-opus-5-5',
    'claude-opus-5',
    'claude-sonnet-5-5',
    'claude-fable-5-2',
    'claude-fable-5-1',
  };

  final Future<String?> Function() _apiKey;
  final http.Client _client;
  final String baseUrl;
  final int maxRetries;
  final Duration idleTimeout;
  final Future<void> Function(Duration) _sleep;
  static const _redactor = Redactor();

  Future<Map<String, String>> _headers({required bool fallback}) async {
    final key = await _apiKey();
    if (key == null || key.trim().isEmpty) {
      throw const AiException(AiErrorKind.noKey, 'Aucune clé API Anthropic configurée.');
    }
    return {
      'content-type': 'application/json',
      'x-api-key': key.trim(),
      'anthropic-version': apiVersion,
      if (fallback) 'anthropic-beta': fallbackBeta,
    };
  }

  /// Corps de requête (exposé pour les tests).
  static Map<String, dynamic> buildBody(AiRequest r) => {
        'model': r.model,
        'max_tokens': r.maxTokens,
        'stream': true,
        'system': r.system,
        'messages': [
          for (final m in r.messages) {'role': m.role, 'content': m.content},
        ],
        if (r.effort != null) 'output_config': {'effort': r.effort},
        if (fallbackModels.contains(r.model)) 'fallbacks': 'default',
      };

  @override
  Future<void> checkConnection(String model) async {
    final headers = await _headers(fallback: false)..remove('content-type');
    final http.Response res;
    try {
      res = await _client
          .get(Uri.parse('$baseUrl/v1/models/${Uri.encodeComponent(model)}'), headers: headers)
          .timeout(const Duration(seconds: 20));
    } on TimeoutException {
      throw const AiException(AiErrorKind.timeout, 'Délai dépassé en contactant api.anthropic.com.');
    } on http.ClientException catch (e) {
      throw AiException(AiErrorKind.network, 'Réseau indisponible : ${e.message}');
    }
    if (res.statusCode != 200) throw errorFromResponse(res.statusCode, res.body, res.headers);
  }

  @override
  Stream<AiEvent> stream(AiRequest request) async* {
    final body = jsonEncode(buildBody(request));
    final fallback = fallbackModels.contains(request.model);
    var attempt = 0;
    while (true) {
      final headers = await _headers(fallback: fallback);
      final req = http.Request('POST', Uri.parse('$baseUrl/v1/messages'))
        ..headers.addAll(headers)
        ..body = body;
      http.StreamedResponse res;
      try {
        res = await _client.send(req).timeout(const Duration(seconds: 60));
      } on TimeoutException {
        if (attempt++ < maxRetries) {
          await _sleep(_backoff(attempt, null));
          continue;
        }
        throw const AiException(AiErrorKind.timeout, 'Pas de réponse d\'Anthropic après 60 s.');
      } on http.ClientException catch (e) {
        if (attempt++ < maxRetries) {
          await _sleep(_backoff(attempt, null));
          continue;
        }
        throw AiException(AiErrorKind.network, 'Réseau indisponible : ${e.message}');
      }
      if (res.statusCode != 200) {
        final text = await res.stream.bytesToString();
        final err = errorFromResponse(res.statusCode, text, res.headers);
        if (err.retryable && attempt++ < maxRetries) {
          await _sleep(_backoff(attempt, err.retryAfter));
          continue;
        }
        throw err;
      }
      yield* _parse(res.stream.timeout(idleTimeout, onTimeout: (sink) {
        sink.addError(const AiException(AiErrorKind.timeout, 'Flux interrompu : aucune donnée depuis 90 s.'));
        sink.close();
      }), request.model);
      return;
    }
  }

  Duration _backoff(int attempt, Duration? retryAfter) =>
      retryAfter ?? Duration(seconds: 1 << (attempt - 1));

  /// Reconstruit les blocs de contenu à partir des événements SSE, en
  /// conservant intégralement les blocs de réflexion signés.
  Stream<AiEvent> _parse(Stream<List<int>> bytes, String requestedModel) async* {
    final blocks = <int, Map<String, dynamic>>{};
    var model = requestedModel;
    var input = 0, output = 0;
    String? stopReason;
    var thinkingSignaled = false;

    await for (final e in decodeSse(bytes)) {
      final Map<String, dynamic> d;
      try {
        d = jsonDecode(e.data) as Map<String, dynamic>;
      } on FormatException {
        continue;
      }
      switch (d['type']) {
        case 'message_start':
          final m = d['message'] as Map<String, dynamic>;
          model = m['model'] as String? ?? model;
          final u = m['usage'] as Map<String, dynamic>?;
          input = (u?['input_tokens'] as int?) ?? 0;
          output = (u?['output_tokens'] as int?) ?? 0;
        case 'content_block_start':
          final b = Map<String, dynamic>.of(d['content_block'] as Map<String, dynamic>);
          blocks[d['index'] as int] = b;
          if ((b['type'] == 'thinking' || b['type'] == 'redacted_thinking') && !thinkingSignaled) {
            thinkingSignaled = true;
            yield const AiThinking();
          }
        case 'content_block_delta':
          final b = blocks[d['index'] as int];
          final delta = d['delta'] as Map<String, dynamic>;
          if (b == null) continue;
          switch (delta['type']) {
            case 'text_delta':
              final t = delta['text'] as String;
              b['text'] = (b['text'] as String? ?? '') + t;
              yield AiTextDelta(t);
            case 'thinking_delta':
              b['thinking'] = (b['thinking'] as String? ?? '') + (delta['thinking'] as String);
            case 'signature_delta':
              b['signature'] = delta['signature'];
            case 'input_json_delta':
              b['_partial_json'] = (b['_partial_json'] as String? ?? '') +
                  (delta['partial_json'] as String? ?? '');
          }
        case 'message_delta':
          final delta = d['delta'] as Map<String, dynamic>?;
          stopReason = delta?['stop_reason'] as String? ?? stopReason;
          final u = d['usage'] as Map<String, dynamic>?;
          output = (u?['output_tokens'] as int?) ?? output;
          input = (u?['input_tokens'] as int?) ?? input;
        case 'message_stop':
          final ordered = (blocks.keys.toList()..sort()).map((i) {
            final b = blocks[i]!;
            final partial = b.remove('_partial_json');
            if (partial is String && partial.isNotEmpty) {
              try {
                b['input'] = jsonDecode(partial);
              } on FormatException {
                // Entrée d'outil incomplète : conservée telle quelle.
              }
            }
            return b;
          }).toList();
          yield AiDone(
            message: AiMessage(role: 'assistant', content: ordered),
            usage: AiUsage(inputTokens: input, outputTokens: output),
            stopReason: stopReason,
            model: model,
          );
          return;
        case 'error':
          final err = d['error'] as Map<String, dynamic>? ?? const {};
          throw errorFromType(err['type'] as String?, err['message'] as String? ?? 'erreur');
      }
    }
    throw const AiException(AiErrorKind.network, 'Flux terminé avant la fin de la réponse.');
  }

  static AiException errorFromResponse(int status, String body, Map<String, String> headers) {
    String? type;
    var message = 'HTTP $status';
    try {
      final err = (jsonDecode(body) as Map<String, dynamic>)['error'] as Map<String, dynamic>;
      type = err['type'] as String?;
      message = err['message'] as String? ?? message;
    } catch (_) {}
    final retryAfter = int.tryParse(headers['retry-after'] ?? '');
    final kind = switch (status) {
      400 => AiErrorKind.invalidRequest,
      401 => AiErrorKind.authentication,
      402 => AiErrorKind.billing,
      403 => AiErrorKind.permission,
      404 => AiErrorKind.notFound,
      413 => AiErrorKind.tooLarge,
      429 => AiErrorKind.rateLimited,
      529 => AiErrorKind.overloaded,
      >= 500 => AiErrorKind.server,
      _ => errorFromType(type, message).kind,
    };
    return AiException(
      kind,
      _redactor.redact(message),
      statusCode: status,
      retryAfter: retryAfter == null ? null : Duration(seconds: retryAfter.clamp(1, 60)),
    );
  }

  static AiException errorFromType(String? type, String message) => AiException(
        switch (type) {
          'overloaded_error' => AiErrorKind.overloaded,
          'rate_limit_error' => AiErrorKind.rateLimited,
          'api_error' => AiErrorKind.server,
          'authentication_error' => AiErrorKind.authentication,
          'permission_error' => AiErrorKind.permission,
          'not_found_error' => AiErrorKind.notFound,
          'invalid_request_error' => AiErrorKind.invalidRequest,
          'request_too_large' => AiErrorKind.tooLarge,
          'billing_error' => AiErrorKind.billing,
          _ => AiErrorKind.unknown,
        },
        _redactor.redact(message),
      );

  /// Vrai si l'erreur signale des blocs de réflexion liés à un autre
  /// historique (récupération : retirer les blocs de réflexion, une fois).
  static bool isThinkingMismatch(AiException e) =>
      e.kind == AiErrorKind.invalidRequest &&
      RegExp('signature|thinking', caseSensitive: false).hasMatch(e.message);
}
