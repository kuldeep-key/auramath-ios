import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/repositories/family_repository.dart';
import '../../../../data/repositories/grown_up_repository.dart';
import '../../../../data/services/api.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../routing/paths.dart';
import '../../../core/parts/aura_button.dart';
import '../../../core/parts/aura_page.dart';
import '../../../core/parts/avatar.dart';
import '../../../core/theme/tokens.dart';

// The grown-up area's own small parts, from Figma's parent components:
// Pcard 684:67, Kv 684:99, Opt 684:95 and the section labels.

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
    this.detail,
    this.chevron = false,
  });

  final String label;
  final String? value;

  /// A mute line under the label ("The teacher's voice").
  final String? detail;

  /// A small › after the value (`.kv.tap`, a picker behind it).
  final bool chevron;

  /// In place of [value] (a "Remove" link).
  final Widget? trailing;
  final bool divider;

  /// A setting: tapping changes the value. The row grows to 48 pt (iOS
  /// asks 44, Android 48).
  final VoidCallback? onTap;
  final String? hint;

  @override
  Widget build(BuildContext context) => onTap == null
      ? _row()
      : Semantics(
          button: true,
          hint: hint,
          child: InkWell(onTap: onTap, child: _row()),
        );

  /// `.kv`'s hairline: #EEF0F5.
  static const rule = Color(0xFFEEF0F5);

  Widget _row() => Container(
    constraints: BoxConstraints(minHeight: onTap == null ? 32 : 48),
    padding: onTap == null
        ? const EdgeInsets.symmetric(vertical: 6)
        : const EdgeInsets.symmetric(vertical: 10),
    decoration: divider
        ? const BoxDecoration(
            border: Border(bottom: BorderSide(color: rule)),
          )
        : null,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: detail == null
              ? Text(label, style: AuraText.kvLabel)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AuraText.kvLabel),
                    Text(detail!, style: AuraText.optionDetail),
                  ],
                ),
        ),
        const SizedBox(width: 12),
        if (trailing != null)
          trailing!
        else if (value != null)
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    value!,
                    style: AuraText.kvValue,
                    textAlign: TextAlign.end,
                  ),
                ),
                if (chevron)
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: AuraColors.blueInk,
                  ),
              ],
            ),
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
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
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
              style: AuraText.barTitle,
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
                        Text(detail!, style: AuraText.optionDetail),
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
        style: AuraText.eyebrow.copyWith(color: AuraColors.mute),
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

  /// What a parent or carer reads for [e] (PAR-14). The server couldn't
  /// be reached: says so plainly. The server's own reason, or the app's,
  /// as it says it. Anything else (a bare status line, an answer that
  /// isn't JSON, an error that isn't an [ApiException]): "That didn't work
  /// just now". Never a socket error or a status line: they go to the log
  /// only. A [String] is already the screen's own words.
  static String message(Object e, AppLocalizations l) {
    if (e is String) return e;
    if (e is ApiException && !_unreached(e) && !_technical(e)) {
      return e.message;
    }
    debugPrint('family area: $e');
    return e is ApiException && _unreached(e)
        ? l.guOffline
        : l.guSomethingWrong;
  }

  static bool _unreached(ApiException e) =>
      e.offline && (e.cause != null || e.message.startsWith(_unreachable));
  static final _unreachable = const ApiException.unreachable('').message;

  /// api_client's own words for an answer with no reason in it.
  static bool _technical(ApiException e) =>
      RegExp(r'^HTTP \d+$').hasMatch(e.message) ||
      e.message == 'The server sent something that is not JSON';

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
            Expanded(
              child: Text(
                message(error, AppLocalizations.of(context)!),
                style: AuraText.body,
              ),
            ),
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
    this.refresh,
  });

  final Future<T> Function() load;
  final String? fallback;

  /// Loads again each time it fires: `FamilyRepository.childrenChanged`,
  /// so a child's new name shows on every screen the grown-up goes back to.
  final Listenable? refresh;
  final Widget Function(BuildContext context, T data, VoidCallback reload)
  builder;

  @override
  State<Loaded<T>> createState() => _LoadedState<T>();
}

class _LoadedState<T> extends State<Loaded<T>> {
  late Future<T> _future = widget.load();
  (T,)? _last;

  @override
  void initState() {
    super.initState();
    widget.refresh?.addListener(_refreshed);
  }

  @override
  void didUpdateWidget(Loaded<T> old) {
    super.didUpdateWidget(old);
    if (old.refresh != widget.refresh) {
      old.refresh?.removeListener(_refreshed);
      widget.refresh?.addListener(_refreshed);
    }
  }

  @override
  void dispose() {
    widget.refresh?.removeListener(_refreshed);
    super.dispose();
  }

  void _refreshed() {
    if (mounted) _reload();
  }

  void _reload() => setState(() {
    _future = widget.load();
  });

