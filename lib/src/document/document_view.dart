// Copyright 2023, domohuhn.
// SPDX-License-Identifier: BSD-3-Clause
// See LICENSE for the full text of the license

import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:reqif_editor/src/core/resizable_box.dart';
import 'package:reqif_editor/src/document/document_bottom_bar.dart';
import 'package:reqif_editor/src/document/document_controller.dart';
import 'package:reqif_editor/src/document/document_navigation.dart';
import 'package:reqif_editor/src/document/document_top_bar.dart';
import 'package:reqif_editor/src/document/reqif_spreadsheet.dart';
import 'package:reqif_editor/src/localization/app_localizations.dart';
import 'package:reqif_editor/src/reqif/conversions.dart';

class ReqIfDocumentView extends StatefulWidget {
  static const routeName = '/reqif_editor';
  final DocumentController documentController;

  const ReqIfDocumentView({super.key, required this.documentController});

  @override
  State<ReqIfDocumentView> createState() => _ReqIfDocumentViewState();
}

class _ReqIfDocumentViewState extends State<ReqIfDocumentView> {
  static const double minWidthNavBar = 100;
  double widthNavBar = 350;
  double heightEditor = 350;
  static const double heightNavBar = 40;
  static const double heightFooter = 41;
  static const double widthBorder = 4.0;
  bool navbarIsVisible = true;
  bool filterIsActive = false;
  bool searchIsVisible = false;
  int filterCounter = 0;

  QuillController _controller = QuillController.basic();
  // ignore: unused_field
  late AppLifecycleListener _appLifecycleListener;

