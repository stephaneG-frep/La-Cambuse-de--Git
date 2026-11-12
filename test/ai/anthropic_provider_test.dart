import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:la_cambuse/features/ai/data/anthropic_provider.dart';
import 'package:la_cambuse/features/ai/data/sse_decoder.dart';
import 'package:la_cambuse/features/ai/domain/ai_models.dart';

const fakeKey = 'sk-ant-test-0000000000000000000000';

String sse(List<Map<String, dynamic>> events) =>
    events.map((e) => 'event: ${e['type']}\ndata: ${jsonEncode(e)}\n\n').join();

final okStream = sse([
  {'type': 'message_start', 'message': {'id': 'msg_1', 'model': 'claude-opus-5-5', 'usage': {'input_tokens': 42, 'output_tokens': 1}}},
  {'type': 'ping'},
  {'type': 'content_block_start', 'index': 0, 'content_block': {'type': 'thinking', 'thinking': ''}},
  {'type': 'content_block_delta', 'index': 0, 'delta': {'type': 'thinking_delta', 'thinking': ''}},
  {'type': 'content_block_delta', 'index': 0, 'delta': {'type': 'signature_delta', 'signature': 'SIG123'}},
  {'type': 'content_block_stop', 'index': 0},
  {'type': 'content_block_start', 'index': 1, 'content_block': {'type': 'text', 'text': ''}},
  {'type': 'content_block_delta', 'index': 1, 'delta': {'type': 'text_delta', 'text': 'Ahoy, '}},
  {'type': 'content_block_delta', 'index': 1, 'delta': {'type': 'text_delta', 'text': 'moussaillon !'}},
  {'type': 'content_block_stop', 'index': 1},
  {'type': 'message_delta', 'delta': {'stop_reason': 'end_turn'}, 'usage': {'output_tokens': 17}},
  {'type': 'message_stop'},
]);

/// Client simulé : renvoie les réponses dans l'ordre et capture les requêtes.
MockClient fake(List<(int, String, Map<String, String>)> responses, List<http.BaseRequest> seen,
    {List<String>? bodies}) {
  var i = 0;
  return MockClient.streaming((req, body) async {
    seen.add(req);
    bodies?.add(await body.bytesToString());
    final (status, text, headers) = responses[i++ < responses.length ? i - 1 : responses.length - 1];
    // Découpe volontaire en petits paquets pour éprouver le décodeur SSE.
    final bytes = utf8.encode(text);
    final chunks = [for (var o = 0; o < bytes.length; o += 7) bytes.sublist(o, (o + 7).clamp(0, bytes.length))];
    return http.StreamedResponse(Stream.fromIterable(chunks), status, headers: headers);
  });
}

AiRequest req({String model = 'claude-opus-5-5'}) => AiRequest(
      model: model,
      system: 'Tu es le Capitaine Commit.',
      messages: [AiMessage.userText('Bonjour')],
      effort: 'medium',
    );

