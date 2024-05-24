// Copyright 2024, domohuhn.
// SPDX-License-Identifier: BSD-3-Clause
// See LICENSE for the full text of the license

import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class LoadingScreen extends StatelessWidget {
  static const routeName = '/loading';

  const LoadingScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
        child: SafeArea(
            child: Center(
                child: LoadingAnimationWidget.hexagonDots(
      color: theme.colorScheme.primaryFixedDim,
      size: 128,
    ))));
  }
}