  void _exchangeControllerAndText(dynamic value) {
    setState(() {
      _controller.dispose();
      _controller = QuillController.basic();
      if (value != null) {
        final delta = deltaFromReqIfNode(value.node);
        _controller.document = Document.fromDelta(delta);
        _controller.addListener(() {
          final fragment = deltaToXhtml(_controller.document.toDelta());
          if (value.value.toString() != fragment.toString()) {
            value.value = fragment;
            widget.documentController.documentWasModified(
                widget.documentController.visibleDocumentNumber);
          }
        });
        _controller.document.history.clear();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _appLifecycleListener = AppLifecycleListener(
      onExitRequested: () async {
        if (!widget.documentController.modified) {
          return AppExitResponse.exit;
        }
        final response = await _askUnsavedChanges(null);
        return response;
      },
    );
  }

  Future<AppExitResponse> _askUnsavedChanges(int? idx) async {
    bool save = false;
    bool cancel = false;

    Widget quitWithoutSavingButton = TextButton(
      child: Text(AppLocalizations.of(context)!.quitWithoutSaving),
      onPressed: () {
        Navigator.of(context).pop();
      },
    );

    Widget saveExitButton = TextButton(
      child: Text(AppLocalizations.of(context)!.saveAndExit),
      onPressed: () {
        save = true;
        cancel = false;
        Navigator.of(context).pop();
      },
    );

    Widget cancelButton = TextButton(
      child: Text(AppLocalizations.of(context)!.cancel),
      onPressed: () {
        cancel = true;
        Navigator.of(context).pop();
      },
    );

    AlertDialog alert = AlertDialog(
      title: Text(AppLocalizations.of(context)!.unsavedChanges),
      content: Text(AppLocalizations.of(context)!.unsavedChangesText),
      actions: [saveExitButton, quitWithoutSavingButton, cancelButton],
    );

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );

    if (cancel) {
      return AppExitResponse.cancel;
    }
    if (save) {
      if (idx != null) {
        await widget.documentController.save(idx);
      } else {
        await widget.documentController.saveAllModified();
      }
    }
    return AppExitResponse.exit;
  }

  @override
  void dispose() {
    _appLifecycleListener.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _toggleNavBarVisibility() {
    setState(() {
      navbarIsVisible = !navbarIsVisible;
    });
  }

  void _applyFilter() {
    widget.documentController.applyFilter(filterIsActive);
    setState(() {
      filterCounter += 1;
    });
  }

  void _toggleFilterState() {
    setState(() {
      filterIsActive = !filterIsActive;
    });
    _applyFilter();
  }

  void _toggleSearchState() {
    setState(() {
      searchIsVisible = !searchIsVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> centerRow = [];
    if (navbarIsVisible) {
      centerRow.add(
        HorizontalResizableBox(
            width: widthNavBar,
            widthBorder: widthBorder,
            borderColor: Theme.of(context).colorScheme.onSurfaceVariant,
            onHorizontalDragUpdate: (details) {
              setState(() {
                widthNavBar += details.delta.dx;
                widthNavBar = max(widthNavBar, minWidthNavBar);
              });
            },
            child: DocumentNavigation(
              key: ValueKey<int>(filterCounter),
              controller: widget.documentController,
              width: widthNavBar,
            )),
      );
    }
    centerRow.add(_buildTableView(context));

    List<Widget> children = [
      SizedBox(
          height: heightNavBar,
          child: DocumentTopBar(
            controller: _controller,
            navbarIsVisible: navbarIsVisible,
            onNavBarPressed: _toggleNavBarVisibility,
            filterIsVisible: filterIsActive,
            onFilterPressed: _toggleFilterState,
            searchIsVisible: searchIsVisible,
            onSearchPressed: _toggleSearchState,
          )),
      Expanded(
          child: Row(
        children: centerRow,
      )),
    ];
    if (searchIsVisible) {
      children.add(SizedBox(
          height: heightFooter,
          child: DocumentBottomBar(
            controller: widget.documentController,
          )));
    }
    return Column(children: children);
  }

  Widget _buildDecoratedTabBox(BuildContext context, int idx) {
    final theme = Theme.of(context);
    final backgroundColorSelected = theme.colorScheme.secondaryContainer;
    final backgroundColorNormal = theme.colorScheme.onInverseSurface;
    final borderColor = theme.colorScheme.onSecondaryContainer;
    final side = BorderSide(color: borderColor);
    final data = widget.documentController[idx];
    final selected = widget.documentController.visibleDocumentNumber == idx;
    final modified = data.modified;
    final border = Border(
        left: idx == 0 ? BorderSide.none : side,
        right: side,
        top: side,
        bottom: selected ? BorderSide.none : side);
    return Container(
        decoration: BoxDecoration(border: border),
        child: Material(
            color: selected ? backgroundColorSelected : backgroundColorNormal,
            child: InkWell(
                onTap: () {
                  widget.documentController.visibleDocumentNumber = idx;
                },
                splashColor: theme.colorScheme.primary,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Padding(
                      padding: const EdgeInsets.fromLTRB(6, 0, 0, 0),
                      child: Text(data.flatDocument.title,
                          style: theme.textTheme.bodySmall)),
                  Padding(
                      padding: const EdgeInsets.fromLTRB(2, 0, 2, 0),
                      child: IconButton(
                        tooltip: AppLocalizations.of(context)!.close,
                        icon: Icon(
                          modified ? Icons.circle : Icons.clear_outlined,
                          size: 16,
                          color:
                              modified ? theme.colorScheme.error : borderColor,
                        ),
                        onPressed: () async {
                          if (data.modified) {
                            final answer = await _askUnsavedChanges(idx);
                            if (answer == AppExitResponse.cancel) {
                              return;
                            }
                          }
                          widget.documentController.closeDocument(idx);
                          if (widget.documentController.length == 0 &&
                              context.mounted) {
                            // return to default page
                            Navigator.of(context).popAndPushNamed("lastUsed");
                          }
                        },
                      ))
                ]))));
  }

  Widget _buildTableView(BuildContext context) {
    List<Widget> buttons = [];
    for (int i = 0; i < widget.documentController.length; ++i) {
      buttons.add(_buildDecoratedTabBox(context, i));
    }

    return Expanded(
        child: Column(children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: buttons,
      ),
      Expanded(
          child: ReqIfSpreadSheet(
              controller: widget.documentController,
              editorController: _controller,
              onNewQuillEditor: _exchangeControllerAndText,
              filterIsEnabled: filterIsActive,
              onNewFilterValue: _applyFilter,
              searchIsEnabled: searchIsVisible))
    ]));
  }
}
