import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/repositories/family_repository.dart';
import '../../../../data/repositories/grown_up_repository.dart';
import '../../../../data/services/api.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../routing/paths.dart';
import '../../../core/parts/aura_button.dart';
import '../../../core/parts/aura_page.dart';
import '../../../core/theme/tokens.dart';

// The grown-up area's own small parts, from Figma's parent components:
// Pcard 684:67, Kv 684:99, Opt 684:95 and the section labels.

/// [s] at another weight of the variable Nunito.
TextStyle weight(TextStyle s, double w) => s.copyWith(
  fontWeight: FontWeight.values[(w ~/ 100) - 1],
  fontVariations: [FontVariation('wght', w)],
);

/// The child's name, or "your child" when there is no single child to name.
String childName(BuildContext context, List<Child> children) =>
    children.length == 1
    ? children.single.name
    : AppLocalizations.of(context)!.guYourChild;

/// Monday 00:00 of this week, on this phone's clock.
DateTime weekStart(DateTime now) =>
    DateTime(now.year, now.month, now.day - (now.weekday - 1));

/// Lessons since [from], and their finished minutes added up.
({int count, int minutes}) tally(List<Lesson> lessons, DateTime from) {
  final since = lessons.where((s) => !s.startedAt.isBefore(from));
  return (
    count: since.length,
    minutes: since.fold(0, (sum, s) => sum + (s.minutes ?? 0)),
  );
}

/// A white card, or a blue-tinted one for a link to another view.
class GuCard extends StatelessWidget {
  const GuCard({
    super.key,
    required this.child,
    this.tint = false,
    this.onTap,
    this.label,
  });

  final Widget child;
  final bool tint;
  final VoidCallback? onTap;

  /// What a screen reader says for a tappable card.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AuraRadii.panel);
    final card = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tint ? AuraColors.blueTint : AuraColors.white,
        borderRadius: radius,
        border: Border.all(color: AuraColors.line, width: 2),
        boxShadow: const [
          BoxShadow(color: AuraColors.line, offset: Offset(0, 3)),
        ],
      ),
      child: child,
    );
    if (onTap == null) return card;
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(borderRadius: radius, onTap: onTap, child: card),
      ),
    );
  }
}

/// One line of a card: a name on the left, its value on the right.
class KvRow extends StatelessWidget {
  const KvRow({
    super.key,
    required this.label,
    this.value,
    this.trailing,
    this.divider = true,
    this.onTap,
    this.hint,
  });

  final String label;
  final String? value;

  /// In place of [value] (a "Remove" link).
  final Widget? trailing;
  final bool divider;

  /// A setting: tapping changes the value. The row grows to 44 pt.
  final VoidCallback? onTap;
  final String? hint;

  static final labelStyle = weight(AuraText.small, 700);
  static final valueStyle = weight(
    AuraText.small,
    900,
  ).copyWith(color: AuraColors.blueInk);

  @override
  Widget build(BuildContext context) => onTap == null
      ? _row()
      : Semantics(
          button: true,
          hint: hint,
          child: InkWell(onTap: onTap, child: _row()),
        );

  Widget _row() => Container(
    constraints: BoxConstraints(minHeight: onTap == null ? 32 : 44),
    padding: const EdgeInsets.only(top: 6, bottom: 7),
    decoration: divider
        ? const BoxDecoration(
            border: Border(bottom: BorderSide(color: AuraColors.ink)),
          )
        : null,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(child: Text(label, style: labelStyle)),
        const SizedBox(width: 12),
        if (trailing != null)
          trailing!
        else if (value != null)
          Flexible(
            child: Text(value!, style: valueStyle, textAlign: TextAlign.end),
          ),
      ],
    ),
  );
}

/// The child [id] with what [more] loads for them; 404s like the server
/// when the child isn't in this family.
Future<(Child, T)> withChild<T>(
  FamilyRepository family,
  String id,
  Future<T> Function() more,
) async {
  final children = await family.children();
  final child = children.where((c) => c.id == id).firstOrNull;
  if (child == null) throw const ApiException('no such child', status: 404);
  return (child, await more());
}

/// Back, a small title, and the settings gear beside it (Book 652:35).
class TitleBar extends StatelessWidget {
  const TitleBar({super.key, required this.title, required this.fallback});

  final String title;
  final String fallback;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 48,
    child: Row(
      children: [
        IconButton(
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          alignment: Alignment.centerLeft,
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          icon: const Icon(Icons.arrow_back_rounded, color: AuraColors.ink),
          onPressed: () => popOr(context, fallback),
        ),
        Flexible(
          child: Semantics(
            header: true,
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: weight(AuraText.body, 700).copyWith(fontSize: 18),
            ),
          ),
        ),
        IconButton(
          tooltip: AppLocalizations.of(context)!.guSettingsTitle,
          icon: const Icon(Icons.settings_outlined, color: AuraColors.ink),
          onPressed: () => context.push(Paths.settings),
        ),
      ],
    ),
  );
}

/// A tappable row: icon, title (and a line under it), chevron.
class NavRow extends StatelessWidget {
  const NavRow({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.detail,
    this.iconColor = AuraColors.blue,
    this.chevron = true,
  });

