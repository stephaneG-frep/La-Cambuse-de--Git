
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:la_cambuse/features/ai/data/secret_store.dart';
import 'package:la_cambuse/features/ai/domain/ai_models.dart';
import 'package:la_cambuse/features/ai/presentation/ai_providers.dart';

import '../ai/chat_service_test.dart' show FakeProvider, reply;
import 'academy_test.dart' show module, openAcademy, tapVisible;
import 'widget_helpers.dart';

const key = 'sk-ant-widget-test-123456789';

void main() {
  testWidgets('sans clé : professeur annoncé non configuré, application utilisable', (tester) async {
    final db = await pumpApp(tester, size: phone);
    await openAcademy(tester);
    await tapVisible(tester, find.text('Professeur IA'));
    await tapVisible(tester, find.text('Nouvelle conversation'));
    expect(find.text('Professeur IA non configuré'), findsOneWidget);
    expect(find.textContaining('fonctionne sans IA'), findsOneWidget);
    await teardown(tester, db);
  });

  testWidgets('paramètres : clé dans le coffre (jamais en base), test de connexion', (tester) async {
    final secrets = MemorySecretStore();
    final fake = FakeProvider([]);
    final db = await pumpApp(tester, size: desktop, secrets: secrets,
        overrides: [aiProviderFactoryProvider.overrideWithValue((_) => fake)]);
    await tester.tap(find.byTooltip('Paramètres'));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Professeur IA'));
    expect(find.text('Aucune clé enregistrée'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Clé API'), key);
    await tapVisible(tester, find.text('Enregistrer la clé'));
    expect(secrets.values['ai.api_key.anthropic'], key);
    expect(find.textContaining('sk-ant…6789'), findsOneWidget);
    expect(find.text(key), findsNothing, reason: 'la clé complète n\'est jamais réaffichée');
    // Laisse disparaître la notification flottante qui recouvre les boutons.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Tester la connexion'));
    expect(find.text('Connexion réussie : claude-opus-5-5 est disponible.'), findsOneWidget);
    await tapVisible(tester, find.text('Enregistrer'));
    final rows = await dbRead(tester, () => db.select(db.appSettingsTable).get());
    expect(rows.map((r) => r.value).join(), isNot(contains(key)));
    expect(rows.firstWhere((r) => r.key == 'ai.model').value, 'claude-opus-5-5');
    await teardown(tester, db);
  });

  testWidgets('chat depuis une leçon : réponse en flux, coût estimé, contexte de leçon', (tester) async {
    final secrets = MemorySecretStore()..values['ai.api_key.anthropic'] = key;
    final fake = FakeProvider([(_) => reply('Un commit est un instantané. ```\ngit commit -m "msg"\n```', inTok: 1200, outTok: 300)]);
    final db = await pumpApp(tester, size: desktop, secrets: secrets,
        overrides: [aiProviderFactoryProvider.overrideWithValue((_) => fake)]);
    await openAcademy(tester);
    await tapVisible(tester, find.text('Git'));
    final lesson = module.lessons.first;
    await tapVisible(tester, find.text(lesson.title));
    await tapVisible(tester, find.byTooltip('Demander au professeur'));
    expect(find.text('Contexte : ${lesson.title}', findRichText: true), findsNothing);
    expect(find.textContaining('Contexte : ${lesson.title}'), findsOneWidget);
    await tapVisible(tester, find.text('Expert'));
    await tester.enterText(find.widgetWithText(TextField, 'Votre question au Capitaine Commit'), 'C\'est quoi un commit ?');
    await tester.pump();
    await tapVisible(tester, find.byTooltip('Envoyer'));
    expect(find.textContaining('Un commit est un instantané.'), findsOneWidget);
    expect(find.text('git commit -m "msg"'), findsOneWidget, reason: 'bloc de code rendu');
    expect(find.textContaining('1500 jetons · claude-opus-5-5'), findsOneWidget);
    expect(find.textContaining('≈ 0.0108 \$'), findsOneWidget);
    final sys = fake.requests.single.system;
    expect(sys, contains('<lesson_content>'));
    expect(sys, contains(lesson.title));
    expect(sys, contains('expert'));
    final conv = await dbRead(tester, () => db.select(db.aiConversations).getSingle());
    expect(conv.lessonId, lesson.id);
    await teardown(tester, db);
  });

  testWidgets('hors ligne : message concret, question conservée dans le champ', (tester) async {
    final secrets = MemorySecretStore()..values['ai.api_key.anthropic'] = key;
    final fake = FakeProvider([(_) => Stream.error(const AiException(AiErrorKind.network, 'x'))]);
    final db = await pumpApp(tester, size: phone, secrets: secrets,
        overrides: [aiProviderFactoryProvider.overrideWithValue((_) => fake)]);
    await openAcademy(tester);
    await tapVisible(tester, find.text('Professeur IA'));
    await tapVisible(tester, find.text('Nouvelle conversation'));
    await tester.enterText(find.widgetWithText(TextField, 'Votre question au Capitaine Commit'), 'Question perdue ?');
    await tester.pump();
    await tapVisible(tester, find.byTooltip('Envoyer'));
    expect(find.textContaining('le professeur IA nécessite Internet'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Question perdue ?'), findsOneWidget);
    await teardown(tester, db);
  });

  testWidgets('accessibilité du chat (téléphone)', (tester) async {
    final handle = tester.ensureSemantics();
    final secrets = MemorySecretStore()..values['ai.api_key.anthropic'] = key;
    final db = await pumpApp(tester, size: phone, secrets: secrets,
        overrides: [aiProviderFactoryProvider.overrideWithValue((_) => FakeProvider([]))]);
    await openAcademy(tester);
    await tapVisible(tester, find.text('Professeur IA'));
    await tapVisible(tester, find.text('Nouvelle conversation'));
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    handle.dispose();
    await teardown(tester, db);
  });
}
