import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Reproductor de video de fondo optimizado
/// Soporta reproducción sin loop, pause en último frame y fallback instantáneo a imagen estática.
class BackgroundVideoPlayer extends StatefulWidget {
  final String assetPath;
  final String fallbackImagePath;
  final double overlayOpacity;
  final bool loop;
  final bool initialMuted;

  const BackgroundVideoPlayer({
    super.key,
    required this.assetPath,
    required this.fallbackImagePath,
    this.overlayOpacity = 0.35,
    this.loop = false,
    this.initialMuted = false,
  });

  @override
  State<BackgroundVideoPlayer> createState() => _BackgroundVideoPlayerState();
}

class _BackgroundVideoPlayerState extends State<BackgroundVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  late bool _isMuted;

  @override
  void initState() {
    super.initState();
    _isMuted = widget.initialMuted;
    _controller = VideoPlayerController.asset(widget.assetPath)
      ..initialize().then((_) {
        if (mounted) {
          _controller.setLooping(widget.loop);
          _controller.setVolume(_isMuted ? 0.0 : 1.0);
          _controller.play();
          setState(() {
            _isInitialized = true;
          });
        }
      }).catchError((err) {
        debugPrint('⚠️ Error inicializando video de fondo: $err');
      });
  }

  void _toggleAudio() {
    if (!_isInitialized) return;
    setState(() {
      _isMuted = !_isMuted;
      _controller.setVolume(_isMuted ? 0.0 : 1.0);
      if (!_controller.value.isPlaying) {
        _controller.play();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Capa de video (o fallback a imagen mientras inicializa o en caso de error)
        if (_isInitialized && _controller.value.isInitialized)
          FittedBox(
            fit: BoxFit.cover,
            clipBehavior: Clip.hardEdge,
            child: SizedBox(
              width: _controller.value.size.width,
              height: _controller.value.size.height,
              child: VideoPlayer(_controller),
            ),
          )
        else
          Image.asset(
            widget.fallbackImagePath,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),

        // Capa de oscurecimiento suave para legibilidad de textos y botones
        Container(
          color: Colors.black.withValues(alpha: widget.overlayOpacity),
        ),

        // Botón elegante flotante de control de audio (Mute / Unmute)
        if (_isInitialized)
          Positioned(
            top: 16,
            right: 16,
            child: SafeArea(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _toggleAudio,
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFC5A052).withValues(alpha: 0.6),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                          color: const Color(0xFFC5A052),
                          size: 16,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _isMuted ? 'Activar Audio' : 'Silenciar',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
