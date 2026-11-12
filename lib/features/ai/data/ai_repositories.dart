import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/db/database.dart';
import '../domain/ai_config.dart';
import '../domain/ai_models.dart';

class AiConfigRepository {
  AiConfigRepository(this._db);
  final AppDatabase _db;

  Future<AiConfig> load() async {
    final rows = await (_db.select(_db.appSettingsTable)..where((t) => t.key.like('ai.%'))).get();
    return AiConfig.fromMap({for (final r in rows) r.key: r.value});
  }

  Future<void> save(AiConfig c) => _db.transaction(() async {
        for (final e in c.toMap().entries) {
          await _db.into(_db.appSettingsTable).insertOnConflictUpdate(
                AppSettingsTableCompanion.insert(key: e.key, value: e.value),
              );
        }
      });
}

class ConversationRepository {
  ConversationRepository(this._db, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final AppDatabase _db;
  final DateTime Function() _clock;

  Future<int> create({
    required String title,
    required String systemPrompt,
    required AiProviderKind kind,
    required String model,
    required String level,
    String? moduleId,
    String? lessonId,
  }) {
    final now = _clock();
    return _db.into(_db.aiConversations).insert(AiConversationsCompanion.insert(
          title: title,
          systemPrompt: systemPrompt,
          providerKind: kind.code,
          model: model,
          level: level,
          moduleId: Value(moduleId),
          lessonId: Value(lessonId),
          createdAt: now,
          updatedAt: now,
        ));
  }

  Future<AiConversationRow?> conversation(int id) =>
      (_db.select(_db.aiConversations)..where((t) => t.id.equals(id))).getSingleOrNull();

  Stream<List<AiConversationRow>> watchConversations() => (_db.select(_db.aiConversations)
        ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
      .watch();

  Stream<List<AiMessageRow>> watchMessages(int conversationId) => (_db.select(_db.aiMessages)
        ..where((t) => t.conversationId.equals(conversationId))
        ..orderBy([(t) => OrderingTerm.asc(t.id)]))
      .watch();

  Future<List<AiMessage>> messages(int conversationId) async {
    final rows = await (_db.select(_db.aiMessages)
          ..where((t) => t.conversationId.equals(conversationId))
          ..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .get();
    return rows.map(toMessage).toList();
  }

  static AiMessage toMessage(AiMessageRow r) => AiMessage(
        role: r.role,
        content: (jsonDecode(r.contentJson) as List).cast<Map<String, dynamic>>(),
      );

  Future<int> add(int conversationId, AiMessage m, {AiUsage usage = const AiUsage(), String? model}) async {
    final id = await _db.into(_db.aiMessages).insert(AiMessagesCompanion.insert(
          conversationId: conversationId,
          role: m.role,
          contentJson: jsonEncode(m.content),
          inputTokens: Value(usage.inputTokens),
          outputTokens: Value(usage.outputTokens),
          model: Value(model),
          createdAt: _clock(),
        ));
    await (_db.update(_db.aiConversations)..where((t) => t.id.equals(conversationId)))
        .write(AiConversationsCompanion(updatedAt: Value(_clock())));
    return id;
  }

  Future<void> deleteMessage(int id) => (_db.delete(_db.aiMessages)..where((t) => t.id.equals(id))).go();

  Future<void> deleteConversation(int id) =>
      (_db.delete(_db.aiConversations)..where((t) => t.id.equals(id))).go();

  /// Récupération unique : retire les blocs de réflexion de tout l'historique.
  Future<void> stripThinking(int conversationId) async {
    final rows = await (_db.select(_db.aiMessages)
          ..where((t) => t.conversationId.equals(conversationId)))
        .get();
    for (final r in rows) {
      final blocks = (jsonDecode(r.contentJson) as List).cast<Map<String, dynamic>>();
      final kept = blocks
          .where((b) => b['type'] != 'thinking' && b['type'] != 'redacted_thinking')
          .toList();
      if (kept.length != blocks.length) {
        await (_db.update(_db.aiMessages)..where((t) => t.id.equals(r.id)))
            .write(AiMessagesCompanion(contentJson: Value(jsonEncode(kept))));
      }
    }
  }

  /// Jetons consommés depuis minuit (heure locale).
  Future<int> tokensToday() async {
    final now = _clock();
    final midnight = DateTime(now.year, now.month, now.day);
    final sum = _db.aiMessages.inputTokens.sum() + _db.aiMessages.outputTokens.sum();
    final q = _db.selectOnly(_db.aiMessages)
      ..addColumns([sum])
      ..where(_db.aiMessages.createdAt.isBiggerOrEqualValue(midnight));
    return (await q.map((r) => r.read(sum)).getSingle()) ?? 0;
  }
}
