import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mvst/bloc/bloctket/tkevent.dart';
import 'package:mvst/bloc/bloctket/tkstate.dart';

class BlocAjoutListe extends Bloc<EventAjout, AjoutState> {
  StreamSubscription<List<int>>? _ticketsSubscription;

  BlocAjoutListe() : super(InitialisationAjoutState([])) {
    on<EventAjoutListe>(_onAjoutListe);
    on<EventInitialiseListe>(_onInitialiseListe);
  }

  void _onAjoutListe(EventAjoutListe event, Emitter<AjoutState> emit) {
    _ticketsSubscription?.cancel();
    _ticketsSubscription = getTicketsStream().listen(
      (List<int> tickets) {
        emit(UpdatedAjoutState(tickets));
      },
      onError: (error) {
        emit(ErrorAjoutState([], error.toString()));
      },
    );
  }

  void _onInitialiseListe(
      EventInitialiseListe event, Emitter<AjoutState> emit) {
    emit(InitialisationAjoutState([]));
    _ticketsSubscription?.cancel();
    _ticketsSubscription = null;
  }

  Stream<List<int>> getTicketsStream() {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    return _firestore.collection('tickets').snapshots().map((snapshot) =>
        snapshot.docs
            .map((doc) => doc.data()['place'] as int?)
            .where((place) => place != null)
            .map((place) => place!)
            .toList());
  }

  @override
  Future<void> close() {
    _ticketsSubscription?.cancel();
    return super.close();
  }
}


/*
class BlocAjoutListe extends Bloc<EventAjout, AjoutState> {
  BlocAjoutListe() : super(InitialisationAjoutState([])) {
    // Écouter l'événement d'ajout de liste
    on<EventAjoutListe>((event, emit) {
      emit(InitialisationAjoutState(getTicketsStream()));
    });
    // Écouter l'événement d'initialisation de la liste
    on<EventInitialiseListe>((event, emit) {
      emit(UpdatedAjoutState([]));
    });
  }

  // Fonction qui retourne un Stream des places de la collection "tickets"
  Stream<List<int>> getTicketsStream() {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    return _firestore.collection('tickets').snapshots().map((snapshot) =>
        snapshot.docs
            .map((doc) => doc.data()['place'] as int?)
            .where((place) => place != null)
            .map((place) => place!)
            .toList());
  }
}
*/

/*
  void _onAjoutListe(EventAjoutListe event, Emitter<AjoutState> emit) {
    try {
      // Récupérer la liste des places depuis Firestore
      state.places ??= getTicketsStream().listen(
        (List<int> tickets) {
          emit(UpdatedAjoutState(tickets));
        },
        onError: (error) {
          emit(ErrorAjoutState([], error.toString()));
        },
      );
    } catch (error) {
      emit(ErrorAjoutState([], error.toString()));
    }
  }

*/
/*

  @override
  Future<void> close() {
    // Annuler l'abonnement au Stream lors de la fermeture du bloc
    _ticketsSubscription?.cancel();
    return super.close();
  }
  void _onInitialiseListe(
      EventInitialiseListe event, Emitter<AjoutState> emit) {
    // Initialiser l'état avec une liste vide
    emit(InitialisationAjoutState([]));
    _ticketsSubscription?.cancel();
    _ticketsSubscription = null;
  }

*/

