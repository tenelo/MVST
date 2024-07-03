abstract class TicketsState {}

class TicketsInitial extends TicketsState {}

class TicketsLoading extends TicketsState {}

class TicketsLoaded extends TicketsState {
  final List<int> tickets;
  TicketsLoaded(this.tickets);
}

class TicketsError extends TicketsState {
  final String message;
  TicketsError(this.message);
}
