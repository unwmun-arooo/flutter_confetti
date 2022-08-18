import 'package:flutter/cupertino.dart';

import 'enums/confetti_controller_state.dart';

class ConfettiController extends ChangeNotifier {
  ConfettiController({this.duration = const Duration(seconds: 30)})
      : assert(!duration.isNegative && duration.inMicroseconds > 0);

  Duration duration;

  ConfettiControllerState _state = ConfettiControllerState.stopped;

  ConfettiControllerState get state => _state;

  void play() {
    _state = ConfettiControllerState.playing;
    notifyListeners();
  }

  void stop() {
    _state = ConfettiControllerState.stopped;
    notifyListeners();
  }
}
