import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mvst/bloc/bolc_ticket/ticket_event.dart';
import 'package:mvst/bloc/bolc_ticket/ticket_state.dart';

class TicketsBloc extends Bloc<TicketsEvent, TicketsState> {
  TicketsBloc() : super(TicketsInitial()) {
    on<FetchTickets>(_onFetchTickets);
  }

  void _onFetchTickets(FetchTickets event, Emitter<TicketsState> emit) {
    emit(TicketsLoading());

    FirebaseFirestore.instance
        .collection('tickets')
        .where('date', isEqualTo: event.date)
        .snapshots()
        .listen(
      (QuerySnapshot snapshot) {
        List<int> fetchedTickets = snapshot.docs.map((doc) {
          return (doc.data() as Map<String, dynamic>)['place'] as int;
        }).toList();

        emit(TicketsLoaded(fetchedTickets));
      },
      onError: (error) {
        emit(TicketsError('Failed to fetch tickets: $error'));
      },
    );
  }
}
