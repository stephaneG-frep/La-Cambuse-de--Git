import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/theme.dart';
import '../../../app/theme/tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/state_views.dart';
import '../domain/catalog.dart';
import '../domain/course.dart';
import 'academy_providers.dart';

String _fold(String s) {
  const from = 'àâäéèêëîïôöùûüçœ';
  const to = 'aaaeeeeiioouuuco';
  final b = StringBuffer();
  for (final ch in s.toLowerCase().split('')) {
    final i = from.indexOf(ch);
    b.write(i >= 0 ? to[i] : ch);
  }
  return b.toString();
}

/// Recherche dans les leçons et le glossaire (ou glossaire seul).
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key, this.glossaryOnly = false});

  final bool glossaryOnly;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = CambuseTheme.of(context);
    final modules = [
      for (final i in islands.where((i) => i.isAvailable)) ref.watch(courseProvider(i.id)),
    ];
    if (modules.any((m) => m.isLoading)) return const LoadingView();
    final loaded = modules.map((m) => m.value).whereType<CourseModule>().toList();
    final q = _fold(_query.trim());

    final lessons = <(CourseModule, Lesson)>[
      if (!widget.glossaryOnly && q.isNotEmpty)
        for (final m in loaded)
          for (final lesson in m.lessons)
            if (_fold(lesson.searchText).contains(q)) (m, lesson),
    ];
    final terms = <GlossaryEntry>[
      for (final m in loaded)
        for (final g in m.glossary)
          if (q.isEmpty
              ? widget.glossaryOnly
              : _fold('${g.term} ${g.definition}').contains(q))
            g,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(title: widget.glossaryOnly ? l.glossaryTitle : l.academySearch),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: CambuseSpacing.md),
          child: TextField(
            autofocus: !widget.glossaryOnly,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              labelText: l.searchHint,
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        const SizedBox(height: CambuseSpacing.sm),
        Expanded(
          child: (q.isNotEmpty && lessons.isEmpty && terms.isEmpty)
              ? EmptyView(message: l.searchNoResult, icon: Icons.search_off)
              : ListView(
                  padding: const EdgeInsets.all(CambuseSpacing.md),
                  children: [
                    if (lessons.isNotEmpty) ...[
                      Text(l.searchLessons, style: Theme.of(context).textTheme.titleMedium),
                      for (final (m, lesson) in lessons)
                        ListTile(
                          leading: Icon(Icons.menu_book, color: p.copper),
                          title: Text(lesson.title),
                          subtitle: Text(m.title, style: TextStyle(color: p.textSecondary)),
                          onTap: () => context.go('/academie/${m.id}/lecon/${lesson.id}'),
                        ),
                      const SizedBox(height: CambuseSpacing.md),
                    ],
                    if (terms.isNotEmpty) ...[
                      if (!widget.glossaryOnly)
                        Text(l.searchGlossary, style: Theme.of(context).textTheme.titleMedium),
                      for (final g in terms)
                        Card(
                          margin: const EdgeInsets.only(bottom: CambuseSpacing.sm),
                          child: ListTile(
                            title: Text(g.term,
                                style: TextStyle(color: p.gold, fontWeight: FontWeight.w700)),
                            subtitle: Text(g.definition),
                          ),
                        ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}
