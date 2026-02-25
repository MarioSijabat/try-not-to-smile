import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceDetectorPainter extends CustomPainter {
  final List<Face> faces;
  final Size absoluteImageSize;
  final InputImageRotation rotation;

  FaceDetectorPainter(this.faces, this.absoluteImageSize, this.rotation);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = Colors.green;

    for (final Face face in faces) {
      final Rect boundingBox = face.boundingBox;

      // Handle rotation: If portrait (90 or 270 degrees), swap width and height of raw image
      final bool isPortrait = rotation == InputImageRotation.rotation90deg || 
                              rotation == InputImageRotation.rotation270deg;

      final double imageWidth = isPortrait ? absoluteImageSize.height : absoluteImageSize.width;
      final double imageHeight = isPortrait ? absoluteImageSize.width : absoluteImageSize.height;

      // 1. Coordinate Transformation: Calculate scale factors
      final double scaleX = size.width / imageWidth;
      final double scaleY = size.height / imageHeight;

      // 2. Mirroring (Crucial for selfie camera): Flip the X-axis mapping.
      // Left and right are reversed and scaled to the view bounds.
      final double left = size.width - (boundingBox.right * scaleX);
      final double right = size.width - (boundingBox.left * scaleX);
      
      // Y-axis scales normally
      final double top = boundingBox.top * scaleY;
      final double bottom = boundingBox.bottom * scaleY;

      // Draw the mapped and scaled green bounding box
      canvas.drawRect(
        Rect.fromLTRB(left, top, right, bottom),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(FaceDetectorPainter oldDelegate) {
    // Only repaint if the faces, image size, or rotation changes
    return oldDelegate.absoluteImageSize != absoluteImageSize ||
           oldDelegate.faces != faces ||
           oldDelegate.rotation != rotation;
  }
}
