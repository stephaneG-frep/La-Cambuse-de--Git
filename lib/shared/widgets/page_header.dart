import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/theme.dart';
import '../../app/theme/tokens.dart';

/// En-tête de page imbriquée dans une section (retour + titre « plaque »).
class PageHeader extends StatelessWidget {
  const PageHeader({super.key, required this.title, this.subtitle, this.trailing, this.subtitleMaxLines});

  final String title;
  final String? subtitle;
  final Widget? trailing;

  /// Limite de lignes du sous-titre (points de suspension au-delà).
  final int? subtitleMaxLines;

  @override
  Widget build(BuildContext context) {
    final p = CambuseTheme.of(context);
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          CambuseSpacing.sm, CambuseSpacing.sm, CambuseSpacing.md, CambuseSpacing.sm),
      child: Row(
        children: [
          if (context.canPop()) const BackButton() else const SizedBox(width: CambuseSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(title, style: text.headlineSmall?.copyWith(color: p.gold)),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: TextStyle(color: p.textSecondary),
                    maxLines: subtitleMaxLines,
                    overflow: subtitleMaxLines == null ? null : TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
