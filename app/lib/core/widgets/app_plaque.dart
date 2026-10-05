import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/bt_tokens.dart';

/// What an [AppPlaque] holds (docs/design/ui-kit-spec.md §6.2).
enum AppPlaqueKind {
  /// Deck name, name at the table: Fraunces 22 on a wire.
  nome,

  /// Search: same plaque, the magnifier goes in [AppPlaque.leading].
  busca,

  /// AI prompt: up to four lines, the wire under all of them.
  prompt,

  /// Password: Inter 600 22 tabular dots (a serif dot does not exist).
  senha,

  /// E-mail: the name plaque with the e-mail keyboard and no correction.
  email,
}

/// The plaque (`.plaque`, vt-05-jogador.png): the kit's free-text field.
///
/// Large serif over a wire, no box: the wire rests at ivory .45 (D1,
/// D-44: 4.09:1) and lights in brass on focus; an error turns it ember and
/// adds one capital word ([errorWord]) or, when a word does not fit, one
/// line ([errorLine]). The caption sits above, fixed, in capitals — never a
/// floating label. The whole row is a 48 dp target.
class AppPlaque extends StatefulWidget {
  const AppPlaque({
    super.key,
    required this.controller,
    this.kind = AppPlaqueKind.nome,
    this.caption,
    this.placeholder,
    this.leading,
    this.trailing,
    this.errorWord,
    this.errorLine,
    this.maxLines = 1,
    this.onSubmitted,
    this.autofillHints,
    this.textInputAction,
    this.focusNode,
    this.onChanged,
    this.validator,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.autocorrect = true,
    this.enabled = true,
    this.readOnly = false,
    this.fieldKey,
  });

  final TextEditingController controller;
  final AppPlaqueKind kind;

  /// The capital caption above the wire; also the accessible name.
  final String? caption;

  /// Italic, mist-dim.
  final String? placeholder;

  /// Magnifier, player dot.
  final Widget? leading;

  /// Eye, counter.
  final Widget? trailing;

  /// "JÁ EXISTE": one capital word in ember.
  final String? errorWord;

  /// The whole sentence when a word does not fit (password rule, server
  /// error): Inter 500 12px in ember, at most two lines.
  final String? errorLine;

  /// Lines of a [AppPlaqueKind.prompt] (capped at 4).
  final int maxLines;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;

  /// Runs inside the enclosing `Form`; its message shows as [errorLine].
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final bool autocorrect;
  final bool enabled;
  final bool readOnly;

  /// Stable key of the inner editable field.
  final Key? fieldKey;

  @override
  State<AppPlaque> createState() => _AppPlaqueState();
}

class _AppPlaqueState extends State<AppPlaque> {
  FocusNode? _ownFocus;
  bool _focused = false;

  FocusNode get _focus => widget.focusNode ?? (_ownFocus ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocus);
  }

  @override
  void didUpdateWidget(AppPlaque old) {
    super.didUpdateWidget(old);
    if (old.focusNode != widget.focusNode) {
      (old.focusNode ?? _ownFocus)?.removeListener(_onFocus);
      _focus.addListener(_onFocus);
    }
  }

  void _onFocus() {
    if (mounted && _focused != _focus.hasFocus) {
      setState(() => _focused = _focus.hasFocus);
    }
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocus);
    _ownFocus?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      initialValue: widget.controller.text,
      validator: widget.validator,
      enabled: widget.enabled,
      builder: (field) => _build(context, field),
    );
  }

  Widget _build(BuildContext context, FormFieldState<String> field) {
    final tokens = BtTokens.of(context);
    final palette = tokens.palette;
    final kind = widget.kind;
    final secret = kind == AppPlaqueKind.senha;
    final email = kind == AppPlaqueKind.email;
    final prompt = kind == AppPlaqueKind.prompt;
    final errorLine = widget.errorLine ?? field.errorText;
    final hasError = widget.errorWord != null || errorLine != null;
    final wire = hasError
        ? palette.ember
        : _focused
        ? palette.brass
        : palette.plaqueRest;
    final textStyle =
        (secret ? tokens.typography.plaqueSecret : tokens.typography.plaque)
            .copyWith(color: palette.ivory);
    final hintStyle = tokens.typography.plaque.copyWith(
      color: palette.mistDim,
      fontStyle: FontStyle.italic,
    );
    final lines = prompt ? widget.maxLines.clamp(1, 4) : 1;

    final input = TextField(
      key: widget.fieldKey ?? const ValueKey<String>('app-plaque-field'),
      controller: widget.controller,
      focusNode: _focus,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      obscureText: secret,
      obscuringCharacter: '•',
      maxLines: secret ? 1 : lines,
      minLines: 1,
      style: textStyle,
      cursorColor: palette.brass,
      keyboardType:
          widget.keyboardType ??
          (email
              ? TextInputType.emailAddress
              : prompt
              ? TextInputType.multiline
              : null),
      textCapitalization: email || secret
          ? TextCapitalization.none
          : widget.textCapitalization,
      autocorrect: !(email || secret) && widget.autocorrect,
      enableSuggestions: !(email || secret),
      autofillHints:
          widget.autofillHints ??
          (email
              ? const [AutofillHints.email]
              : secret
              ? const [AutofillHints.password]
              : null),
      textInputAction: widget.textInputAction,
      onSubmitted: widget.onSubmitted,
      onChanged: (value) {
        field.didChange(value);
        widget.onChanged?.call(value);
      },
      // No box, no fill, no floating label (§6.4): the wire is drawn by the
      // plaque, not by the decoration.
      decoration: InputDecoration(
        isCollapsed: true,
        filled: false,
        hintText: widget.placeholder,
        hintStyle: hintStyle,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        disabledBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        focusedErrorBorder: InputBorder.none,
        contentPadding: EdgeInsets.zero,
      ),
    );

    final row = GestureDetector(
      behavior: HitTestBehavior.translucent,
      excludeFromSemantics: true,
      onTap: widget.enabled ? _focus.requestFocus : null,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: tokens.metrics.touchTarget),
        child: Container(
          alignment: AlignmentDirectional.bottomStart,
          padding: const EdgeInsetsDirectional.only(
            top: AppTheme.space2,
            bottom: AppTheme.space7,
          ),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: wire, width: AppTheme.strokeStrong),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (widget.leading != null) ...[
                IconTheme.merge(
                  data: IconThemeData(color: palette.mist, size: 22),
                  child: widget.leading!,
                ),
                const SizedBox(width: AppTheme.space10),
              ],
              Expanded(child: input),
              if (widget.trailing != null) ...[
                const SizedBox(width: AppTheme.space10),
                widget.trailing!,
              ],
            ],
          ),
        ),
      ),
    );

    return Opacity(
      opacity: widget.enabled ? 1 : tokens.metrics.disabledOpacity,
      child: MergeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.caption != null) ...[
              Text(
                widget.caption!.toUpperCase(),
                style: tokens.typography.bandCaption.copyWith(
                  color: palette.mist,
                ),
              ),
              const SizedBox(height: AppTheme.space7),
            ],
            row,
            if (widget.errorWord != null) ...[
              const SizedBox(height: AppTheme.space6),
              Semantics(
                liveRegion: true,
                child: Text(
                  widget.errorWord!.toUpperCase(),
                  style: tokens.typography.ruleState.copyWith(
                    color: palette.ember,
                  ),
                ),
              ),
            ] else if (errorLine != null) ...[
              const SizedBox(height: AppTheme.space6),
              Semantics(
                liveRegion: true,
                child: Text(
                  errorLine,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: tokens.typography.errorLine.copyWith(
                    color: palette.ember,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
