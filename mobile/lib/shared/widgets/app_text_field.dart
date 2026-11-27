import 'package:flutter/material.dart';

/// Styled text field matching the app's input decoration theme.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.errorText,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.obscureText = false,
    this.readOnly    = false,
    this.autofocus   = false,
    this.maxLines    = 1,
    this.maxLength,
    this.prefixIcon,
    this.suffixIcon,
    this.focusNode,
  });

  final TextEditingController? controller;
  final String?           label;
  final String?           hint;
  final String?           errorText;
  final FormFieldValidator<String>? validator;
  final TextInputType?    keyboardType;
  final TextInputAction?  textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback?     onTap;
  final bool              obscureText;
  final bool              readOnly;
  final bool              autofocus;
  final int               maxLines;
  final int?              maxLength;
  final Widget?           prefixIcon;
  final Widget?           suffixIcon;
  final FocusNode?        focusNode;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscure;

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) => TextFormField(
        controller:      widget.controller,
        focusNode:       widget.focusNode,
        keyboardType:    widget.keyboardType,
        textInputAction: widget.textInputAction,
        obscureText:     _obscure,
        readOnly:        widget.readOnly,
        autofocus:       widget.autofocus,
        maxLines:        widget.obscureText ? 1 : widget.maxLines,
        maxLength:       widget.maxLength,
        onChanged:       widget.onChanged,
        onFieldSubmitted: widget.onSubmitted,
        onTap:           widget.onTap,
        validator:       widget.validator,
        decoration: InputDecoration(
          labelText:  widget.label,
          hintText:   widget.hint,
          errorText:  widget.errorText,
          prefixIcon: widget.prefixIcon,
          suffixIcon: widget.obscureText
              ? IconButton(
                  icon: Icon(_obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscure = !_obscure),
                )
              : widget.suffixIcon,
        ),
      );
}
