import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/theme.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/db/database.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/state_views.dart';
import '../../academy/presentation/academy_providers.dart';
import '../data/ai_repositories.dart';
import '../domain/ai_config.dart';
import '../domain/ai_models.dart';
import '../domain/teacher_prompt.dart';
import 'ai_providers.dart';
import 'markdown_lite.dart';

/// Liste des conversations avec le professeur IA.
class TeacherHomeScreen extends ConsumerWidget {
  const TeacherHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final p = CambuseTheme.of(context);
    final convs = ref.watch(conversationsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(title: l.aiTeacher),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: CambuseSpacing.md),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: () => context.go('/academie/professeur/nouvelle'),
              icon: const Icon(Icons.add_comment),
              label: Text(l.aiNewConversation),
            ),
          ),
        ),
        Expanded(
          child: convs.when(
            loading: () => const LoadingView(),
            error: (e, _) => ErrorView(error: e),
            data: (rows) => rows.isEmpty
                ? EmptyView(message: l.aiNoConversations, icon: Icons.forum_outlined)
                : ListView.separated(
                    padding: const EdgeInsets.all(CambuseSpacing.md),
                    itemCount: rows.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final c = rows[i];
                      return ListTile(
                        leading: Icon(Icons.smart_toy_outlined, color: p.copper),
                        title: Text(c.title),
                        subtitle: Text('${c.model} · ${c.level}', style: TextStyle(color: p.textSecondary)),
                        onTap: () => context.go('/academie/professeur/${c.id}'),
                        trailing: IconButton(
                          tooltip: l.aiDeleteConversation,
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text(l.aiDeleteConversation),
                                content: Text(l.aiDeleteConfirm),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
                                  FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.confirmDelete)),
                                ],
                              ),
                            );
                            if (ok == true) {
                              await ref.read(conversationRepositoryProvider).deleteConversation(c.id);
                            }
                          },
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

