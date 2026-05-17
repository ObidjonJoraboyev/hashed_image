import 'dart:async';
import 'dart:ui' as ui;

import 'package:blurhash_dart/blurhash_dart.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import 'blur_decay_painter.dart';
import 'decay_pattern.dart';
import 'decay_permits.dart';

/// A network image widget that shows a BlurHash placeholder while the real
/// image loads, then dissolves the placeholder away using an organic
/// blob-decay animation.
///
/// ```dart
/// ImageWithHash(
///   imageUrl: 'https://example.com/photo.jpg',
///   imageHash: 'LEHV6nWB2yk8pyo0adR*.7kCMdnj',
/// )
/// ```
///
/// The widget decodes [imageHash] to a 32×32 pixel preview immediately, so
/// the user always sees something — even on a slow connection. Once the first
/// frame of the network image is ready the blur cover dissolves.
///
/// **Concurrent animation throttling** — at most [DecayPermits.maxConcurrent]
/// decay animations run simultaneously across the entire app. Extra widgets
/// queue and animate one-by-one as slots free up. Call [DecayPermits.reset]
/// if you rebuild a whole list so queued animations don't fire on stale items.
class ImageWithHash extends StatefulWidget {
  /// URL of the full-resolution image to load from the network.
  final String imageUrl;

  /// Valid BlurHash string used as the low-resolution placeholder.
  final String imageHash;

  /// How the image is inscribed into the available space. Defaults to
  /// [BoxFit.cover].
  final BoxFit fit;

  /// Optional explicit width. If null the widget expands to fill its parent.
  final double? width;

  /// Optional explicit height. If null the widget expands to fill its parent.
  final double? height;

  /// Duration of the blur-to-real-image decay animation.
  /// Defaults to 850 ms.
  final Duration animationDuration;

  /// Called when the network image fails to load. If null a default broken-
  /// image icon is shown.
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;

  const ImageWithHash({
    super.key,
    required this.imageUrl,
    required this.imageHash,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.animationDuration = const Duration(milliseconds: 850),
    this.errorBuilder,
  });

  @override
  State<ImageWithHash> createState() => _ImageWithHashState();
}

class _ImageWithHashState extends State<ImageWithHash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _decay;
  late final Animation<double> _decayCurved;
  late final DecayPattern _pattern;

  ui.Image? _blurImage;
  bool _blurVisible = true;
  bool _revealing = false;
  bool _holdsPermit = false;
  bool _loadFired = false;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _decay = AnimationController(vsync: this, duration: widget.animationDuration)
      ..addStatusListener(_onStatus);
    _decayCurved =
        CurvedAnimation(parent: _decay, curve: Curves.easeInOutSine);
    _pattern = DecayPattern.generate(
      seed: widget.imageUrl.hashCode ^ widget.imageHash.hashCode,
    );
    _decodeBlur();
  }

  void _onStatus(AnimationStatus s) {
    if (s != AnimationStatus.completed || !mounted) return;
    setState(() {
      _blurVisible = false;
      _revealing = false;
    });
    if (_holdsPermit) {
      _holdsPermit = false;
      DecayPermits.release();
    }
  }

  Future<void> _decodeBlur() async {
    try {
      const int w = 32, h = 32;
      final pixels = BlurHash.decode(widget.imageHash)
          .toImage(w, h)
          .getBytes(order: img.ChannelOrder.rgba);
      final completer = Completer<ui.Image>();
      ui.decodeImageFromPixels(
        pixels,
        w,
        h,
        ui.PixelFormat.rgba8888,
        completer.complete,
      );
      final uiImage = await completer.future;
      if (_disposed) {
        uiImage.dispose();
        return;
      }
      if (mounted) setState(() => _blurImage = uiImage);
    } catch (e) {
      debugPrint('[hashed_image] BlurHash decode failed: $e');
    }
  }

  Future<void> _onImageLoaded() async {
    if (_revealing || !_blurVisible || _disposed) return;
    try {
      await DecayPermits.acquire();
    } catch (_) {
      return; // slot was cancelled (e.g. parent list refreshed / dispose).
    }
    _holdsPermit = true;
    if (_disposed || !mounted || !_blurVisible) {
      _holdsPermit = false;
      DecayPermits.release();
      return;
    }
    setState(() => _revealing = true);
    _decay.forward(from: 0);
  }

  @override
  void dispose() {
    _disposed = true;
    _decay.removeStatusListener(_onStatus);
    _decay.dispose();
    _blurImage?.dispose();
    if (_holdsPermit) {
      _holdsPermit = false;
      DecayPermits.release();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: RepaintBoundary(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              widget.imageUrl,
              fit: widget.fit,
              gaplessPlayback: true,
              frameBuilder:
                  (context, child, frame, wasSynchronouslyLoaded) {
                if (frame != null && !_loadFired) {
                  _loadFired = true;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) _onImageLoaded();
                  });
                }
                return child;
              },
              errorBuilder: widget.errorBuilder ??
                  (_, __, ___) => const ColoredBox(
                        color: Color(0x1F000000),
                        child: Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: Colors.white70,
                          ),
                        ),
                      ),
            ),
            if (_blurVisible && _blurImage != null)
              CustomPaint(
                painter: BlurDecayPainter(
                  blur: _blurImage!,
                  progress: _decayCurved,
                  pattern: _pattern,
                ),
              ),
            if (_blurVisible && _blurImage == null)
              const ColoredBox(color: Color(0x42000000)),
          ],
        ),
      ),
    );
  }
}
