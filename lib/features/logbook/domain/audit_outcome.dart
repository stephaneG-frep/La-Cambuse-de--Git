/// Résultat d'une action consignée au journal de bord.
enum AuditOutcome {
  success('success'),
  failure('failure'),
  cancelled('cancelled'),
  info('info');

  const AuditOutcome(this.code);

  final String code;

  static AuditOutcome fromCode(String code) =>
      values.firstWhere((o) => o.code == code, orElse: () => AuditOutcome.info);
}
