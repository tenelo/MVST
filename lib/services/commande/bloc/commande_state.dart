import 'package:flutter/material.dart';

@immutable
class ticketsState {
  final String error;

  const ticketsState({
    required this.error,
  });

  static ticketsState get initialState => const ticketsState(
        error: '',
      );

  ticketsState clone({
    String? error,
  }) {
    return ticketsState(
      error: error ?? this.error,
    );
  }
}
