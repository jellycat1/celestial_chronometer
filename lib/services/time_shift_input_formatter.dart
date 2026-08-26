import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TimeShiftInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
      String digits = newValue.text.replaceAll(RegExp(r'\D'), '');

      if (digits.length > 6) {
        digits = digits.substring(digits.length - 6);
      }

      final padded = digits.padLeft(6, '0');

      final hh = padded.substring(0, 2);
      final mm = padded.substring(2, 4);
      final ss = padded.substring(4, 6);

      final formatted = "$hh:$mm:$ss";

      return TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
  }
}