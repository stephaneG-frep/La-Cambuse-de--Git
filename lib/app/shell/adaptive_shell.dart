import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../theme/tokens.dart';

class _Destination {
  const _Destination(this.icon, this.selectedIcon, this.label);
  final IconData icon;
  final IconData selectedIcon;
  final String Function(AppLocalizations) label;
}

final _destinations = <_Destination>[
  _Destination(Icons.sailing_outlined, Icons.sailing, (l) => l.navBridge),
  _Destination(Icons.map_outlined, Icons.map, (l) => l.navAcademy),
  _Destination(
    Icons.construction_outlined,
    Icons.construction,
    (l) => l.navWorkshop,
  ),
  _Destination(Icons.explore_outlined, Icons.explore, (l) => l.navCaptain),
  _Destination(Icons.menu_book_outlined, Icons.menu_book, (l) => l.navLogbook),
];

/// Coque adaptative : barre inférieure sur téléphone, rail latéral sur bureau.
/// Raccourcis clavier : Ctrl+1…5 pour les sections, Ctrl+, pour les paramètres.
class AdaptiveShell extends StatelessWidget {
  const AdaptiveShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static int get destinationCount => _destinations.length;

  void _go(int index) => navigationShell.goBranch(
    index,
    initialLocation: index == navigationShell.currentIndex,
  );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final useRail = width >= CambuseBreakpoints.rail;
    final compact = MediaQuery.sizeOf(context).height < 520;

    final shortcuts = <ShortcutActivator, VoidCallback>{
      for (var i = 0; i < _destinations.length; i++)
        SingleActivator(
          LogicalKeyboardKey(LogicalKeyboardKey.digit1.keyId + i),
          control: true,
        ): () =>
            _go(i),
      const SingleActivator(LogicalKeyboardKey.comma, control: true): () =>
          context.push('/parametres'),
    };

    final settingsButton = IconButton(
      tooltip: l.navSettings,
      icon: const Icon(Icons.settings_outlined),
      onPressed: () => context.push('/parametres'),
    );

    final body = Scaffold(
      appBar: AppBar(
        title: Text(l.appTitle),
        actions: [
          settingsButton,
          const SizedBox(width: CambuseSpacing.sm),
        ],
      ),
      body: useRail
          ? Row(
              children: [
                // Téléphone en paysage : peu de hauteur. Le rail défile et
                // n'affiche que le libellé de la destination active.
                LayoutBuilder(
                  builder: (context, c) => SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: c.maxHeight),
                      child: IntrinsicHeight(
                        child: NavigationRail(
                          extended: width >= CambuseBreakpoints.extendedRail,
                          labelType: width >= CambuseBreakpoints.extendedRail
                              ? NavigationRailLabelType.none
                              : compact
                              ? NavigationRailLabelType.selected
                              : NavigationRailLabelType.all,
                          selectedIndex: navigationShell.currentIndex,
                          onDestinationSelected: _go,
                          destinations: [
                            for (final d in _destinations)
                              NavigationRailDestination(
                                icon: Icon(d.icon),
                                selectedIcon: Icon(d.selectedIcon),
                                label: Text(d.label(l)),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: navigationShell),
              ],
            )
          : navigationShell,
      bottomNavigationBar: useRail
          ? null
          : NavigationBar(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: _go,
              destinations: [
                for (final d in _destinations)
                  NavigationDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selectedIcon),
                    label: d.label(l),
                  ),
              ],
            ),
    );

    return CallbackShortcuts(
      bindings: shortcuts,
      child: Focus(autofocus: true, child: body),
    );
  }
}
