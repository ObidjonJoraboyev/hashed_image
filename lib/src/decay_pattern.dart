import 'dart:math' as math;
import 'package:flutter/painting.dart';

/// Number of vertices around each blob's perimeter.
/// Lower = chunkier / leaf-like. Higher = closer to a circle.
const int kBlobPerimeterPoints = 8;

/// How much each perimeter vertex's radius can vary from the nominal radius.
/// Range [1 - jitter, 1 + jitter].
const double kBlobRadiusJitter = 0.28;

/// One organic decay origin, baked at generation time so the silhouette stays
/// consistent across frames — only the overall radius grows with progress.
class DecayBlob {
  /// Normalized center position ([0,1] on both axes relative to the widget).
  final Offset center;

  /// Maximum radius expressed as a fraction of the widget's diagonal.
  final double maxRadiusFactor;

  /// Per-vertex radius multipliers. Length == [kBlobPerimeterPoints].
  final List<double> radialOffsets;

  /// Initial rotation offset so blobs don't all point the same direction.
  final double rotation;

  const DecayBlob({
    required this.center,
    required this.maxRadiusFactor,
    required this.radialOffsets,
    required this.rotation,
  });
}

/// A set of [DecayBlob]s generated for one widget instance.
class DecayPattern {
  final List<DecayBlob> blobs;

  const DecayPattern._(this.blobs);

  /// Generates well-spread blob origins using Mitchell's best-candidate
  /// sampling so blobs don't cluster in one corner.
  factory DecayPattern.generate({int seed = 0, int count = 6}) {
    final r = math.Random(seed);
    final centers = <Offset>[];
    final blobs = <DecayBlob>[];

    Offset randomPoint() => Offset(
          0.08 + r.nextDouble() * 0.84,
          0.08 + r.nextDouble() * 0.84,
        );

    for (int i = 0; i < count; i++) {
      Offset best;
      if (centers.isEmpty) {
        best = randomPoint();
      } else {
        final numCandidates = math.max(12, centers.length * 4);
        Offset bestCandidate = randomPoint();
        double bestDistance = -1;
        for (int k = 0; k < numCandidates; k++) {
          final candidate = randomPoint();
          double minDist = double.infinity;
          for (final c in centers) {
            final d = (candidate - c).distance;
            if (d < minDist) minDist = d;
          }
          if (minDist > bestDistance) {
            bestDistance = minDist;
            bestCandidate = candidate;
          }
        }
        best = bestCandidate;
      }
      centers.add(best);
      blobs.add(
        DecayBlob(
          center: best,
          maxRadiusFactor: 0.11 + r.nextDouble() * 0.09,
          radialOffsets: List<double>.generate(
            kBlobPerimeterPoints,
            (_) => 1.0 + (r.nextDouble() * 2 - 1) * kBlobRadiusJitter,
          ),
          rotation: r.nextDouble() * 2 * math.pi,
        ),
      );
    }
    return DecayPattern._(blobs);
  }
}
