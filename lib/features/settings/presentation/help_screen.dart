import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/theme.dart';
import '../../../app/theme/tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/state_views.dart';
import '../../ai/presentation/markdown_lite.dart';

/// Source unique : docs/GUIDE_UTILISATEUR.md, embarqué dans l'application.
final userGuideProvider = FutureProvider<String>((ref) => rootBundle.loadString('docs/GUIDE_UTILISATEUR.md'));

/// Découpe le guide en (titre, contenu) par section de niveau 2.
List<(String, String)> guideSections(String md) {
  final out = <(String, String)>[];
  for (final part in md.split(RegExp(r'^## ', multiLine: true)).skip(1)) {
    final nl = part.indexOf('\n');
    out.add((part.substring(0, nl < 0 ? part.length : nl).trim(), nl < 0 ? '' : part.substring(nl + 1).trim()));
  }
  return out;
}

/// Guide de bord : mode d'emploi hors ligne, une section repliable par chapitre.
class HelpScreen extends ConsumerWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final p = CambuseTheme.of(context);
    final guide = ref.watch(userGuideProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.helpTitle)),
      body: guide.when(
        loading: () => const LoadingView(),
        error: (e, _) => Center(child: Text('$e')),
        data: (md) {
          final sections = guideSections(md);
          return ListView(
            padding: const EdgeInsets.all(CambuseSpacing.md),
            children: [
              if (Localizations.localeOf(context).languageCode != 'fr')
                Padding(
                  padding: const EdgeInsets.only(bottom: CambuseSpacing.sm),
                  child: Text(l.helpFrenchOnly, style: TextStyle(color: p.textSecondary)),
                ),
              for (final (i, (title, body)) in sections.indexed)
                Card(
                  margin: const EdgeInsets.only(bottom: CambuseSpacing.sm),
                  clipBehavior: Clip.antiAlias,
                  child: ExpansionTile(
                    initiallyExpanded: i == 0,
                    title: Text(title, style: TextStyle(color: p.gold, fontWeight: FontWeight.w600)),
                    childrenPadding: const EdgeInsets.fromLTRB(CambuseSpacing.md, 0, CambuseSpacing.md, CambuseSpacing.md),
                    expandedCrossAxisAlignment: CrossAxisAlignment.start,
                    children: [MarkdownLiteView(text: body, selectable: false)],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
