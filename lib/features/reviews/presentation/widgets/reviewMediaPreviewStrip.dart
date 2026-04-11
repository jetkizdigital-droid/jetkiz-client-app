import 'dart:io';
import 'package:flutter/material.dart';

class ReviewMediaPreviewStrip extends StatelessWidget {
  final List<File> files;

  const ReviewMediaPreviewStrip({
    super.key,
    required this.files,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: files.length,
        itemBuilder: (_, i) {
          return Padding(
            padding: const EdgeInsets.all(4),
            child: Image.file(files[i]),
          );
        },
      ),
    );
  }
}