/// A Flutter widget that displays a network image with an organic BlurHash
/// placeholder that dissolves away once the real image has loaded.
///
/// ## Quick start
///
/// ```dart
/// import 'package:hashed_image/hashed_image.dart';
///
/// ImageWithHash(
///   imageUrl: 'https://example.com/photo.jpg',
///   imageHash: 'LEHV6nWB2yk8pyo0adR*.7kCMdnj',
/// )
/// ```
///
/// ## Managing animations in lists
///
/// When you rebuild a list (e.g. pull-to-refresh), call
/// [DecayPermits.reset] first so queued animations don't fire on stale
/// widgets:
///
/// ```dart
/// void _onRefresh() {
///   DecayPermits.reset();
///   setState(() => _items = fetchNewItems());
/// }
/// ```
library hashed_image;

export 'src/image_with_hash.dart';
export 'src/decay_permits.dart' show DecayPermits;
