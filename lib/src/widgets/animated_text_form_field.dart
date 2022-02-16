import 'dart:io';
import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' as cupertino;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

import '../../flutter_login.dart';

enum TextFieldInertiaDirection {
  left,
  right,
}

Interval _getInternalInterval(
  double start,
  double end,
  double externalStart,
  double externalEnd, [
  Curve curve = Curves.linear,
]) {
  return Interval(
    start + (end - start) * externalStart,
    start + (end - start) * externalEnd,
    curve: curve,
  );
}

const defaultDateFormat = "dd/MM/yyyy";

class AnimatedTextFormField extends StatefulWidget {
  const AnimatedTextFormField(
      {Key? key,
      this.interval = const Interval(0.0, 1.0),
      required this.width,
      this.loadingController,
      this.inertiaController,
      this.inertiaDirection,
      this.enabled = true,
      this.labelText,
      this.prefixIcon,
      this.suffixIcon,
      this.keyboardType,
      this.textInputAction,
      this.obscureText = false,
      this.controller,
      this.focusNode,
      this.validator,
      this.onFieldSubmitted,
      this.onSaved,
      this.autocorrect = false,
      this.autofillHints,
      this.fieldType,
      this.optionItems,
      this.dateFormat})
      : assert((inertiaController == null && inertiaDirection == null) ||
            (inertiaController != null && inertiaDirection != null)),
        super(key: key);

  final Interval? interval;
  final AnimationController? loadingController;
  final AnimationController? inertiaController;
  final double width;
  final bool enabled;
  final bool autocorrect;
  final Iterable<String>? autofillHints;
  final String? labelText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onFieldSubmitted;
  final FormFieldSetter<String>? onSaved;
  final TextFieldInertiaDirection? inertiaDirection;
  final FormFieldType? fieldType;
  final List<String>? optionItems;
  final String? dateFormat;

  @override
  _AnimatedTextFormFieldState createState() => _AnimatedTextFormFieldState();
}

class _AnimatedTextFormFieldState extends State<AnimatedTextFormField> {
  late Animation<double> scaleAnimation;
  late Animation<double> sizeAnimation;
  late Animation<double> suffixIconOpacityAnimation;

  late Animation<double> fieldTranslateAnimation;
  late Animation<double> iconRotationAnimation;
  late Animation<double> iconTranslateAnimation;

  DateTime _selectedDate = _getDefaultDate();

  void _onDateSelected(DateTime? newSelectedDate, String dateFormat) {
    if (newSelectedDate != null) {
      setState(() {
        _selectedDate = newSelectedDate;
        var dateFormatted = DateFormat(dateFormat).format(_selectedDate);
        widget.controller?.text = dateFormatted;
      });
    }
  }

