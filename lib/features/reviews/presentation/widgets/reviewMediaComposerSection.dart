import 'package:flutter/material.dart';

class ReviewMediaComposerSection extends StatelessWidget {
  final VoidCallback onPickImage;
  final VoidCallback onPickVideo;
  final VoidCallback onPickAudio;

  const ReviewMediaComposerSection({
    super.key,
    required this.onPickImage,
    required this.onPickVideo,
    required this.onPickAudio,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        IconButton(onPressed: onPickImage, icon: const Icon(Icons.camera)),
        IconButton(onPressed: onPickVideo, icon: const Icon(Icons.videocam)),
        IconButton(onPressed: onPickAudio, icon: const Icon(Icons.mic)),
      ],
    );
  }
}
