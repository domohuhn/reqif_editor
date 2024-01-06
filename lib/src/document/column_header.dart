// Copyright 2023, domohuhn.
// SPDX-License-Identifier: BSD-3-Clause
// See LICENSE for the full text of the license

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// Header for a column of the table. Can show text, or text + a textfield to edit the filter.
///
class ColumnHeader extends StatelessWidget {
  final bool showTextInput;
  final String text;
  final TextEditingController controller;
  final void Function(String)? onChanged;
  const ColumnHeader(
      {super.key,
      this.showTextInput = false,
      required this.text,
      required this.controller,
      this.onChanged});

  @override
  Widget build(BuildContext context) {
    final title = Text(text);
    final textTheme = Theme.of(context).textTheme;
    if (showTextInput) {
      final inputBox = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
        child: TextField(
          style: textTheme.bodySmall,
          controller: controller,
          onChanged: (value) {
            if (onChanged != null) {
              onChanged!(value);
            }
          },
          decoration: InputDecoration(
            border: const OutlineInputBorder(gapPadding: 1.0),
            hintText: AppLocalizations.of(context)!.contains,
            labelText: AppLocalizations.of(context)!.contains,
          ),
        ),
      );
      return Column(
          mainAxisSize: MainAxisSize.min, children: [title, inputBox]);
    }
    return Center(
      child: title,
    );
  }
}
