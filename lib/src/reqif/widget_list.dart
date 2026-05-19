// Copyright 2023, domohuhn.
// SPDX-License-Identifier: BSD-3-Clause
// See LICENSE for the full text of the license

import 'package:flutter/material.dart';
import 'package:collection/collection.dart';


class WidgetList extends StatelessWidget {
  final List<Widget> children;
  final bool isOrdered;

  const WidgetList(this.children, {super.key, this.isOrdered = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children.mapIndexed((idx,widget) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                getLeadingText(idx,widget)
              ),
              const SizedBox(
                width: 5,
              ),
              Expanded(
                child: widget,
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  String getLeadingText(int index, dynamic widget) {
    if (widget is WidgetList) {
      return '';
    }
    if(isOrdered) {
      return '${index+1}.';
    }
    return '\u2022';
  }
}
