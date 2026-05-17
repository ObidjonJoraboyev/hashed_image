# hashed_image

<p align="center">
  <img
    src="https://raw.githubusercontent.com/ObidjonJoraboyev/hashed_image/main/doc/demo.gif"
    alt="hashed_image demo"
    width="320"
  />
</p>

A Flutter widget that displays a network image with an organic **BlurHash**
placeholder. The blur dissolves away using a smooth blob-decay animation once
the real image has loaded — no jarring pop-in, no loading spinners.

---

## Features

- Drop-in `ImageWithHash` widget — just pass `imageUrl` and `imageHash`
- Organic blob-decay animation (blobs grow + fade the blur cover away)
- Concurrent animation throttling: at most 2 decay animations run
  simultaneously so a grid of 20+ images won't spike the GPU
- Safe lifecycle management: no zombie animations after dispose
- Built on [`blurhash_dart`](https://pub.dev/packages/blurhash_dart) — pure
  Dart, works on **all platforms** including Web

---

## Getting started

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  hashed_image: ^0.0.1
```

Then run:

```sh
flutter pub get
```

---

## Usage

```dart
import 'package:hashed_image/hashed_image.dart';

// Basic usage — fill a fixed-size box
SizedBox(
  width: 200,
  height: 200,
  child: ImageWithHash(
    imageUrl: 'https://picsum.photos/seed/hello/800/800',
    imageHash: 'LEHV6nWB2yk8pyo0adR*.7kCMdnj',
  ),
),

// Inside a grid card — let the widget expand
Expanded(
  child: ImageWithHash(
    imageUrl: product.imageUrl,
    imageHash: product.blurHash,
    fit: BoxFit.cover,
  ),
),

// Custom error widget
ImageWithHash(
  imageUrl: product.imageUrl,
  imageHash: product.blurHash,
  errorBuilder: (context, error, stackTrace) =>
      const Center(child: Icon(Icons.error)),
),
```

---

## Managing animations in lists

When you refresh a list (e.g. pull-to-refresh), call `DecayPermits.reset()`
**before** rebuilding so queued animations don't fire on stale widgets:

```dart
void _onRefresh() {
  DecayPermits.reset();
  setState(() => _items = fetchNewItems());
}
```

---

## API

### `ImageWithHash`

| Parameter           | Type                                                | Default                          | Description                                      |
|---------------------|-----------------------------------------------------|----------------------------------|--------------------------------------------------|
| `imageUrl`          | `String` (**required**)                             | —                                | URL of the full-resolution network image         |
| `imageHash`         | `String` (**required**)                             | —                                | Valid BlurHash string for the placeholder        |
| `fit`               | `BoxFit`                                            | `BoxFit.cover`                   | How the image is inscribed into the widget       |
| `width`             | `double?`                                           | `null` (expands)                 | Optional explicit width                          |
| `height`            | `double?`                                           | `null` (expands)                 | Optional explicit height                         |
| `animationDuration` | `Duration`                                          | `Duration(milliseconds: 850)`    | Duration of the blur-decay animation             |
| `errorBuilder`      | `Widget Function(BuildContext, Object, StackTrace?)?`| `null` (broken-image icon)       | Widget shown when the network image fails        |

### `DecayPermits`

| Method            | Description                                                       |
|-------------------|-------------------------------------------------------------------|
| `reset()`         | Cancel all queued animations and reset the active count to zero   |
| `maxConcurrent`   | Constant — maximum simultaneous decay animations (default: `2`)   |

---

## Additional information

- BlurHash strings are typically returned by your API alongside the image URL.
  You can generate them server-side using the
  [BlurHash algorithm](https://blurha.sh/).
- This package uses `blurhash_dart` (pure Dart) and works on all Flutter
  platforms: iOS, Android, macOS, Linux, Windows, and **Web**.
- Found a bug or have a feature request? Open an issue on
  [GitHub](https://github.com/ObidjonJoraboyev/hashed_image/issues).
