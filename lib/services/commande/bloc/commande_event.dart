import 'package:flutter/material.dart';

@immutable
abstract class ticketsEvent {}

class ErrorEvent extends ticketsEvent {
  final String error;

  ErrorEvent(this.error);
}
