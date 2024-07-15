import 'package:equatable/equatable.dart';

// Classe abstraite représentant les événements du Bloc
abstract class ListePlaceEvent extends Equatable {
  const ListePlaceEvent();

  @override
  List<Object> get props => [];
}

// Événement pour charger les places
class ChargerListeDesPlaces extends ListePlaceEvent {
  final String dateDeTri;
  final String heureTri;

  const ChargerListeDesPlaces(this.dateDeTri, this.heureTri);

  @override
  List<Object> get props => [dateDeTri, heureTri];
}
