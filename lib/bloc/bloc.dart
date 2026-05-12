import 'package:bloc/bloc.dart';
import 'package:mvst/bloc/event.dart';
import 'package:mvst/bloc/state.dart';

// Bloc<EventCompteur, CompteurState> signifie que BlocCompteur
//prend EventCompteur comme type d'événement et CompteurState
//comme type d'état.
class BlocCompteur extends Bloc<EventCompteur, CompteurState> {
  // Constructeur de la classe BlocCompteur.
  // InitialisationCompteurState(0) est l'état initial du Bloc.
  BlocCompteur() : super(InitialisationCompteurState(0)) {
    // Chaque fois qu'un EventIncrement est émis,
    //le Bloc émet un UpdatedCompteurState avec la valeur
    //de panier incrémentée de 1.
    on<EventIcrement>((event, emit) {
      emit(UpdatedCompteurState(state.tickets + 1));
    });

    // Chaque fois qu'un EventDecrement est émis,
    //le Bloc émet un UpdatedCompteurState
    //avec la valeur de panier décrémentée de 1.
    on<EventDecrement>((event, emit) {
      if (state.tickets > 0) emit(UpdatedCompteurState(state.tickets - 1));
    });

    // Chaque fois qu'un EventInitialise est émis, le Bloc
    //émet un InitialisationCompteurState avec
    //la valeur de panier réinitialisée à 0.
    on<EventInitialise>((event, emit) {
      emit(InitialisationCompteurState(0));
    });
    // Ajout de la gestion de l'événement EventListeNumero
  }
}
