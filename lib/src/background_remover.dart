import 'dart:io';

import 'package:apple_vision_selfie/apple_vision_selfie.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:google_mlkit_selfie_segmentation/google_mlkit_selfie_segmentation.dart';
import 'package:image/image.dart' as img;

class FlutterBackgroundRemover {
  // Private constructor to prevent instantiation of the class
  FlutterBackgroundRemover._();

  // Apple Vision Selfie controller for macOS
  static final AppleVisionSelfieController visionController =
      AppleVisionSelfieController();

  // Google ML Kit Selfie Segmentation for Android and iOS
  static final SelfieSegmenter _segmenter = SelfieSegmenter(
    mode: SegmenterMode.single,
    enableRawSizeMask: true,
  );

  // Asynchronous method to remove background from an image file
  static Future<Uint8List> removeBackground(File file) async {
    final inputImage = InputImage.fromFile(file);

    // Read image bytes in a separate isolate
    final Uint8List bytes = await compute(_getBytes, file);

    // Decode image size from bytes
    final size = await decodeImageFromList(bytes);
    final Uint8List image = bytes;

    // Check the platform and call the appropriate background removal method
    if (Platform.isMacOS) {
      return await _removeBackgroundMacOS(image,
          size: Size(size.width.toDouble(), size.height.toDouble()));
    } else if (Platform.isAndroid || Platform.isIOS) {
      return await _mobileRemovebackground(inputImage,
          orignalImage: image, width: size.width, height: size.height);
    } else {
      throw UnimplementedError("Unsupported platform");
    }
  }

  // Helper method to read bytes from a file
  static Future<Uint8List> _getBytes(File file) async {
    return await file.readAsBytes();
  }

  // Method to remove background on mobile platforms (Android and iOS)
  static Future<Uint8List> _mobileRemovebackground(InputImage inputImage,
      {required Uint8List orignalImage,
      required int width,
      required int height}) async {
    try {
      final mask = await _segmenter.processImage(inputImage);

      final decodedImage = await removeBackgroundFromImage(
          image: img.decodeImage(orignalImage)!,
          segmentationMask: mask!,
          width: width,
          height: height);

      return Uint8List.fromList(img.encodePng(decodedImage));
    } catch (e) {
      throw Exception("Image Cannot Remove Background");
    }
  }

  // Method to remove background on macOS using Apple Vision
  static Future<Uint8List> _removeBackgroundMacOS(Uint8List inputImage,
      {required Size size}) async {
    try {
      final value = await visionController.processImage(SelfieSegmentationData(
        image: inputImage,
        imageSize: size,
        format: PictureFormat.png,
        quality: SelfieQuality.accurate,
      ));

      if (value != null && value[0] != null) {
        return value[0]!;
      } else {
        throw Exception("Image Cannot Remove Background");
      }
    } catch (e) {
      throw Exception("Image Cannot Remove Background");
    }
  }

  // Method to remove background from an image using a segmentation mask
  static Future<img.Image> removeBackgroundFromImage({
    required img.Image image,
    required SegmentationMask segmentationMask,
    required int width,
    required int height,
  }) async {
    return await compute(_removeBackgroundFromImage, {
      'image': image,
      'segmentationMask': segmentationMask,
      'width': width,
      'height': height
    });
  }

  // Helper method to remove background from an image in a separate isolate
  static Future<img.Image> _removeBackgroundFromImage(
      Map<String, dynamic> input) async {
    final img.Image image = input['image'];
    final int height = input['height'];
    final int width = input['width'];
    final SegmentationMask segmentationMask = input['segmentationMask'];

    // Create a new image with the background removed based on the segmentation mask
    final newImage = img.copyResize(image,
        width: segmentationMask.width, height: segmentationMask.height);

    for (int y = 0; y < segmentationMask.height; y++) {
      for (int x = 0; x < segmentationMask.width; x++) {
        final int index = y * segmentationMask.width + x;
        final double bgConfidence =
            ((1.0 - segmentationMask.confidences[index]) * 255)
                .toInt()
                .toDouble();

        // Check if the background confidence is below a threshold (e.g., 100)
        if (bgConfidence >= 100) {
          // If not fully transparent, copy the pixel from the original image
          newImage.setPixel(x, y, img.ColorRgba8(255, 255, 255, 0));
        }
      }
    }

    return img.copyResize(newImage, width: width, height: height);
  }
}