  @override
  void initState() {
    super.initState();

    widget.inertiaController?.addStatusListener(handleAnimationStatus);

    final interval = widget.interval;
    final loadingController = widget.loadingController;

    if (loadingController != null) {
      scaleAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: loadingController,
        curve: _getInternalInterval(
            0, .2, interval!.begin, interval.end, Curves.easeOutBack),
      ));
      suffixIconOpacityAnimation =
          Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: loadingController,
        curve: _getInternalInterval(.65, 1.0, interval.begin, interval.end),
      ));
      _updateSizeAnimation();
    }

    final inertiaController = widget.inertiaController;
    final inertiaDirection = widget.inertiaDirection;
    final sign = inertiaDirection == TextFieldInertiaDirection.right ? 1 : -1;

    if (inertiaController != null) {
      fieldTranslateAnimation = Tween<double>(
        begin: 0.0,
        end: sign * 15.0,
      ).animate(CurvedAnimation(
        parent: inertiaController,
        curve: const Interval(0, .5, curve: Curves.easeOut),
        reverseCurve: Curves.easeIn,
      ));
      iconRotationAnimation =
          Tween<double>(begin: 0.0, end: sign * pi / 12 /* ~15deg */)
              .animate(CurvedAnimation(
        parent: inertiaController,
        curve: const Interval(.5, 1.0, curve: Curves.easeOut),
        reverseCurve: Curves.easeIn,
      ));
      iconTranslateAnimation =
          Tween<double>(begin: 0.0, end: 8.0).animate(CurvedAnimation(
        parent: inertiaController,
        curve: const Interval(.5, 1.0, curve: Curves.easeOut),
        reverseCurve: Curves.easeIn,
      ));
    }
  }

  Future<void> renderDatePicker(String dateFormat) async {
    if (Platform.isIOS) {
      _showCupertinoDialog(
        cupertino.CupertinoDatePicker(
          initialDateTime: _selectedDate,
          minimumDate: _getFistDate(),
          maximumDate: _getLastDate(),
          mode: cupertino.CupertinoDatePickerMode.date,
          use24hFormat: true,
          // This is called when the user changes the date.
          onDateTimeChanged: (DateTime newDate) {
            _onDateSelected(newDate, dateFormat);
          },
        ),
      );
    } else {
      final selectedDate = await showDatePicker(
        context: context,
        initialEntryMode: DatePickerEntryMode.calendarOnly,
        initialDate: _selectedDate,
        firstDate: _getFistDate(),
        lastDate: _getLastDate(),
      );
      _onDateSelected(selectedDate, dateFormat);
    }
  }

  void _updateSizeAnimation() {
    final interval = widget.interval!;
    final loadingController = widget.loadingController!;

    sizeAnimation = Tween<double>(
      begin: 48.0,
      end: widget.width,
    ).animate(CurvedAnimation(
      parent: loadingController,
      curve: _getInternalInterval(
          .2, 1.0, interval.begin, interval.end, Curves.linearToEaseOut),
      reverseCurve: Curves.easeInExpo,
    ));
  }

  @override
  void didUpdateWidget(AnimatedTextFormField oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.width != widget.width) {
      _updateSizeAnimation();
    }
  }

  @override
  void dispose() {
    widget.inertiaController?.removeStatusListener(handleAnimationStatus);
    super.dispose();
  }

  void handleAnimationStatus(status) {
    if (status == AnimationStatus.completed) {
      widget.inertiaController?.reverse();
    }
  }

  Widget? _buildInertiaAnimation(Widget? child) {
    if (widget.inertiaController == null) {
      return child;
    }

    return AnimatedBuilder(
      animation: iconTranslateAnimation,
      builder: (context, child) => Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..translate(iconTranslateAnimation.value)
          ..rotateZ(iconRotationAnimation.value),
        child: child,
      ),
      child: child,
    );
  }

  InputDecoration _getInputDecoration(ThemeData theme) {
    return InputDecoration(
      labelText: widget.labelText,
      prefixIcon: _buildInertiaAnimation(widget.prefixIcon),
      suffixIcon: _buildInertiaAnimation(widget.loadingController != null
          ? FadeTransition(
              opacity: suffixIconOpacityAnimation,
              child: widget.suffixIcon,
            )
          : widget.suffixIcon),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget textField = TextFormField(
      cursorColor: theme.primaryColor,
      controller: widget.controller,
      focusNode: widget.focusNode,
      decoration: _getInputDecoration(theme),
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      obscureText: widget.obscureText,
      onFieldSubmitted: widget.onFieldSubmitted,
      onSaved: widget.onSaved,
      validator: widget.validator,
      enabled: widget.enabled,
      autocorrect: widget.autocorrect,
      autofillHints: widget.autofillHints,
    );

    if (widget.loadingController != null) {
      textField = ScaleTransition(
        scale: scaleAnimation,
        child: AnimatedBuilder(
          animation: sizeAnimation,
          builder: (context, child) => ConstrainedBox(
            constraints: BoxConstraints.tightFor(width: sizeAnimation.value),
            child: child,
          ),
          child: textField,
        ),
      );
    }

    if (widget.inertiaController != null) {
      textField = AnimatedBuilder(
        animation: fieldTranslateAnimation,
        builder: (context, child) => Transform.translate(
          offset: Offset(fieldTranslateAnimation.value, 0),
          child: child,
        ),
        child: textField,
      );
    }

    if (widget.fieldType == FormFieldType.calendar) {
      return GestureDetector(
        onTap: () {
          FocusScope.of(context).requestFocus(FocusNode());
          renderDatePicker(widget.dateFormat ?? defaultDateFormat);
        },
        child: AbsorbPointer(child: textField),
      );
    } else if (widget.fieldType == FormFieldType.options) {
      return GestureDetector(
        onTap: () {
          FocusScope.of(context).requestFocus(FocusNode());
          renderOptionsDialog(widget.optionItems, widget.labelText);
        },
        child: AbsorbPointer(child: textField),
      );
    } else {
      return textField;
    }
  }

  void renderOptionsDialog(List<String>? optionItems, String? labelText) async {
    if (optionItems == null || optionItems.isEmpty == true) {
      return;
    }

    if (Platform.isIOS) {
      final int indexOfCurrentSelection = optionItems
          .indexWhere((element) => element == widget.controller?.text);
      final initialItemIndex = max(0, indexOfCurrentSelection);
      _showCupertinoDialog(cupertino.CupertinoPicker(
        scrollController:
            FixedExtentScrollController(initialItem: initialItemIndex),
        itemExtent: 30,
        children: optionItems.map((e) => Text(e)).toList(),
        onSelectedItemChanged: (selectedOptionIndex) {
          final String selectedOption = optionItems[selectedOptionIndex];
          widget.controller?.text = selectedOption;
        },
      ));
    } else {
      final selectedValue = await showDialog<String>(
          context: context,
          builder: (BuildContext context) {
            return SimpleDialog(
                title: Text(labelText ?? ""),
                children: optionItems
                    .map((e) => SimpleDialogOption(
                        onPressed: () {
                          Navigator.pop(context, e);
                        },
                        child: Text(e)))
                    .toList());
          });

      widget.controller?.text = selectedValue ?? "";
    }
  }

  void _showCupertinoDialog(Widget child) {
    cupertino.showCupertinoModalPopup<void>(
        context: context,
        builder: (BuildContext context) => Container(
              height: 216 + 50,
              padding: const EdgeInsets.only(top: 6.0),
              // The Bottom margin is provided to align the popup above the system navigation bar.
              margin: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              // Provide a background color for the popup.
              color: cupertino.CupertinoColors.systemBackground
                  .resolveFrom(context),
              // Use a SafeArea widget to avoid system overlaps.
              child: SafeArea(
                top: false,
                child: SizedBox(
                  height: 216 + 40,
                  child: cupertino.Column(children: [
                    SizedBox(
                      height: 45,
                      child: cupertino.Align(
                        alignment: cupertino.Alignment.topRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const cupertino.Text('OK',
                              style: cupertino.TextStyle(
                                  fontSize: 12,
                                  color: cupertino.CupertinoColors.systemBlue)),
                        ),
                      ),
                    ),
                    cupertino.Expanded(child: child),
                  ]),
                ),
              ),
            ));
  }
}

