// tickets_event.dart

abstract class TicketsEvent {}

class FetchTickets extends TicketsEvent {
  final String date;

  FetchTickets(this.date);
}
