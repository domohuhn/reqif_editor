// Copyright 2023, domohuhn.
// SPDX-License-Identifier: BSD-3-Clause
// See LICENSE for the full text of the license

import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:reqif_editor/src/reqif/reqif_common.dart';
import 'settings_controller.dart';

/// Displays the various settings that can be customized by the user.
///
/// When a user changes a setting, the SettingsController is updated and
/// Widgets that listen to the SettingsController are rebuilt.
class SettingsView extends StatelessWidget {
  const SettingsView({super.key, required this.controller});

  static const routeName = '/settings';

  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.settings),
      ),
      body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeadlineText(
                  context, AppLocalizations.of(context)!.generalSettings),
              _buildThemeComboBox(context),
              const Divider(),
              _buildHeadlineText(
                  context, AppLocalizations.of(context)!.settingsSave),
              _buildCheckbox(
                  context,
                  AppLocalizations.of(context)!.settingsSaveUpdateUUID,
                  controller.updateDocumentUUID,
                  controller.updateUpdateDocumentUUID),
              _buildCheckbox(
                  context,
                  AppLocalizations.of(context)!.settingsSaveUpdateTime,
                  controller.updateCreationTime,
                  controller.updateUpdateCreationTime),
              _buildCheckbox(
                  context,
                  AppLocalizations.of(context)!.settingsSaveUpdateTool,
                  controller.updateTool,
                  controller.updateUpdateTool),
              _buildLineEndingsComboBox(context)
            ],
          )),
    );
  }

  Widget _buildHeadlineText(BuildContext context, String text) {
    return Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 6),
        child: Text(
          text,
          textAlign: TextAlign.left,
          style: Theme.of(context).textTheme.headlineSmall,
        ));
  }

  Text _buildBodyText(BuildContext context, String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyLarge,
    );
  }

  Row _buildThemeComboBox(BuildContext context) {
    return Row(children: [
      _buildBodyText(
        context,
        AppLocalizations.of(context)!.themeSelection,
      ),
      const SizedBox(width: 20),
      DropdownButton<ThemeMode>(
        value: controller.themeMode,
        onChanged: controller.updateThemeMode,
        items: [
          DropdownMenuItem(
            value: ThemeMode.system,
            child: Text(AppLocalizations.of(context)!.systemTheme),
          ),
          DropdownMenuItem(
            value: ThemeMode.light,
            child: Text(AppLocalizations.of(context)!.lightTheme),
          ),
          DropdownMenuItem(
            value: ThemeMode.dark,
            child: Text(AppLocalizations.of(context)!.darkTheme),
          )
        ],
      ),
    ]);
  }

  Row _buildLineEndingsComboBox(BuildContext context) {
    return Row(children: [
      _buildBodyText(
        context,
        AppLocalizations.of(context)!.settingsLineEndings,
      ),
      const SizedBox(width: 20),
      DropdownButton<LineEndings>(
        value: controller.lineEndings,
        onChanged: controller.updateLineEndings,
        items: const [
          DropdownMenuItem(
            value: LineEndings.carriageReturnLinefeed,
            child: Text("CRLF"),
          ),
          DropdownMenuItem(
            value: LineEndings.linefeed,
            child: Text("LF"),
          ),
        ],
      ),
    ]);
  }

  Widget _buildCheckbox(BuildContext context, String text, bool value,
      void Function(bool?) onChanged) {
    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Checkbox(
        value: value,
        onChanged: onChanged,
      ),
      const SizedBox(width: 6),
      _buildBodyText(context, text),
    ]);
  }
}