DateTime _getFistDate() {
  final DateTime now = DateTime.now();
  return DateTime(now.year - 100, now.month, now.day, 23, 59, 59, 0, 0);
}

DateTime _getLastDate() {
  final DateTime now = DateTime.now();
  return DateTime(now.year - 16, now.month, now.day, 23, 59, 59, 0, 0);
}

DateTime _getDefaultDate() {
  final DateTime ref = _getLastDate();
  return DateTime(ref.year, ref.month, ref.day - 1, 0, 0, 0, 0, 0);
}

class AnimatedPasswordTextFormField extends StatefulWidget {
  const AnimatedPasswordTextFormField({
    Key? key,
    this.interval = const Interval(0.0, 1.0),
    required this.animatedWidth,
    this.loadingController,
    this.inertiaController,
    this.inertiaDirection,
    this.enabled = true,
    this.labelText,
    this.keyboardType,
    this.textInputAction,
    this.controller,
    this.focusNode,
    this.validator,
    this.onFieldSubmitted,
    this.onSaved,
    this.autofillHints,
  })  : assert((inertiaController == null && inertiaDirection == null) ||
            (inertiaController != null && inertiaDirection != null)),
        super(key: key);

  final Interval? interval;
  final AnimationController? loadingController;
  final AnimationController? inertiaController;
  final double animatedWidth;
  final bool enabled;
  final String? labelText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onFieldSubmitted;
  final FormFieldSetter<String>? onSaved;
  final TextFieldInertiaDirection? inertiaDirection;
  final Iterable<String>? autofillHints;

  @override
  _AnimatedPasswordTextFormFieldState createState() =>
      _AnimatedPasswordTextFormFieldState();
}

class _AnimatedPasswordTextFormFieldState
    extends State<AnimatedPasswordTextFormField> {
  var _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return AnimatedTextFormField(
      interval: widget.interval,
      loadingController: widget.loadingController,
      inertiaController: widget.inertiaController,
      width: widget.animatedWidth,
      enabled: widget.enabled,
      autofillHints: widget.autofillHints,
      labelText: widget.labelText,
      prefixIcon: const Icon(FontAwesomeIcons.lock, size: 20),
      suffixIcon: GestureDetector(
        onTap: () => setState(() => _obscureText = !_obscureText),
        dragStartBehavior: DragStartBehavior.down,
        child: AnimatedCrossFade(
          duration: const Duration(milliseconds: 250),
          firstCurve: Curves.easeInOutSine,
          secondCurve: Curves.easeInOutSine,
          alignment: Alignment.center,
          layoutBuilder: (Widget topChild, _, Widget bottomChild, __) {
            return Stack(
              alignment: Alignment.center,
              children: <Widget>[bottomChild, topChild],
            );
          },
          firstChild: const Icon(
            Icons.visibility,
            size: 25.0,
            semanticLabel: 'show password',
          ),
          secondChild: const Icon(
            Icons.visibility_off,
            size: 25.0,
            semanticLabel: 'hide password',
          ),
          crossFadeState: _obscureText
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
        ),
      ),
      obscureText: _obscureText,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      controller: widget.controller,
      focusNode: widget.focusNode,
      validator: widget.validator,
      onFieldSubmitted: widget.onFieldSubmitted,
      onSaved: widget.onSaved,
      inertiaDirection: widget.inertiaDirection,
    );
  }
}
