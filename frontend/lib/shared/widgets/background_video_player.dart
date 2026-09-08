import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Reproductor de video de fondo optimizado
/// Soporta reproducción sin loop, pause en último frame y fallback instantáneo a imagen estática.
class BackgroundVideoPlayer extends StatefulWidget {
  final String assetPath;
  final String fallbackImagePath;
  final double overlayOpacity;
  final bool loop;

  const BackgroundVideoPlayer({
    super.key,
    required this.assetPath,
    required this.fallbackImagePath,
    this.overlayOpacity = 0.35,
    this.loop = false,
  });

  @override
  State<BackgroundVideoPlayer> createState() => _BackgroundVideoPlayerState();
}

class _BackgroundVideoPlayerState extends State<BackgroundVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(widget.assetPath)
      ..initialize().then((_) {
        if (mounted) {
          _controller.setLooping(widget.loop);
          _controller.setVolume(0.0); // Silenciado para cumplir políticas de autoplay
          _controller.play();
          setState(() {
            _isInitialized = true;
          });
        }
      }).catchError((err) {
        debugPrint('⚠️ Error inicializando video de fondo: ');
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
      ],
    );
  }
}