void main() {
  test('décodeur SSE : paquets coupés, commentaires, événements multiples', () async {
    final raw = ': ping\nevent: a\ndata: {"x":1}\n\nevent: b\ndata: {"y":\ndata: 2}\n\n';
    final bytes = utf8.encode(raw);
    final events = await decodeSse(Stream.fromIterable([for (final b in bytes) [b]])).toList();
    expect(events.map((e) => e.event), ['a', 'b']);
    expect(events.last.data, '{"y":\n2}');
  });

  test('corps et en-têtes conformes ; repli serveur sur Opus 5.5', () async {
    final seen = <http.BaseRequest>[];
    final bodies = <String>[];
    final p = AnthropicProvider(apiKey: () async => fakeKey, client: fake([(200, okStream, {})], seen, bodies: bodies));
    await p.stream(req()).toList();
    final h = seen.single.headers;
    expect(seen.single.url.toString(), 'https://api.anthropic.com/v1/messages');
    expect(h['x-api-key'], fakeKey);
    expect(h['anthropic-version'], '2026-10-21');
    expect(h['anthropic-beta'], 'server-side-fallback-2026-07-01');
    final body = jsonDecode(bodies.single) as Map<String, dynamic>;
    expect(body['model'], 'claude-opus-5-5');
    expect(body['stream'], isTrue);
    expect(body['fallbacks'], 'default');
    expect(body['output_config'], {'effort': 'medium'});
    expect(body.containsKey('thinking'), isFalse, reason: 'réflexion toujours active sur Opus 5.5 : pas de paramètre');
    expect(body.containsKey('temperature'), isFalse);
  });

  test('pas de repli serveur pour Haiku 5.5', () {
    final body = AnthropicProvider.buildBody(req(model: 'claude-haiku-5-5'));
    expect(body.containsKey('fallbacks'), isFalse);
  });

  test('flux : deltas de texte, réflexion signée conservée, usage final', () async {
    final p = AnthropicProvider(apiKey: () async => fakeKey, client: fake([(200, okStream, {})], []));
    final events = await p.stream(req()).toList();
    expect(events.whereType<AiThinking>(), hasLength(1));
    expect(events.whereType<AiTextDelta>().map((e) => e.text).join(), 'Ahoy, moussaillon !');
    final done = events.last as AiDone;
    expect(done.stopReason, 'end_turn');
    expect(done.usage.inputTokens, 42);
    expect(done.usage.outputTokens, 17);
    expect(done.message.content.first, {'type': 'thinking', 'thinking': '', 'signature': 'SIG123'});
    expect(done.message.text, 'Ahoy, moussaillon !');
  });

  test('529 puis succès : nouvelle tentative avec attente', () async {
    final seen = <http.BaseRequest>[];
    final waits = <Duration>[];
    final p = AnthropicProvider(
      apiKey: () async => fakeKey,
      client: fake([
        (529, '{"type":"error","error":{"type":"overloaded_error","message":"Overloaded"}}', {}),
        (200, okStream, {}),
      ], seen),
      sleep: (d) async => waits.add(d),
    );
    final events = await p.stream(req()).toList();
    expect(seen, hasLength(2));
    expect(waits, [const Duration(seconds: 1)]);
    expect(events.last, isA<AiDone>());
  });

  test('429 : respecte retry-after puis abandonne après 2 nouvelles tentatives', () async {
    final seen = <http.BaseRequest>[];
    final waits = <Duration>[];
    final p = AnthropicProvider(
      apiKey: () async => fakeKey,
      client: fake([(429, '{"type":"error","error":{"type":"rate_limit_error","message":"slow down"}}', {'retry-after': '3'})], seen),
      sleep: (d) async => waits.add(d),
    );
    await expectLater(p.stream(req()).toList(),
        throwsA(isA<AiException>().having((e) => e.kind, 'kind', AiErrorKind.rateLimited)));
    expect(seen, hasLength(3));
    expect(waits, [const Duration(seconds: 3), const Duration(seconds: 3)]);
  });

  test('401 : erreur non réessayée, message expurgé de toute clé', () async {
    final seen = <http.BaseRequest>[];
    final p = AnthropicProvider(
      apiKey: () async => fakeKey,
      client: fake([(401, '{"type":"error","error":{"type":"authentication_error","message":"invalid x-api-key $fakeKey"}}', {})], seen),
    );
    try {
      await p.stream(req()).toList();
      fail('exception attendue');
    } on AiException catch (e) {
      expect(e.kind, AiErrorKind.authentication);
      expect(e.message, isNot(contains(fakeKey)));
      expect(seen, hasLength(1));
    }
  });

  test('sans clé : erreur explicite, aucun appel réseau', () async {
    final seen = <http.BaseRequest>[];
    final p = AnthropicProvider(apiKey: () async => null, client: fake([(200, okStream, {})], seen));
    await expectLater(p.stream(req()).toList(),
        throwsA(isA<AiException>().having((e) => e.kind, 'kind', AiErrorKind.noKey)));
    expect(seen, isEmpty);
  });

  test('erreur au milieu du flux (événement error)', () async {
    final s = sse([
      {'type': 'message_start', 'message': {'model': 'claude-opus-5-5', 'usage': {'input_tokens': 1}}},
      {'type': 'error', 'error': {'type': 'overloaded_error', 'message': 'Overloaded'}},
    ]);
    final p = AnthropicProvider(apiKey: () async => fakeKey, client: fake([(200, s, {})], []));
    await expectLater(p.stream(req()).toList(),
        throwsA(isA<AiException>().having((e) => e.kind, 'kind', AiErrorKind.overloaded)));
  });

  test('flux tronqué : erreur réseau', () async {
    final s = sse([
      {'type': 'message_start', 'message': {'model': 'claude-opus-5-5', 'usage': {'input_tokens': 1}}},
    ]);
    final p = AnthropicProvider(apiKey: () async => fakeKey, client: fake([(200, s, {})], []));
    await expectLater(p.stream(req()).toList(), throwsA(isA<AiException>()));
  });

  test('refus : stop_reason transmis', () async {
    final s = sse([
      {'type': 'message_start', 'message': {'model': 'claude-opus-5-5', 'usage': {'input_tokens': 5}}},
      {'type': 'message_delta', 'delta': {'stop_reason': 'refusal'}, 'usage': {'output_tokens': 0}},
      {'type': 'message_stop'},
    ]);
    final p = AnthropicProvider(apiKey: () async => fakeKey, client: fake([(200, s, {})], []));
    final done = (await p.stream(req()).toList()).last as AiDone;
    expect(done.stopReason, 'refusal');
  });

  test('test de connexion : GET /v1/models/{id}, 404 = modèle indisponible', () async {
    final seen = <http.BaseRequest>[];
    var p = AnthropicProvider(apiKey: () async => fakeKey, client: fake([(200, '{"id":"claude-opus-5-5"}', {})], seen));
    await p.checkConnection('claude-opus-5-5');
    expect(seen.single.method, 'GET');
    expect(seen.single.url.path, '/v1/models/claude-opus-5-5');
    p = AnthropicProvider(apiKey: () async => fakeKey,
        client: fake([(404, '{"type":"error","error":{"type":"not_found_error","message":"model: x"}}', {})], []));
    await expectLater(p.checkConnection('x'),
        throwsA(isA<AiException>().having((e) => e.kind, 'kind', AiErrorKind.notFound)));
  });

  test('détection du besoin de retirer les blocs de réflexion', () {
    expect(AnthropicProvider.isThinkingMismatch(const AiException(AiErrorKind.invalidRequest,
        'messages.5.content.0: Invalid `signature` in `thinking` block.')), isTrue);
    expect(AnthropicProvider.isThinkingMismatch(
        const AiException(AiErrorKind.invalidRequest, 'max_tokens too large')), isFalse);
  });
}