/// Conversation avec le Capitaine Commit. [conversationId] null = nouvelle
/// conversation, créée au premier envoi (avec le contexte de [lessonId]).
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, this.conversationId, this.moduleId, this.lessonId});

  final int? conversationId;
  final String? moduleId;
  final String? lessonId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  late int? _conversationId = widget.conversationId;
  final _input = TextEditingController();
  final _scroll = ScrollController();
  LearnerLevel _level = LearnerLevel.beginner;
  bool _busy = false;
  bool _thinking = false;
  String _pending = '';
  String? _pendingQuestion;
  String? _error;
  String? _notice;
  Completer<void>? _cancel;

  @override
  void dispose() {
    _cancel?.complete();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToEnd() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.animateTo(_scroll.position.maxScrollExtent,
              duration: const Duration(milliseconds: 150), curve: Curves.easeOut);
        }
      });

  Future<int> _ensureConversation(AiConfig config) async {
    if (_conversationId != null) return _conversationId!;
    final module = widget.moduleId == null ? null : await ref.read(courseProvider(widget.moduleId!).future);
    final lesson = widget.lessonId == null ? null : module?.lesson(widget.lessonId!);
    final first = _input.text.trim();
    final id = await ref.read(conversationRepositoryProvider).create(
          title: lesson?.title ?? (first.length > 50 ? '${first.substring(0, 50)}…' : first),
          systemPrompt: buildTeacherPrompt(level: _level, module: module, lesson: lesson),
          kind: config.kind,
          model: config.model,
          level: _level.code,
          moduleId: widget.moduleId,
          lessonId: widget.lessonId,
        );
    setState(() => _conversationId = id);
    return id;
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _busy) return;
    final l = AppLocalizations.of(context);
    final config = await ref.read(aiConfigProvider.future);
    final id = await _ensureConversation(config);
    final service = buildChatService(ref, config);
    _cancel = Completer<void>();
    setState(() {
      _busy = true;
      _thinking = false;
      _pending = '';
      _pendingQuestion = text;
      _error = null;
      _notice = null;
      _input.clear();
    });
    _scrollToEnd();
    try {
      final out = await service.send(id, text, cancel: _cancel, onEvent: (e) {
        if (!mounted) return;
        setState(() {
          if (e is AiThinking) _thinking = true;
          if (e is AiTextDelta) {
            _thinking = false;
            _pending += e.text;
          }
        });
        _scrollToEnd();
      });
      if (!mounted) return;
      if (out.secretMasked) setState(() => _notice = l.aiSecretMasked);
    } on AiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = describeAiError(l, e);
        _input.text = text; // rien n'est perdu
      });
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _thinking = false;
          _pending = '';
          _pendingQuestion = null;
        });
      }
      _cancel = null;
      if (mounted) ref.invalidate(tokensTodayProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = CambuseTheme.of(context);
    final config = ref.watch(aiConfigProvider).value;
    if (config == null) return const LoadingView();
    final keyHint = ref.watch(storedKeyHintProvider(config.kind));
    final needsKey = config.kind == AiProviderKind.anthropic;
    if (keyHint.isLoading) return const LoadingView();
    if (needsKey && keyHint.value == null) {
      return Column(children: [
        PageHeader(title: l.aiTeacher),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(CambuseSpacing.lg),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.key_off, size: 56, color: p.gold),
                const SizedBox(height: CambuseSpacing.md),
                Text(l.aiNoKeyTitle, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: CambuseSpacing.sm),
                Text(l.aiNoKeyBody, textAlign: TextAlign.center),
                const SizedBox(height: CambuseSpacing.lg),
                FilledButton.icon(
                  onPressed: () => context.push('/parametres/ia'),
                  icon: const Icon(Icons.settings),
                  label: Text(l.aiOpenSettings),
                ),
              ]),
            ),
          ),
        ),
      ]);
    }

    final rows = _conversationId == null
        ? const <AiMessageRow>[]
        : ref.watch(messagesProvider(_conversationId!)).value ?? const <AiMessageRow>[];
    final conv = _conversationId == null
        ? null
        : ref.watch(conversationsProvider).value?.where((c) => c.id == _conversationId).firstOrNull;
    // Contexte : celui demandé à l'ouverture, ou celui stocké avec la conversation.
    final moduleId = widget.moduleId ?? conv?.moduleId;
    final lessonId = widget.lessonId ?? conv?.lessonId;
    final lessonTitle = lessonId == null || moduleId == null
        ? null
        : ref.watch(courseProvider(moduleId)).value?.lesson(lessonId)?.title;
    final used = ref.watch(tokensTodayProvider).value;
    final model = conv?.model ?? config.model;
    final providerName = config.kind == AiProviderKind.anthropic ? 'Anthropic' : config.baseUrl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: conv?.title ?? l.aiTeacher,
          subtitle: [model, if (lessonTitle != null) l.aiContextLesson(lessonTitle)].join(' · '),
        ),
        if (_conversationId == null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: CambuseSpacing.md),
            child: Wrap(
              spacing: CambuseSpacing.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('${l.aiLevel} :'),
                for (final (lv, label) in [
                  (LearnerLevel.beginner, l.aiLevelBeginner),
                  (LearnerLevel.intermediate, l.aiLevelIntermediate),
                  (LearnerLevel.expert, l.aiLevelExpert),
                ])
                  ChoiceChip(
                    label: Text(label),
                    selected: _level == lv,
                    onSelected: (_) => setState(() => _level = lv),
                  ),
              ],
            ),
          ),
        Expanded(
          child: ListView(
            controller: _scroll,
            padding: const EdgeInsets.all(CambuseSpacing.md),
            children: [
              Text(l.aiPrivacy(providerName), style: TextStyle(color: p.textSecondary)),
              Text(l.aiDisclaimer, style: TextStyle(color: p.textSecondary)),
              const SizedBox(height: CambuseSpacing.md),
              for (final r in rows)
                _Bubble(
                  user: r.role == 'user',
                  text: ConversationRepository.toMessage(r).text,
                  caption: r.role == 'assistant' ? _usageCaption(l, r) : null,
                ),
              if (_pendingQuestion != null) _Bubble(user: true, text: _pendingQuestion!),
              if (_busy)
                _Bubble(
                  user: false,
                  text: _pending.isEmpty ? l.aiThinking : _pending,
                  muted: _pending.isEmpty,
                  showSpinner: _pending.isEmpty || _thinking,
                ),
              if (_notice != null) _Banner(text: _notice!, color: p.gold, icon: Icons.shield),
              if (_error != null) _Banner(text: _error!, color: p.alert, icon: Icons.error_outline),
            ],
          ),
        ),
        if (used != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: CambuseSpacing.md),
            child: Text(
              config.dailyTokenBudget > 0
                  ? l.aiTokensToday(used, config.dailyTokenBudget)
                  : l.aiTokensTodayUnlimited(used),
              style: TextStyle(color: p.textSecondary, fontSize: 12),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(CambuseSpacing.sm),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _input,
                enabled: !_busy,
                minLines: 1,
                maxLines: 5,
                textInputAction: TextInputAction.send,
                decoration: InputDecoration(labelText: l.aiInputHint),
                onSubmitted: (_) => _send(),
              ),
            ),
            const SizedBox(width: CambuseSpacing.sm),
            _busy
                ? IconButton.filledTonal(
                    tooltip: l.aiStop,
                    icon: const Icon(Icons.stop),
                    onPressed: () => _cancel?.complete(),
                  )
                : IconButton.filled(
                    tooltip: l.aiSend,
                    icon: const Icon(Icons.send),
                    onPressed: _send,
                  ),
          ]),
        ),
      ],
    );
  }

  String _usageCaption(AppLocalizations l, AiMessageRow r) {
    final usage = AiUsage(inputTokens: r.inputTokens, outputTokens: r.outputTokens);
    final model = r.model ?? '';
    final cost = AiConfig.estimateCost(model, usage);
    return [
      l.aiUsageLine(usage.total, model),
      if (cost != null) l.aiCostLine(cost.toStringAsFixed(4)),
    ].join(' · ');
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.text, required this.color, required this.icon});
  final String text;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: CambuseSpacing.sm),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color),
          const SizedBox(width: CambuseSpacing.sm),
          Expanded(child: Text(text, style: TextStyle(color: color))),
        ]),
      );
}

