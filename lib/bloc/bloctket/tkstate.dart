abstract class AjoutState {
  List<int> places = [3];
  AjoutState(this.places);
}

class InitialisationAjoutState extends AjoutState {
  InitialisationAjoutState(List<int> places) : super(places);
}

class UpdatedAjoutState extends AjoutState {
  UpdatedAjoutState(List<int> places) : super(places);
}

class ErrorAjoutState extends AjoutState {
  String message;
  ErrorAjoutState(List<int> places, this.message) : super(places);
}
