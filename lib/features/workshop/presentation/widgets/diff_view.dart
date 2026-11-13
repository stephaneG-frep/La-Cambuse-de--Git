import 'package:flutter/material.dart';

import '../../../../app/theme/theme.dart';
import '../../../../app/theme/tokens.dart';
import '../../domain/git_parsing.dart';

/// Visualiseur de diff : ajouts en turquoise, retraits en rouge, numéros de
/// ligne, symboles +/− toujours visibles (pas seulement la couleur).
class DiffView extends StatelessWidget {
  const DiffView({super.key, required this.files, required this.emptyLabel});

  final List<FileDiff> files;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    final p = CambuseTheme.of(context);
    if (files.isEmpty) return Padding(padding: const EdgeInsets.all(CambuseSpacing.md), child: Text(emptyLabel));
    const mono = TextStyle(fontFamily: 'monospace', fontSize: 13, height: 1.35);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final f in files)
          Container(
            margin: const EdgeInsets.only(bottom: CambuseSpacing.sm),
            decoration: BoxDecoration(
              color: p.night,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: p.copper.withValues(alpha: 0.6)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Padding(
                padding: const EdgeInsets.all(CambuseSpacing.sm),
                child: Text('${f.path}   +${f.added} −${f.removed}',
                    style: mono.copyWith(color: p.gold, fontWeight: FontWeight.w700)),
              ),
              if (f.binary)
                Padding(
                  padding: const EdgeInsets.all(CambuseSpacing.sm),
                  child: Text('Fichier binaire', style: mono.copyWith(color: p.textSecondary)),
                ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final l in f.lines.where((l) => l.kind != DiffLineKind.header))
                      Container(
                        color: switch (l.kind) {
                          DiffLineKind.added => p.turquoise.withValues(alpha: 0.12),
                          DiffLineKind.removed => p.alert.withValues(alpha: 0.14),
                          DiffLineKind.hunk => p.surface,
                          _ => null,
                        },
                        padding: const EdgeInsets.symmetric(horizontal: CambuseSpacing.sm),
                        child: Text(
                          switch (l.kind) {
                            DiffLineKind.hunk => l.text,
                            _ => '${(l.oldNo?.toString() ?? '').padLeft(4)} ${(l.newNo?.toString() ?? '').padLeft(4)} '
                                '${l.kind == DiffLineKind.added ? '+' : l.kind == DiffLineKind.removed ? '−' : ' '} ${l.text}',
                          },
                          style: mono.copyWith(
                            color: switch (l.kind) {
                              DiffLineKind.added => p.turquoise,
                              DiffLineKind.removed => p.alert,
                              DiffLineKind.hunk => p.textSecondary,
                              _ => p.text,
                            },
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ]),
          ),
      ],
    );
  }
}