  @override
  Widget build(BuildContext context) => FutureBuilder<T>(
    future: _future,
    builder: (context, snap) {
      if (snap.connectionState == ConnectionState.done && !snap.hasError) {
        _last = (snap.data as T,);
        return widget.builder(context, snap.data as T, _reload);
      }
      // loading again: the page stays as it was until the new data is in
      final last = _last;
      if (last != null && !snap.hasError) {
        return widget.builder(context, last.$1, _reload);
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
  const ChildAvatar({
    super.key,
    required this.name,
    this.avatar,
    this.size = 56,
  });

  final String name;

  /// The avatar the child chose (ACC-12); the initial until there is one.
  final String? avatar;
  final double size;

  @override
  Widget build(BuildContext context) =>
      AvatarDisc(avatar: avatar, size: size, fallback: _initial());

  Widget _initial() => ExcludeSemantics(
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
    this.cancel,
  });

  final String title;
  final String body;
  final String action;

  /// The way out without acting; "Cancel" unless given.
  final String? cancel;
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
            label: widget.cancel ?? l.guCancel,
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

/// The prototype's `.part` on a grown-up screen: Black 13, capitals,
/// spaced, mute ("CHILDREN", "THIS FAMILY").
class PartLabel extends StatelessWidget {
  const PartLabel(this.text, {super.key, this.top = 16, this.bottom = 6});

  final String text;
  final double top;
  final double bottom;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(top: top, bottom: bottom),
    child: Semantics(
      header: true,
      child: Text(
        text.toUpperCase(),
        style: AuraText.eyebrow.copyWith(
          color: AuraColors.mute,
          fontSize: 13,
          letterSpacing: 1.04,
        ),
      ),
    ),
  );
}

/// The prototype's `.empty`: a big mute icon, a navy line, a mute line,
/// centred ("No notes yet", "No child yet").
class EmptyNote extends StatelessWidget {
  const EmptyNote({
    super.key,
    required this.icon,
    required this.title,
    this.body,
  });

  final IconData icon;
  final String title;
  final String? body;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
    child: Column(
      children: [
        Icon(icon, size: 64, color: AuraColors.mute),
        const SizedBox(height: 6),
        Text(
          title,
          textAlign: TextAlign.center,
          style: AuraText.option.copyWith(color: AuraColors.navy),
        ),
        if (body != null) ...[
          const SizedBox(height: 6),
          Text(body!, textAlign: TextAlign.center, style: AuraText.cardLine),
        ],
      ],
    ),
  );
}

/// The prototype's `.statecard`: a white card, centred, an icon or a
/// spinner over a navy line and a mute one (Sent, Getting it ready, the
/// family side's error). [ok] edges it green.
class StateCard extends StatelessWidget {
  const StateCard({
    super.key,
    required this.art,
    required this.title,
    this.body,
    this.ok = false,
  });

  final Widget art;
  final String title;
  final String? body;
  final bool ok;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 18),
    decoration: BoxDecoration(
      color: AuraColors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: ok ? AuraColors.green : AuraColors.line,
        width: 1.5,
      ),
    ),
    child: Semantics(
      liveRegion: true,
      child: Column(
        children: [
          art,
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AuraText.option.copyWith(color: AuraColors.navy),
          ),
          if (body != null) ...[
            const SizedBox(height: 8),
            Text(body!, textAlign: TextAlign.center, style: AuraText.cardLine),
          ],
        ],
      ),
    ),
  );
}

/// The prototype's `.sw`: a 52 × 32 switch, grey off and green on, its
/// white knob sliding over 200 ms.
class AuraSwitch extends StatelessWidget {
  const AuraSwitch({super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool>? onChanged;

  static const off = Color(0xFFD6DCE8);

  @override
  Widget build(BuildContext context) {
    const move = Duration(milliseconds: 200);
    return Semantics(
      toggled: value,
      enabled: onChanged != null,
      child: GestureDetector(
        onTap: onChanged == null ? null : () => onChanged!(!value),
        child: AnimatedContainer(
          duration: move,
          width: 52,
          height: 32,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: value ? AuraColors.green : off,
            borderRadius: BorderRadius.circular(16),
          ),
          child: AnimatedAlign(
            duration: move,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 26,
              height: 26,
              decoration: const BoxDecoration(
                color: AuraColors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x40000000),
                    offset: Offset(0, 1),
                    blurRadius: 3,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A row with a switch on the right; the whole row toggles it.
class SwitchRow extends StatelessWidget {
  const SwitchRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.detail,
    this.divider = true,
  });

  final String label;
  final String? detail;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool divider;

  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: KvRow(
      label: label,
      detail: detail,
      divider: divider,
      onTap: onChanged == null ? null : () => onChanged!(!value),
      trailing: AuraSwitch(value: value, onChanged: onChanged),
    ),
  );
}
