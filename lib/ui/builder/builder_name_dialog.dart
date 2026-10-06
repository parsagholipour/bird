import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/game_rules.dart';
import '../theme.dart';
import 'builder_chrome.dart';

/// Asks for a level's new name in a compact card at the top of the screen,
/// above where the keyboard rises (it covers more than half a landscape
/// phone). Every level already has a name, so this is never required.
/// Returns the new name, or null when cancelled or unchanged.
Future<String?> showBuilderNameDialog(BuildContext context, String name) {
  final still = MediaQuery.disableAnimationsOf(context);
  return showGeneralDialog<String>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Cancel rename',
    barrierColor: const Color(0xff12333d).withValues(alpha: .6),
    transitionDuration: still
        ? Duration.zero
        : const Duration(milliseconds: 160),
    pageBuilder: (context, _, _) => _NameDialog(name: name),
    transitionBuilder: (context, animation, _, child) => still
        ? child
        : FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween(begin: const Offset(0, -.2), end: Offset.zero)
                  .animate(
                    CurvedAnimation(parent: animation, curve: Curves.easeOut),
                  ),
              child: child,
            ),
          ),
  );
}

class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.name});
  final String name;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final text = TextEditingController(
    text: widget.name,
  )..selection = TextSelection(baseOffset: 0, extentOffset: widget.name.length);

  String get _name => text.text.trim();
  bool get _valid => BuiltPlan.validName(_name);

  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  void _save() {
    if (!_valid) return;
    Navigator.of(context).pop(_name == widget.name ? null : _name);
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16 + padding.left,
          10 + padding.top,
          16 + padding.right,
          0,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Material(
            type: MaterialType.transparency,
            child: Container(
              key: const ValueKey('name-dialog'),
              padding: const EdgeInsets.fromLTRB(14, 10, 12, 14),
              decoration: BoxDecoration(
                color: SkyColors.cream,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: SkyColors.ink, width: 2.5),
                boxShadow: const [
                  BoxShadow(color: SkyColors.ink, offset: Offset(0, 5)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Text(
                        'Name your level',
                        style: heading(17, weight: FontWeight.w700),
                      ),
                      const Spacer(),
                      ListenableBuilder(
                        listenable: text,
                        builder: (context, _) => Text(
                          _name.isEmpty
                              ? 'A name needs a letter or two'
                              : '${text.text.length} / ${BuiltPlan.maxName}',
                          style: bodyText(
                            12,
                            color: _name.isEmpty
                                ? SkyColors.coralDeep
                                : SkyColors.muted,
                            weight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          key: const ValueKey('name-field'),
                          controller: text,
                          autofocus: true,
                          maxLength: BuiltPlan.maxName,
                          maxLengthEnforcement: MaxLengthEnforcement.enforced,
                          textCapitalization: TextCapitalization.sentences,
                          textInputAction: TextInputAction.done,
                          inputFormatters: [
                            FilteringTextInputFormatter.deny(
                              RegExp(r'[\u0000-\u001f\u007f]'),
                            ),
                          ],
                          onSubmitted: (_) => _save(),
                          style: heading(20, weight: FontWeight.w600),
                          cursorColor: SkyColors.ink,
                          decoration: InputDecoration(
                            counterText: '',
                            isDense: true,
                            filled: true,
                            fillColor: SkyColors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 13,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: SkyColors.ink,
                                width: 2,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: SkyColors.teal,
                                width: 3,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      BuilderKey(
                        key: const ValueKey('name-cancel'),
                        tooltip: 'Cancel',
                        icon: Icons.close_rounded,
                        sound: 'ui_back',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 8),
                      ListenableBuilder(
                        listenable: text,
                        builder: (context, _) => BuilderKey(
                          key: const ValueKey('name-save'),
                          tooltip: 'Save name',
                          label: 'Save',
                          icon: Icons.check_rounded,
                          color: SkyColors.mint,
                          onPressed: _valid ? _save : null,
                        ),
                      ),
                    ],
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
