import 'package:flutter/material.dart';

/// Une île de la carte des compétences = un module du parcours (SPEC §5).
class Island {
  const Island({
    required this.id,
    required this.title,
    required this.icon,
    required this.prerequisites,
    this.availablePhase,
  });

  final String id;
  final String title;
  final IconData icon;
  final List<String> prerequisites;

  /// null = disponible ; sinon phase de la feuille de route qui le livrera.
  final int? availablePhase;

  bool get isAvailable => availablePhase == null;
}

/// Ordre du parcours de zéro à expert. Git (phase 2), Docker et Compose
/// (phase 7) sont livrés ; les autres sont affichés honnêtement « en brume ».
const islands = <Island>[
  Island(id: 'linux', title: 'Terminal Linux', icon: Icons.terminal, prerequisites: [], availablePhase: 9),
  Island(id: 'git', title: 'Git', icon: Icons.account_tree, prerequisites: []),
  Island(id: 'github', title: 'GitHub', icon: Icons.hub, prerequisites: ['git'], availablePhase: 6),
  Island(id: 'gitlab', title: 'GitLab', icon: Icons.merge_type, prerequisites: ['git'], availablePhase: 6),
  Island(id: 'docker', title: 'Docker', icon: Icons.inventory_2, prerequisites: ['git']),
  Island(id: 'compose', title: 'Docker Compose', icon: Icons.layers, prerequisites: ['docker']),
  Island(id: 'devops', title: 'DevOps et CI/CD', icon: Icons.all_inclusive, prerequisites: ['git', 'docker'], availablePhase: 8),
  Island(id: 'reseaux', title: 'Réseaux, serveurs, cloud', icon: Icons.lan, prerequisites: ['linux'], availablePhase: 9),
  Island(id: 'kubernetes', title: 'Kubernetes', icon: Icons.sailing, prerequisites: ['compose', 'reseaux'], availablePhase: 9),
  Island(id: 'iac', title: 'Terraform, Ansible, SRE', icon: Icons.precision_manufacturing, prerequisites: ['kubernetes'], availablePhase: 9),
];

Island islandById(String id) => islands.firstWhere((i) => i.id == id);
