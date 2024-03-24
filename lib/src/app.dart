// Copyright 2023, domohuhn.
// SPDX-License-Identifier: BSD-3-Clause
// See LICENSE for the full text of the license

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:reqif_editor/src/core/menu_bar.dart';
import 'package:reqif_editor/src/document/document_controller.dart';
import 'package:reqif_editor/src/document/document_view.dart';

import 'package:reqif_editor/src/last_opened/last_opened_list_view.dart';
import 'package:reqif_editor/src/settings/settings_controller.dart';
import 'package:reqif_editor/src/settings/settings_view.dart';

class ReqIfEditorApp extends StatelessWidget {
  final SettingsController settingsController;
  final DocumentController documentController;
  const ReqIfEditorApp({
    super.key,
    required this.settingsController,
    required this.documentController,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
        listenable: documentController,
        builder: (context, child) => ListenableBuilder(
              listenable: settingsController,
              builder: (BuildContext context, Widget? child) {
                return MaterialApp(
                  restorationScopeId: 'app',
                  localizationsDelegates: const [
                    AppLocalizations.delegate,
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],
                  supportedLocales: const [
                    Locale('en', ''),
                    Locale('de', ''),
                  ],
                  onGenerateTitle: (BuildContext context) =>
                      AppLocalizations.of(context)!.appTitle,
                  theme: ThemeData(
                    useMaterial3: true,
                  ),
                  darkTheme: ThemeData.dark(
                    useMaterial3: true,
                  ),
                  themeMode: settingsController.themeMode,
                  onGenerateRoute: (RouteSettings routeSettings) {
                    return MaterialPageRoute<void>(
                      settings: routeSettings,
                      builder: (BuildContext context) {
                        switch (routeSettings.name) {
                          case SettingsView.routeName:
                            return SettingsView(controller: settingsController);
                          case ReqIfDocumentView.routeName:
                            return TopMenuBar(
                                documentController: documentController,
                                settingsController: settingsController,
                                centralWidget: ReqIfDocumentView(
                                    documentController: documentController));
                          case LastOpenedListView.routeName:
                          default:
                            return TopMenuBar(
                                documentController: documentController,
                                settingsController: settingsController,
                                centralWidget: LastOpenedListView(
                                  controller: settingsController,
                                  documentController: documentController,
                                ));
                        }
                      },
                    );
                  },
                );
              },
            ));
  }
}
