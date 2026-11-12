import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/ai_models.dart';
import 'anthropic_provider.dart';
import 'sse_decoder.dart';

/// Adaptateur « compatible OpenAI » (Chat Completions en flux) : OpenAI,
/// Mistral, Groq, OpenRouter, Ollama (`http://hôte:11434/v1`)…
///
/// Testé uniquement contre un serveur simulé dans cette phase.
class OpenAiCompatibleProvider implements AiProvider {
  OpenAiCompatibleProvider({
    required this._apiKey,
    required this.baseUrl,
    http.Client? client,
  })  : _client = client ?? http.Client();

  final Future<String?> Function() _apiKey;
  final String baseUrl;
  final http.Client _client;

  String get _base => baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;

  Future<Map<String, String>> _headers() async {
    final key = (await _apiKey())?.trim();
    return {
      'content-type': 'application/json',
      // Ollama local n'exige pas de clé.
      if (key != null && key.isNotEmpty) 'authorization': 'Bearer $key',
    };
  }

  static Map<String, dynamic> buildBody(AiRequest r) => {
        'model': r.model,
        'stream': true,
        'max_tokens': r.maxTokens,
        'stream_options': {'include_usage': true},
        'messages': [
          {'role': 'system', 'content': r.system},
          for (final m in r.messages) {'role': m.role, 'content': m.text},
        ],
      };

  @override
  Future<void> checkConnection(String model) async {
    try {
      final res = await _client
          .get(Uri.parse('$_base/models'), headers: await _headers())
          .timeout(const Duration(seconds: 20));
      if (res.statusCode != 200) {
        throw AnthropicProvider.errorFromResponse(res.statusCode, res.body, res.headers);
      }
    } on TimeoutException {
      throw const AiException(AiErrorKind.timeout, 'Délai dépassé.');
    } on http.ClientException catch (e) {
      throw AiException(AiErrorKind.network, 'Réseau indisponible : ${e.message}');
    }
  }

  @override
  Stream<AiEvent> stream(AiRequest request) async* {
    final req = http.Request('POST', Uri.parse('$_base/chat/completions'))
      ..headers.addAll(await _headers())
      ..body = jsonEncode(buildBody(request));
    final http.StreamedResponse res;
    try {
      res = await _client.send(req).timeout(const Duration(seconds: 60));
    } on TimeoutException {
      throw const AiException(AiErrorKind.timeout, 'Pas de réponse après 60 s.');
    } on http.ClientException catch (e) {
      throw AiException(AiErrorKind.network, 'Réseau indisponible : ${e.message}');
    }
    if (res.statusCode != 200) {
      throw AnthropicProvider.errorFromResponse(
          res.statusCode, await res.stream.bytesToString(), res.headers);
    }
    final text = StringBuffer();
    var usage = const AiUsage();
    String? finish;
    var model = request.model;
    await for (final e in decodeSse(res.stream)) {
      if (e.data == '[DONE]') break;
      final Map<String, dynamic> d;
      try {
        d = jsonDecode(e.data) as Map<String, dynamic>;
      } on FormatException {
        continue;
      }
      model = d['model'] as String? ?? model;
      final u = d['usage'] as Map<String, dynamic>?;
      if (u != null) {
        usage = AiUsage(
          inputTokens: (u['prompt_tokens'] as int?) ?? 0,
          outputTokens: (u['completion_tokens'] as int?) ?? 0,
        );
      }
      for (final c in (d['choices'] as List? ?? const [])) {
        final choice = c as Map<String, dynamic>;
        final delta = choice['delta'] as Map<String, dynamic>?;
        final t = delta?['content'] as String?;
        if (t != null && t.isNotEmpty) {
          text.write(t);
          yield AiTextDelta(t);
        }
        finish = choice['finish_reason'] as String? ?? finish;
      }
    }
    yield AiDone(
      message: AiMessage(role: 'assistant', content: [
        {'type': 'text', 'text': text.toString()},
      ]),
      usage: usage,
      stopReason: finish,
      model: model,
    );
  }
}
