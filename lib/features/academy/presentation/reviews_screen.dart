import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/state_views.dart';
import '../domain/catalog.dart';
import '../domain/course.dart';
import 'academy_providers.dart';
import 'widgets/quiz_view.dart';

/// Révisions espacées : questions dont l'échéance Leitner est atteinte.
class ReviewsScreen extends ConsumerStatefulWidget {
  const ReviewsScreen({super.key});

  @override
  ConsumerState<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends ConsumerState<ReviewsScreen> {
  /// Figée à l'ouverture : la session ne change pas pendant qu'on répond.
  List<(String, QuizQuestion)>? _session;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final due = ref.watch(dueCardsProvider);
    final modules = {
      for (final i in islands.where((i) => i.isAvailable))
        i.id: ref.watch(courseProvider(i.id)).value,
    };

    Widget body;
    if (due.isLoading || modules.values.any((m) => m == null)) {
      body = const LoadingView();
    } else if (due.hasError) {
      body = ErrorView(error: due.error!);
    } else {
      _session ??= [
        for (final c in due.value!)
          if (modules[c.moduleId]?.question(c.questionId) case final q?) (c.moduleId, q),
      ];
      final session = _session!;
      body = session.isEmpty
          ? EmptyView(message: l.reviewsEmpty, icon: Icons.event_available)
          : QuizView(
              questions: [for (final (_, q) in session) q],
              showScore: true,
              onFinished: (answers) async {
                final repo = ref.read(progressRepositoryProvider);
                for (final (moduleId, q) in session) {
                  final ok = answers[q.id];
                  if (ok != null) await repo.recordReview(q.id, moduleId, ok);
                }
              },
            );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(title: l.reviewsTitle, subtitle: l.reviewsDue(due.value?.length ?? 0)),
        Expanded(child: body),
      ],
    );
  }
}