/// Bulle de message. Les blocs ``` sont rendus en police à chasse fixe ; rien
/// n'est interprété ni exécuté.
class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.user,
    required this.text,
    this.caption,
    this.muted = false,
    this.showSpinner = false,
  });

  final bool user;
  final String text;
  final String? caption;
  final bool muted;
  final bool showSpinner;

  @override
  Widget build(BuildContext context) {
    final p = CambuseTheme.of(context);
    // Les messages de l'apprenant restent du texte brut ; ceux du professeur
    // sont mis en forme (Markdown simplifié, rien de cliquable).
    final content = MarkdownLiteView(text: text, plain: user, muted: muted);
    return Align(
      alignment: user ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Container(
          margin: const EdgeInsets.only(bottom: CambuseSpacing.sm),
          padding: const EdgeInsets.all(CambuseSpacing.md),
          decoration: BoxDecoration(
            color: user ? p.night : p.surface,
            borderRadius: BorderRadius.circular(CambuseSpacing.radius),
            border: Border.all(color: user ? p.turquoise : p.copper, width: p.borderWidth),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (!user)
              Row(children: [
                Icon(Icons.smart_toy, size: 18, color: p.gold),
                const SizedBox(width: CambuseSpacing.xs),
                Text('Capitaine Commit', style: TextStyle(color: p.gold, fontWeight: FontWeight.w700)),
                if (showSpinner) ...[
                  const SizedBox(width: CambuseSpacing.sm),
                  const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                ],
              ]),
            if (!user) const SizedBox(height: CambuseSpacing.xs),
            content,
            if (caption != null) ...[
              const SizedBox(height: CambuseSpacing.xs),
              Text(caption!, style: TextStyle(color: p.textSecondary, fontSize: 12)),
            ],
          ]),
        ),
      ),
    );
  }
}
