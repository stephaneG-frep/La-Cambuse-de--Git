import 'package:flutter/foundation.dart';

import 'ai_models.dart';

/// Modèle proposé dans les paramètres, avec ses tarifs publics (USD / million
/// de jetons, relevés le 2026-11-03) pour l'estimation des coûts.
@immutable
class ModelOption {
  const ModelOption(this.id, this.label, this.inputPerMillion, this.outputPerMillion);

  final String id;
  final String label;
  final double inputPerMillion;
  final double outputPerMillion;
}

const anthropicModels = <ModelOption>[
  ModelOption('claude-opus-5-5', 'Claude Opus 5.5 (par défaut)', 4.00, 20.00),
  ModelOption('claude-sonnet-5-5', 'Claude Sonnet 5.5', 2.00, 10.00),
  ModelOption('claude-haiku-5-5', 'Claude Haiku 5.5', 0.10, 0.50),
];

const efforts = ['low', 'medium', 'high'];

@immutable
class AiConfig {
  const AiConfig({
    this.kind = AiProviderKind.anthropic,
    this.model = 'claude-opus-5-5',
    this.baseUrl = '',
    this.effort = 'medium',
    this.dailyTokenBudget = 200000,
  });

  static const defaults = AiConfig();

  final AiProviderKind kind;
  final String model;

  /// Pour les fournisseurs compatibles OpenAI uniquement.
  final String baseUrl;
  final String effort;

  /// Plafond quotidien (entrée + sortie). 0 = illimité.
  final int dailyTokenBudget;

  AiConfig copyWith({
    AiProviderKind? kind,
    String? model,
    String? baseUrl,
    String? effort,
    int? dailyTokenBudget,
  }) =>
      AiConfig(
        kind: kind ?? this.kind,
        model: model ?? this.model,
        baseUrl: baseUrl ?? this.baseUrl,
        effort: effort ?? this.effort,
        dailyTokenBudget: dailyTokenBudget ?? this.dailyTokenBudget,
      );

  Map<String, String> toMap() => {
        'ai.kind': kind.code,
        'ai.model': model,
        'ai.base_url': baseUrl,
        'ai.effort': effort,
        'ai.daily_budget': '$dailyTokenBudget',
      };

  factory AiConfig.fromMap(Map<String, String> m) => AiConfig(
        kind: AiProviderKind.fromCode(m['ai.kind']),
        model: (m['ai.model'] ?? '').trim().isEmpty ? defaults.model : m['ai.model']!.trim(),
        baseUrl: m['ai.base_url'] ?? '',
        effort: efforts.contains(m['ai.effort']) ? m['ai.effort']! : defaults.effort,
        dailyTokenBudget:
            (int.tryParse(m['ai.daily_budget'] ?? '') ?? defaults.dailyTokenBudget).clamp(0, 100000000),
      );

  /// Coût estimé en USD, ou null si le modèle n'a pas de tarif connu.
  static double? estimateCost(String model, AiUsage usage) {
    final o = anthropicModels.where((m) => m.id == model).firstOrNull;
    if (o == null) return null;
    return usage.inputTokens / 1e6 * o.inputPerMillion +
        usage.outputTokens / 1e6 * o.outputPerMillion;
  }

  @override
  bool operator ==(Object other) =>
      other is AiConfig &&
      other.kind == kind &&
      other.model == model &&
      other.baseUrl == baseUrl &&
      other.effort == effort &&
      other.dailyTokenBudget == dailyTokenBudget;

  @override
  int get hashCode => Object.hash(kind, model, baseUrl, effort, dailyTokenBudget);
}
