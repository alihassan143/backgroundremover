# Background Remover

A Flutter package for removing background from images using Apple Vision Selfie on macOS and Google ML Kit Selfie Segmentation on Android and iOS.

## Features

- Cross-platform background removal support (macOS, Android, iOS)
- Efficient background removal using Apple Vision Selfie or Google ML Kit Selfie Segmentation
- Isolate computation for improved performance

## Getting started

Add the following to your `pubspec.yaml` file:


```
dependencies:
  backgroundremover: ^0.0.1
```

## Usage
```
import 'package:background_remover/background_remover.dart';

// Example usage
final File imageFile = ...; // Provide your image file

try {
  final Uint8List result = await BackgroundRemover.removeBackground(imageFile);
  // Use the result as needed, e.g., display it in your Flutter app
} catch (e) {
  print("Error: $e");
}
```

## How Its Works
The package uses Apple Vision Selfie on macOS and Google ML Kit Selfie Segmentation on Android and iOS.
Background removal is achieved by processing an input image and generating a new image with the background removed.

## Contributing
Contributions are welcome! Feel free to open issues or pull requests.

## License
This project is licensed under the MIT License - see the LICENSE file for details.