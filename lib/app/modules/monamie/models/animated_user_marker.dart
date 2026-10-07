import 'package:monamie_app/app/modules/monamie/models/user_model.dart';
import 'package:latlong2/latlong.dart';

/// Representa um usuário com sua posição animada para renderização suave.
/// 
/// Esta classe encapsula um UserModel e fornece interpolação suave
/// entre posições anteriores e novas.
class AnimatedUserMarker {
  final UserModel user;
  late LatLng _currentRenderedPosition;
  late LatLng _targetPosition;
  double _animationProgress = 1.0; // Varia de 0 a 1

  AnimatedUserMarker({required this.user}) {
    _currentRenderedPosition = LatLng(user.lat ?? 0.0, user.lng ?? 0.0);
    _targetPosition = _currentRenderedPosition;
  }

  /// Obtém a posição atual renderizada (interpolada).
  LatLng get renderedPosition => _currentRenderedPosition;

  /// Obtém a posição alvo.
  LatLng get targetPosition => _targetPosition;

  /// Atualiza a posição alvo do usuário e inicia a animação.
  /// Se a posição mudou, retorna true.
  bool updateTargetPosition(double lat, double lng) {
    final newPosition = LatLng(lat, lng);
    
    if (_targetPosition != newPosition) {
      _currentRenderedPosition = _targetPosition;
      _targetPosition = newPosition;
      _animationProgress = 0.0;
      return true; // Indica que a posição foi atualizada
    }
    return false; // Posição não mudou
  }

  /// Define a posição IMEDIATAMENTE sem animação.
  /// Útil para trocas de dia onde a transição deve ser abrupta.
  void setPositionImmediate(double lat, double lng) {
    final newPosition = LatLng(lat, lng);
    _currentRenderedPosition = newPosition;
    _targetPosition = newPosition;
    _animationProgress = 1.0; // Completa imediatamente
  }

  /// Atualiza o progresso da animação (0.0 a 1.0).
  /// Retorna a posição interpolada.
  LatLng updateAnimationProgress(double progress) {
    _animationProgress = progress.clamp(0.0, 1.0);
    
    // Interpolação linear entre a posição anterior e a alvo
    final lat = _currentRenderedPosition.latitude +
        (_targetPosition.latitude - _currentRenderedPosition.latitude) *
            _animationProgress;
    final lng = _currentRenderedPosition.longitude +
        (_targetPosition.longitude - _currentRenderedPosition.longitude) *
            _animationProgress;
    
    return LatLng(lat, lng);
  }

  /// Retorna se a animação ainda está em progresso.
  bool get isAnimating => _animationProgress < 1.0;
}
