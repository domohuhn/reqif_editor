// Copyright 2023, domohuhn.
// SPDX-License-Identifier: BSD-3-Clause
// See LICENSE for the full text of the license

import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:reqif_editor/src/localization/app_localizations.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:reqif_editor/src/core/menu_entry.dart';
import 'package:reqif_editor/src/core/open_document.dart';
import 'package:reqif_editor/src/document/document_controller.dart';
import 'package:reqif_editor/src/settings/settings_controller.dart';
import 'package:reqif_editor/src/settings/settings_view.dart';

/// A widget that adds a menu bar on top of the central widget.
class TopMenuBar extends StatefulWidget {
  const TopMenuBar(
      {super.key,
      required this.centralWidget,
      required this.settingsController,
      required this.documentController});

  final DocumentController documentController;
  final SettingsController settingsController;
  final Widget centralWidget;

  @override
  State<TopMenuBar> createState() => _TopMenuBarState();
}

class _TopMenuBarState extends State<TopMenuBar> with OpenDocument<TopMenuBar> {
  ShortcutRegistryEntry? _shortcutsEntry;

  @override
  void dispose() {
    _shortcutsEntry?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    OutlinedBorder getShape(Set<WidgetState> states) {
      return const ContinuousRectangleBorder();
    }

    return Material(
        child: SafeArea(
            child: Column(
      children: <Widget>[
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Expanded(
              child: MenuBar(
                style: MenuStyle(
                  shape: WidgetStateProperty.resolveWith(getShape),
                ),
                children: MenuEntry.build(_getMenus(context)),
              ),
            ),
          ],
        ),
        Expanded(child: widget.centralWidget),
      ],
    )));
  }

  List<MenuEntry> _getMenus(BuildContext context) {
    final List<MenuEntry> lastUsed = <MenuEntry>[];
    for (final f in widget.settingsController.lastOpenedFiles) {
      lastUsed.add(MenuEntry(
        label: f.path,
        onPressed: () {
          if (f.path.isNotEmpty) {
            openPath(widget.documentController, f.path);
          }
        },
      ));
    }
    final List<MenuEntry> result = <MenuEntry>[
      MenuEntry(
        label: AppLocalizations.of(context)!.file,
        menuChildren: <MenuEntry>[
          MenuEntry(
            label: AppLocalizations.of(context)!.openFile,
            onPressed: () {
              FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ["reqif"]).then((value) {
                if (value != null &&
                    value.files.single.path != null &&
                    value.files.single.path!.isNotEmpty) {
                  openPath(widget.documentController, value.files.single.path!);
                }
              });
            },
          ),
          MenuEntry(
              label: AppLocalizations.of(context)!.openRecent,
              menuChildren: lastUsed),
          MenuEntry(
            label: AppLocalizations.of(context)!.save,
            onPressed: () {
              widget.documentController.saveCurrent();
            },
            // ignore: prefer_const_constructors
            shortcut: SingleActivator(LogicalKeyboardKey.keyS,
                control: true), // cannot be const, otherwise rebuild kills app
          ),
          MenuEntry(
            label: AppLocalizations.of(context)!.saveAs,
            onPressed: () {
              FilePicker.platform.saveFile(
                  type: FileType.custom,
                  allowedExtensions: ["reqif"]).then((value) async {
                if (value != null) {
                  widget.documentController.saveCurrent(outputPath: value);
                }
              });
            },
          ),
          MenuEntry(
            label: AppLocalizations.of(context)!.exit,
            onPressed: () async {
              if (Platform.isAndroid) {
                SystemNavigator.pop();
              } else {
                await ServicesBinding.instance
                    .exitApplication(AppExitType.cancelable);
              }
            },
            // ignore: prefer_const_constructors
            shortcut: SingleActivator(LogicalKeyboardKey.keyQ,
                control: true,
                shift: true), // cannot be const, otherwise rebuild kills app
          ),
        ],
      ),
      MenuEntry(
        label: AppLocalizations.of(context)!.settings,
        onPressed: () {
          Navigator.restorablePushNamed(context, SettingsView.routeName);
        },
      ),
      MenuEntry(
        label: AppLocalizations.of(context)!.about,
        onPressed: () {
          showAboutDialog(
            context: context,
            applicationName: AppLocalizations.of(context)!.appTitle,
            applicationVersion: '0.6.4',
          );
        },
      ),
    ];
    // (Re-)register the shortcuts with the ShortcutRegistry so that they are
    // available to the entire application, and update them if they've changed.
    _shortcutsEntry?.dispose();
    _shortcutsEntry =
        ShortcutRegistry.of(context).addAll(MenuEntry.shortcuts(result));
    return result;
  }
}
