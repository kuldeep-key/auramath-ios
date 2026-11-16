import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/repositories/account_repository.dart';
import '../../../../data/repositories/family_repository.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../routing/paths.dart';
import '../../../core/motion/motion.dart';
import '../../../core/parts/aura_button.dart';
import '../../../core/parts/aura_page.dart';
import '../../../core/parts/avatar.dart';
import '../../../core/parts/ribbon.dart';
import '../../../core/theme/tokens.dart';
import 'play_message.dart';

/// The shared phone's picker: a child taps their picture, a grown-up taps
/// Grown-ups (the router asks for the passcode). Figma: A1 · Who's
/// learning? (644:38). A family with one child has nothing to pick: the
/// phone goes straight to that child's Home (DEV-01), and Home's own
/// Grown-ups button is the way back.
class KidsScreen extends StatefulWidget {
  const KidsScreen({super.key, required this.account, required this.family});

  final AccountRepository account;
  final FamilyRepository family;

  @override
  State<KidsScreen> createState() => _KidsScreenState();
}

class _KidsScreenState extends State<KidsScreen> {
  late Future<List<Child>> _children = _load();

  @override
  void initState() {
    super.initState();
    // the grown-up area changed a child: read them again, so the picker
    // shows the new name when the grown-up comes back here
    widget.family.childrenChanged.addListener(_reread);
  }

  @override
  void dispose() {
    widget.family.childrenChanged.removeListener(_reread);
    super.dispose();
  }

  void _reread() {
    if (!mounted) return;
    setState(() {
      _children = _load(pickOnly: false);
    });
  }

  /// [pickOnly]: a family with one child goes straight to them, but only
  /// on the first read, never while the grown-up area is in front.
  Future<List<Child>> _load({bool pickOnly = true}) async {
    final children = await widget.family.children();
    if (pickOnly && children.length == 1) await _pick(children.single);
    return children;
  }

  Future<void> _pick(Child c) async {
    await widget.account.chooseChild(c.id);
    if (mounted) context.go(Paths.home);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    // the prototype's A1 (16 Nov): the ribbon, "Tap your picture." and the
    // children's tiles in the middle; the Family area pinned below
    return AuraPage(
      play: true,
      bottom: AuraButton(
        label: l.pairFamilyArea,
        leading: const Icon(
          Icons.lock_rounded,
          size: 28,
          color: AuraColors.navy,
        ),
        color: AuraButtonColor.white,
        onPressed: () => context.go(Paths.grownUps),
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: Ribbon(text: l.pairWhosLearning)),
            const SizedBox(height: 12),
            Text(
              l.kidTapYourPicture,
              textAlign: TextAlign.center,
              style: AuraText.play.copyWith(fontSize: 19),
            ),
            const SizedBox(height: 18),
            FutureBuilder(
              future: _children,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done ||
                    snap.data?.length == 1) {
                  return const Center(
                    child: CircularProgressIndicator(color: AuraColors.white),
                  );
                }
                if (snap.hasError) {
                  return LoadError(
                    message: failureText(l, snap.error!),
                    retryLabel: l.pairTryAgain,
                    light: true,
                    onRetry: () => setState(() {
                      _children = _load();
                    }),
                  );
                }
                final children = snap.data!;
                if (children.isEmpty) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l.pairNoKidsYet,
                        textAlign: TextAlign.center,
                        style: AuraText.play,
                      ),
                      const SizedBox(height: 18),
                      AuraButton(
                        label: l.pairAddChild,
                        onPressed: () => context.go(Paths.addChild),
                      ),
                    ],
                  );
                }
                Widget tile(int i) => i < children.length
                    ? Pop(
                        duration: const Duration(milliseconds: 500),
                        delay: Duration(milliseconds: i * 80),
                        child: _ChildTile(
                          child: children[i],
                          onTap: () => _pick(children[i]),
                        ),
                      )
                    : const SizedBox();
                // two to a row (no LayoutBuilder: the page's body measures
                // its height first)
                return Column(
                  children: [
                    for (var i = 0; i < children.length; i += 2) ...[
                      if (i > 0) const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: tile(i)),
                          const SizedBox(width: 14),
                          Expanded(child: tile(i + 1)),
                        ],
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// A child's picture and name. Figma: Prototype parts › Tile (686:47).
class _ChildTile extends StatelessWidget {
  const _ChildTile({required this.child, required this.onTap});

  final Child child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AuraRadii.panel);
    return Semantics(
      button: true,
      label: child.name,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 190),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: AuraColors.navy, width: 3),
              boxShadow: const [
                BoxShadow(color: AuraColors.navy, offset: Offset(0, 6)),
              ],
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.lerp(AuraColors.blue, AuraColors.white, 0.2)!,
                  AuraColors.blue,
                ],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AvatarDisc(avatar: child.avatar, size: 112),
                const SizedBox(height: 8),
                Text(
                  child.name,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AuraText.button.copyWith(color: AuraColors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