/*import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mvst/bloc/bloctket/tkevent.dart';
import 'package:mvst/bloc/bloctket/tkstate.dart';

class BlocAjoutListe extends Bloc<EventAjout, AjoutState> {
  StreamSubscription<List<int>>? _ticketsSubscription;

  BlocAjoutListe() : super(InitialisationAjoutState([])) {
    on<EventAjoutListe>((event, emit) {
      // S'abonner au Stream si ce n'est pas déjà fait
      _ticketsSubscription ??= getTicketsStream().listen(
        (List<int> tickets) => emit(UpdatedAjoutState(tickets)),
        onError: (error) => emit(ErrorAjoutState([], error.toString())),
      );
    });

    on<EventInitialiseListe>((event, emit) {
      // Émettre l'état initial et annuler l'abonnement au Stream
      emit(InitialisationAjoutState([]));
      _ticketsSubscription?.cancel();
      _ticketsSubscription = null;
    });
  }

  @override
  Future<void> close() {
    // Annuler l'abonnement au Stream lors de la fermeture du bloc
    _ticketsSubscription?.cancel();
    return super.close();
  }
}

// Fonction qui retourne un Stream des places de la collection "tickets"
Stream<List<int>> getTicketsStream() {
  return FirebaseFirestore.instance
      .collection('tickets')
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) => doc.data()['place'] as int).toList();
  });
}
*/





/*
// Fonction qui retourne un Stream des places de la collection "tickets"
Stream<List<int>> getTicketsStream() {
  return FirebaseFirestore.instance
      .collection('tickets')
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) => doc.data()['place'] as int).toList();
  });
}

class BlocAjoutListe extends Bloc<EventAjout, AjoutState> {
  StreamSubscription<List<int>>? _ticketsSubscription;

  BlocAjoutListe() : super(InitialisationAjoutState([])) {
    on<EventAjoutListe>((event, emit) async {
      // Annuler l'abonnement précédent s'il existe
      await _ticketsSubscription?.cancel();
      // Écouter le Stream et émettre un nouvel état à chaque mise à jour
      _ticketsSubscription = getTicketsStream().listen((List<int> tickets) {
        emit(UpdatedAjoutState(tickets));
      });
    });

    on<EventInitialiseListe>((event, emit) async {
      emit(InitialisationAjoutState([]));
      // Annuler l'abonnement au Stream lors de la réinitialisation
      await _ticketsSubscription?.cancel();
      _ticketsSubscription = null;
    });
  }

  @override
  Future<void> close() {
    // Annuler l'abonnement au Stream lors de la fermeture du bloc
    _ticketsSubscription?.cancel();
    return super.close();
  }
}
*/

/*


class BlocAjoutListe extends Bloc<EventAjout, AjoutState> {
  late StreamSubscription<List<int>> _ticketsSubscription;

  BlocAjoutListe() : super(InitialisationAjoutState([])) {
    // Ecoute les événements et met à jour l'état en conséquence
    on<EventAjoutListe>((event, emit) {
      // Cet événement semble inutile avec la nouvelle logique du stream
    });

    on<EventInitialiseListe>((event, emit) {
      emit(InitialisationAjoutState([]));
    });

    // S'abonne au stream et met à jour l'état à chaque nouvelle donnée
    _ticketsSubscription = getTicketsStream().listen((places) {
      add(UpdatedListePlaces(places));
    });
  }

  @override
  Future<void> close() {
    _ticketsSubscription.cancel();
    return super.close();
  }
}

// Nouvel événement pour mettre à jour les places
class UpdatedListePlaces extends EventAjout {
  final List<int> places;
  UpdatedListePlaces(this.places);
}




*/




/*
Stream<List<int>> getTicketsStream() {
  return FirebaseFirestore.instance
      .collection('tickets')
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) => doc.data()['value'] as int).toList();
  });
}
*/

/*

class BlocAjoutListe extends Bloc<EventAjout, AjoutState> {
  // Constructeur de la classe BlocAjoutList.
  // InitialisationCompteurState(0) est l'état initial du Bloc.
  BlocAjoutListe() : super(InitialisationAjoutState([])) {
    // Chaque fois qu'un EventAjoutListe est émis,
    //le Bloc émet un UpdatedAjoutState
    on<EventAjoutListe>((event, emit) {
      emit(UpdatedAjoutState(state.places + 1));
    });

    // Chaque fois qu'un EventInitialiseListe est émis, le Bloc
    //émet un InitialisationAjoutState avec
    //une liste vide.
    on<EventInitialiseListe>((event, emit) {
      emit(InitialisationAjoutState([]));
    });
  }
}


 */