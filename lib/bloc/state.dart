// classe abstraite qui représente l'état général du Bloc.
abstract class CompteurState {
  int tickets = 0;
  CompteurState(this.tickets);
}

// Cette classe représente l'état initial du Bloc.
class InitialisationCompteurState extends CompteurState {
  InitialisationCompteurState(super.tickets);
}

// Cette classe représente l'état mis à jour du Bloc.
class UpdatedCompteurState extends CompteurState {
  UpdatedCompteurState(super.tickets);
}
