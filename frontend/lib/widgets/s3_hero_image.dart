import 'package:flutter/material.dart';
import '../core/photography/photography_repository.dart';

/// A hero image widget that displays photography according to S3 specifications.
/// It uses the asset metadata to align the focal point and adjusts the crop
/// based on screen size: 9:16 for mobile (width < 600), 16:9 for desktop.
class S3HeroImage extends StatefulWidget {
  final String assetId;

  const S3HeroImage({
    Key? key,
    required this.assetId,
  }) : super(key: key);

  @override
  State<S3HeroImage> createState() => _S3HeroImageState();
}

class _S3HeroImageState extends State<S3HeroImage> {
  late final PhotographyRepository _repo = PhotographyRepository();
  Map<String, dynamic>? _assetData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAssetData();
  }

  Future<void> _loadAssetData() async {
    try {
      final data = await _repo.getAssetData(widget.assetId);
      if (!mounted) return;
      setState(() {
        _assetData = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const AspectRatio(
        aspectRatio: 9 / 16,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return AspectRatio(
        aspectRatio: 9 / 16,
        child: Center(
          child: Text(
            'Error loading image: $_error',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      );
    }

    if (_assetData == null) {
      return AspectRatio(
        aspectRatio: 9 / 16,
        child: Center(
          child: Text(
            'Asset not found: ${widget.assetId}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      );
    }

    final focalX = (_assetData!['focal_point']?['x'] ?? 0.5) as double;
    final focalY = (_assetData!['focal_point']?['y'] ?? 0.5) as double;

    // Determine aspect ratio based on screen width
    return LayoutBuilder(
      builder: (context, constraints) {
        final double aspectRatio;
        if (constraints.maxWidth < 600) {
          // Mobile: 9:16
          aspectRatio = 9 / 16;
        } else {
          // Desktop: 16:9
          aspectRatio = 16 / 9;
        }

        return AspectRatio(
          aspectRatio: aspectRatio,
          child: Image.asset(
            _assetData!['path'] as String,
            fit: BoxFit.cover,
            alignment: Alignment(
              focalX * 2 - 1, // Convert [0,1] to [-1,1]
              focalY * 2 - 1,
            ),
          ),
        );
      },
    );
  }
}