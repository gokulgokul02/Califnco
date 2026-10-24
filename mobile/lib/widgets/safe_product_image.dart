import 'dart:convert';
import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class SafeProductImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const SafeProductImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
  });

  Widget _buildFallback() {
    return Container(
      width: width,
      height: height,
      color: const Color(0xfff0f2f5),
      alignment: Alignment.center,
      child: Icon(
        Icons.inventory_2_outlined,
        size: (width != null && width! < 60) ? 22 : 36,
        color: Colors.grey.shade400,
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: const Color(0xffe9edf0),
      alignment: Alignment.center,
      child: Icon(
        Icons.image_outlined,
        size: (width != null && width! < 60) ? 22 : 36,
        color: Colors.grey.shade400,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    final trimmed = imageUrl.trim();

    if (trimmed.isEmpty) {
      content = _buildFallback();
    } else if (trimmed.startsWith('data:image')) {
      // Base64 Data URL uploaded manually from Admin Console
      try {
        final commaIdx = trimmed.indexOf(',');
        final base64Str = commaIdx != -1 ? trimmed.substring(commaIdx + 1) : trimmed;
        final Uint8List bytes = base64Decode(base64Str.replaceAll(RegExp(r'\s+'), ''));
        content = Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, __, ___) => _buildFallback(),
        );
      } catch (e) {
        content = _buildFallback();
      }
    } else if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      // Remote HTTP/HTTPS URL
      content = CachedNetworkImage(
        imageUrl: trimmed,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => _buildPlaceholder(),
        errorWidget: (context, url, error) => _buildFallback(),
      );
    } else {
      content = _buildFallback();
    }

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: content);
    }
    return content;
  }
}