  final IconData icon;
  final String label;
  final String? detail;
  final VoidCallback? onTap;
  final Color iconColor;
  final bool chevron;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AuraRadii.button);
    return Semantics(
      button: onTap != null,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AuraColors.white,
              borderRadius: radius,
              border: Border.all(color: AuraColors.line, width: 2),
              boxShadow: const [
                BoxShadow(color: AuraColors.line, offset: Offset(0, 4)),
              ],
            ),
            child: Row(
              children: [
                Icon(icon, color: iconColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: AuraText.option),
                      if (detail != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          detail!,
                          style: AuraText.small.copyWith(
                            fontSize: 14,
                            color: AuraColors.mute,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (chevron) const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "GROWN-UPS", "CHILDREN", "PHONES".
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 10, bottom: 6),
    child: Semantics(
      header: true,
      child: Text(
        text.toUpperCase(),
        style: AuraText.flag.copyWith(
          fontSize: 11,
          letterSpacing: 0.9,
          color: AuraColors.mute,
        ),
      ),
    ),
  );
}

/// A failure, said plainly near where it happened, with a way to retry.
/// An icon as well as words: never colour alone.
class ErrorNote extends StatelessWidget {
  const ErrorNote(this.error, {super.key, this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  static String message(Object e) => e is ApiException ? e.message : '$e';

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline_rounded, color: AuraColors.ink),
            const SizedBox(width: 8),
            Expanded(child: Text(message(error), style: AuraText.body)),
          ],
        ),
        if (onRetry != null)
          AuraLink(
            label: AppLocalizations.of(context)!.guTryAgain,
            onPressed: onRetry,
          ),
      ],
    ),
  );
}

/// Loads once, shows a spinner, then [builder]; a failure shows the
/// server's message and Try again. [reload] runs the load again.
///
/// With a [fallback], the spinner and the failure get a whole page (a back
/// button going there): for a screen whose page needs the data.
class Loaded<T> extends StatefulWidget {
  const Loaded({
    super.key,
    required this.load,
    required this.builder,
    this.fallback,
  });

  final Future<T> Function() load;
  final String? fallback;
  final Widget Function(BuildContext context, T data, VoidCallback reload)
  builder;

  @override
  State<Loaded<T>> createState() => _LoadedState<T>();
}

class _LoadedState<T> extends State<Loaded<T>> {
  late Future<T> _future = widget.load();

  void _reload() => setState(() {
    _future = widget.load();
  });

  @override
  Widget build(BuildContext context) => FutureBuilder<T>(
    future: _future,
    builder: (context, snap) {
      if (snap.connectionState == ConnectionState.done && !snap.hasError) {
        return widget.builder(context, snap.data as T, _reload);
      }
      final Widget state = snap.hasError
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: ErrorNote(snap.error!, onRetry: _reload),
            )
          : const Spinner();
      final fallback = widget.fallback;
      return fallback == null
          ? state
          : AuraPage(
              top: AuraTopBar(fallback: fallback),
              body: state,
            );
    },
  );
}

class Spinner extends StatelessWidget {
  const Spinner({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Center(
      child: CircularProgressIndicator(
        semanticsLabel: AppLocalizations.of(context)!.guLoading,
      ),
    ),
  );
}

/// A child's round badge: their initial on the avatar's yellow. Figma
/// draws sample portraits; a child chosen from the server has none yet.
class ChildAvatar extends StatelessWidget {
  const ChildAvatar({super.key, required this.name, this.size = 56});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AuraColors.yellow,
        border: Border.all(color: AuraColors.navy, width: 4),
      ),
      child: Text(
        name.isEmpty ? '?' : name.characters.first.toUpperCase(),
        style: AuraText.title.copyWith(color: AuraColors.navy),
      ),
    ),
  );
}

/// A heading and a line, then the one action and Cancel: RemovePhone
/// (653:159), SignOut (659:105) and deleting the account. Cancel pops.
/// A failed action stays here, says why, and can be tried again.
class ConfirmScreen extends StatefulWidget {
  const ConfirmScreen({
    super.key,
    required this.title,
    required this.body,
    required this.action,
    required this.onConfirm,
    required this.fallback,
  });

  final String title;
  final String body;
  final String action;
  final Future<void> Function() onConfirm;

  /// Where back and Cancel go when nothing is underneath.
  final String fallback;

  @override
  State<ConfirmScreen> createState() => _ConfirmScreenState();
}

class _ConfirmScreenState extends State<ConfirmScreen> {
  bool _busy = false;
  Object? _error;

  Future<void> _confirm() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onConfirm();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AuraPage(
      top: AuraTopBar(fallback: widget.fallback),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AuraHeading(title: widget.title, subtitle: widget.body),
          if (_error != null) ErrorNote(_error!),
        ],
      ),
      bottom: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuraButton(
            label: widget.action,
            color: AuraButtonColor.blue,
            onPressed: _busy ? null : _confirm,
          ),
          const SizedBox(height: 12),
          AuraLink(
            label: l.guCancel,
            onPressed: _busy ? null : () => popOr(context, widget.fallback),
          ),
        ],
      ),
    );
  }
}

/// Back one step, or to [fallback] when nothing is underneath.
void popOr(BuildContext context, String fallback) {
  final router = GoRouter.of(context);
  router.canPop() ? router.pop() : router.go(fallback);
}
