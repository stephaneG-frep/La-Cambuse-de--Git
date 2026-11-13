import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../features/academy/presentation/academy_screen.dart';
import '../features/academy/presentation/lesson_screen.dart';
import '../features/academy/presentation/module_screen.dart';
import '../features/academy/presentation/project_screen.dart';
import '../features/academy/presentation/reviews_screen.dart';
import '../features/academy/presentation/search_screen.dart';
import '../features/ai/presentation/ai_settings_screen.dart';
import '../features/ai/presentation/chat_screen.dart';
import '../features/captain/presentation/captain_screen.dart';
import '../features/companion_link/presentation/companion_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/forge/presentation/forge_settings_screen.dart';
import '../features/logbook/presentation/logbook_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/workshop/presentation/project_screen.dart' as workshop;
import '../features/workshop/presentation/workshop_screen.dart';
import 'shell/adaptive_shell.dart';

abstract final class Routes {
  static const bridge = '/pont';
  static const academy = '/academie';
  static const workshop = '/atelier';
  static const captain = '/capitaine';
  static const logbook = '/journal';
  static const settings = '/parametres';
}

GoRouter buildRouter() => GoRouter(
      initialLocation: Routes.bridge,
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) => AdaptiveShell(navigationShell: shell),
          branches: [
            _branch(Routes.bridge, const DashboardScreen()),
            StatefulShellBranch(routes: [
              GoRoute(
                path: Routes.academy,
                builder: (context, state) => const AcademyScreen(),
                routes: [
                  GoRoute(path: 'revisions', builder: (c, s) => const ReviewsScreen()),
                  GoRoute(
                      path: 'glossaire',
                      builder: (c, s) => const SearchScreen(glossaryOnly: true)),
                  GoRoute(path: 'recherche', builder: (c, s) => const SearchScreen()),
                  GoRoute(
                    path: 'professeur',
                    builder: (c, s) => const TeacherHomeScreen(),
                    routes: [
                      GoRoute(
                        path: 'nouvelle',
                        builder: (c, s) => ChatScreen(
                          moduleId: s.uri.queryParameters['module'],
                          lessonId: s.uri.queryParameters['lecon'],
                        ),
                      ),
                      GoRoute(
                        path: ':conversationId',
                        builder: (c, s) => ChatScreen(
                          conversationId: int.tryParse(s.pathParameters['conversationId']!),
                        ),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: ':moduleId',
                    builder: (c, s) => ModuleScreen(moduleId: s.pathParameters['moduleId']!),
                    routes: [
                      GoRoute(
                        path: 'lecon/:lessonId',
                        builder: (c, s) => LessonScreen(
                          moduleId: s.pathParameters['moduleId']!,
                          lessonId: s.pathParameters['lessonId']!,
                        ),
                      ),
                      GoRoute(
                        path: 'projet',
                        builder: (c, s) => ProjectScreen(moduleId: s.pathParameters['moduleId']!),
                      ),
                    ],
                  ),
                ],
              ),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                path: Routes.workshop,
                builder: (context, state) => const WorkshopScreen(),
                routes: [
                  GoRoute(
                    path: 'projet',
                    builder: (c, s) => workshop.WorkshopProjectScreen(path: s.uri.queryParameters['chemin'] ?? ''),
                  ),
                ],
              ),
            ]),
            _branch(Routes.captain, const CaptainScreen()),
            _branch(Routes.logbook, const LogbookScreen()),
          ],
        ),
        GoRoute(
          path: Routes.settings,
          builder: (context, state) => const SettingsScreen(),
          routes: [
            GoRoute(path: 'ia', builder: (c, s) => const AiSettingsScreen()),
            GoRoute(path: 'compagnon', builder: (c, s) => const CompanionScreen()),
            GoRoute(path: 'forges', builder: (c, s) => const ForgeSettingsScreen()),
          ],
        ),
      ],
    );

StatefulShellBranch _branch(String path, Widget screen) => StatefulShellBranch(
      routes: [GoRoute(path: path, builder: (context, state) => screen)],
    );
