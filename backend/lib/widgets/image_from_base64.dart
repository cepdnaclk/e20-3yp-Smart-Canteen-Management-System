import 'dart:convert';
import 'package:flutter/material.dart';

class ImageFromBase64 extends StatelessWidget {
  final String? base64String;
  final BoxFit fit;
  final Widget placeholder;

  const ImageFromBase64({
    super.key,
    required this.base64String,
    this.fit = BoxFit.cover,
    this.placeholder = const Center(child: Icon(Icons.fastfood, color: Colors.grey, size: 40)),
  });

  @override
  Widget build(BuildContext context) {
    if (base64String == null || base64String!.isEmpty) {
      return placeholder;
    }

    try {
      // The backend sends a "data URI". We must strip the header part.
      // e.g., "data:image/jpeg;base64,iVBORw0K..." -> "iVBORw0K..."
      final String encoded = base64String!.split(',').last;
      final decodedBytes = base64Decode(encoded);

      // Use Image.memory to display the decoded bytes
      return Image.memory(
        decodedBytes,
        fit: fit,
        gaplessPlayback: true,
      );
    } catch (e) {
      // If decoding fails for any reason, show the placeholder
      return placeholder;
    }
  }
}