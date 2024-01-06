// Copyright 2023, domohuhn.
// SPDX-License-Identifier: BSD-3-Clause
// See LICENSE for the full text of the license

class ReqIfError implements Exception {
  final dynamic message;

  ReqIfError(this.message);

  @override
  String toString() {
    if (message == null) {
      return "ReqIfError";
    }
    return "ReqIfError: $message";
  }
}
