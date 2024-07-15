import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mvst/models/mesfonctions.dart';

import 'event.dart';
import 'state.dart';

class ListePlaceBloc extends Bloc<ListePlaceEvent, ListePlaceState> {
  ListePlaceBloc() : super(ListePlaceInitial()) {
    on<ChargerListeDesPlaces>(_onLoadPlaces);
  }

  Future<void> _onLoadPlaces(
      ChargerListeDesPlaces event, Emitter<ListePlaceState> emit) async {
    emit(PlaceLoading());
    try {
      // Récupérer les documents de la collection 'tickets' qui correspondent aux critères
      QuerySnapshot<Map<String, dynamic>> ticketsSnapshot =
          await FirebaseFirestore.instance
              .collection('tickets')
              .where('dateDeDepart', isEqualTo: event.dateDeTri)
              .where('heureDeDepart', isEqualTo: event.heureTri)
              .get();

      // Récupérer les sous-collections pour chaque document

      for (var ticketDoc in ticketsSnapshot.docs) {
        var subcollectionSnapshot =
            await ticketDoc.reference.collection('sousCollectionTickets').get();

        // Extraire les 'place' de la sous-collection
        for (var subDoc in subcollectionSnapshot.docs) {
          final data = subDoc.data();
          if (data['place'] != null) {
            listeDesNumeros.add(data['place'] as int);
          }
        }
      }

      emit(ListePlaceChargees(listeDesNumeros));
    } catch (e) {
      emit(PlaceError(e.toString()));
    }
  }
}
