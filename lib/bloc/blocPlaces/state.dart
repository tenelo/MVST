import 'package:equatable/equatable.dart';

// Classe abstraite représentant l'état du Bloc
abstract class ListePlaceState extends Equatable {
  const ListePlaceState();

  @override
  List<Object> get props => [];
}

// État initial du Bloc
class ListePlaceInitial extends ListePlaceState {}

// État lors du chargement des places
class PlaceLoading extends ListePlaceState {}

// État lorsque les places sont chargées
class ListePlaceChargees extends ListePlaceState {
  final List<int> places;

  const ListePlaceChargees(this.places);

  @override
  List<Object> get props => [places];
}

// État lors d'une erreur
class PlaceError extends ListePlaceState {
  final String message;

  const PlaceError(this.message);

  @override
  List<Object> get props => [message];
}
