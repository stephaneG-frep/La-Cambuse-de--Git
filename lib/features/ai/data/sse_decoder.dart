import 'dart:async';
import 'dart:convert';

/// Événement Server-Sent Events.
class SseEvent {
  const SseEvent(this.event, this.data);
  final String? event;
  final String data;
}

/// Décode un flux d'octets SSE (lignes `event:` / `data:`, séparées par une
/// ligne vide). Tolère les coupures de paquets au milieu d'une ligne.
Stream<SseEvent> decodeSse(Stream<List<int>> bytes) async* {
  String? event;
  final data = <String>[];
  await for (final line in bytes.transform(utf8.decoder).transform(const LineSplitter())) {
    if (line.isEmpty) {
      if (data.isNotEmpty) yield SseEvent(event, data.join('\n'));
      event = null;
      data.clear();
    } else if (line.startsWith(':')) {
      continue; // commentaire / ping
    } else if (line.startsWith('event:')) {
      event = line.substring(6).trim();
    } else if (line.startsWith('data:')) {
      data.add(line.substring(5).trimLeft());
    }
  }
  if (data.isNotEmpty) yield SseEvent(event, data.join('\n'));
}
