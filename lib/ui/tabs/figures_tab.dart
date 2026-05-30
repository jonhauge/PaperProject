import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/asset.dart';
import '../../models/paper.dart';
import '../../state/app_state.dart';
import '../widgets.dart';

/// Manages the paper's graphics. Figures are referenced from markdown via
/// `assets/<fileName>`; here the author uploads the actual image bytes.
class FiguresTab extends StatelessWidget {
  const FiguresTab({required this.paper, super.key});

  final Paper paper;

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    return Stack(
      children: [
        if (paper.assets.isEmpty)
          const EmptyState(
            icon: Icons.image_outlined,
            message: 'No figures yet. Upload an image to reference it from '
                'your markdown.',
          )
        else
          GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            gridDelegate:
                const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 220,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: paper.assets.length,
            itemBuilder: (context, i) =>
                _FigureCard(paper: paper, asset: paper.assets[i]),
          ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            heroTag: 'add-figure',
            onPressed: () => _pick(context, app),
            icon: const Icon(Icons.upload),
            label: const Text('Upload'),
          ),
        ),
      ],
    );
  }

  Future<void> _pick(BuildContext context, AppState app) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final f = result.files.first;
    final bytes = f.bytes;
    if (bytes == null) return;
    await app.addAsset(
      paper,
      Asset(
        id: app.newId(),
        fileName: f.name,
        base64Data: base64Encode(bytes),
      ),
    );
  }
}

class _FigureCard extends StatelessWidget {
  const _FigureCard({required this.paper, required this.asset});

  final Paper paper;
  final Asset asset;

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    Widget image;
    if (asset.base64Data.isNotEmpty) {
      try {
        image = Image.memory(base64Decode(asset.base64Data),
            fit: BoxFit.cover, width: double.infinity);
      } catch (_) {
        image = const Icon(Icons.broken_image_outlined);
      }
    } else {
      image = const Icon(Icons.image_outlined);
    }
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: Container(color: Colors.black12, child: image)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    asset.markdownPath,
                    style: const TextStyle(
                        fontSize: 12, fontFamily: 'monospace'),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                InkWell(
                  onTap: () => app.deleteAsset(paper, asset.id),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.delete_outline, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
