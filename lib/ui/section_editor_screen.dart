import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';

import '../models/asset.dart';
import '../models/paper.dart';
import '../models/section.dart';
import '../state/app_state.dart';

/// Two-mode editor for a markdown section: write or preview. The toolbar lets
/// the author insert a reference to one of the paper's figures.
class SectionEditorScreen extends StatefulWidget {
  const SectionEditorScreen({
    required this.paperId,
    required this.sectionId,
    super.key,
  });

  final String paperId;
  final String sectionId;

  @override
  State<SectionEditorScreen> createState() => _SectionEditorScreenState();
}

class _SectionEditorScreenState extends State<SectionEditorScreen> {
  late TextEditingController _body;
  late TextEditingController _title;
  bool _preview = false;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    final section = _section();
    _body = TextEditingController(text: section?.body ?? '');
    _title = TextEditingController(text: section?.title ?? '');
    _body.addListener(() => _dirty = true);
    _title.addListener(() => _dirty = true);
  }

  @override
  void dispose() {
    _body.dispose();
    _title.dispose();
    super.dispose();
  }

  Paper? _paper() => context.read<AppState>().byId(widget.paperId);

  Section? _section() {
    final p = _paper();
    if (p == null) return null;
    for (final s in p.sections) {
      if (s.id == widget.sectionId) return s;
    }
    return null;
  }

  Future<void> _save() async {
    final app = context.read<AppState>();
    final paper = _paper();
    final section = _section();
    if (paper == null || section == null) return;
    await app.updateSection(
      paper,
      section.copyWith(title: _title.text, body: _body.text),
    );
    _dirty = false;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Section saved')),
      );
    }
  }

  Future<void> _insertFigure() async {
    final paper = _paper();
    if (paper == null) return;
    if (paper.assets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No figures yet — add one in the Figures tab.'),
        ),
      );
      return;
    }
    final asset = await showModalBottomSheet<Asset>(
      context: context,
      builder: (_) => ListView(
        shrinkWrap: true,
        children: paper.assets
            .map((a) => ListTile(
                  leading: const Icon(Icons.image_outlined),
                  title: Text(a.fileName),
                  subtitle: a.caption.isEmpty ? null : Text(a.caption),
                  onTap: () => Navigator.pop(context, a),
                ))
            .toList(),
      ),
    );
    if (asset == null) return;
    final snippet =
        '\n\n![${asset.caption.isEmpty ? asset.fileName : asset.caption}]'
        '(${asset.markdownPath})\n';
    final sel = _body.selection;
    final text = _body.text;
    final pos = sel.isValid ? sel.start : text.length;
    _body.text = text.substring(0, pos) + snippet + text.substring(pos);
    _body.selection =
        TextSelection.collapsed(offset: pos + snippet.length);
    _dirty = true;
  }

  @override
  Widget build(BuildContext context) {
    final paper = _paper();
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _save();
        if (mounted) Navigator.pop(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: TextField(
            controller: _title,
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: 'Section title',
            ),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          actions: [
            IconButton(
              tooltip: _preview ? 'Edit' : 'Preview',
              icon: Icon(_preview ? Icons.edit : Icons.visibility),
              onPressed: () => setState(() => _preview = !_preview),
            ),
            IconButton(
              tooltip: 'Save',
              icon: const Icon(Icons.save),
              onPressed: _save,
            ),
          ],
        ),
        body: _preview
            ? _PreviewView(markdown: _body.text, paper: paper)
            : Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: _body,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  style: const TextStyle(fontFamily: 'monospace', height: 1.4),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Write markdown here…\n\n'
                        '# Heading\n\nText with a [@citation] and a figure.',
                  ),
                ),
              ),
        floatingActionButton: _preview
            ? null
            : FloatingActionButton.extended(
                onPressed: _insertFigure,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: const Text('Figure'),
              ),
      ),
    );
  }
}

/// Renders markdown, resolving `assets/<file>` image links to the paper's
/// inline base64 figure data.
class _PreviewView extends StatelessWidget {
  const _PreviewView({required this.markdown, required this.paper});

  final String markdown;
  final Paper? paper;

  @override
  Widget build(BuildContext context) {
    return Markdown(
      data: markdown,
      padding: const EdgeInsets.all(16),
      imageBuilder: (uri, title, alt) {
        final p = paper;
        if (p == null) return const SizedBox.shrink();
        final name = uri.pathSegments.isNotEmpty
            ? uri.pathSegments.last
            : uri.toString();
        for (final a in p.assets) {
          if (a.fileName == name && a.base64Data.isNotEmpty) {
            try {
              return Image.memory(base64Decode(a.base64Data));
            } catch (_) {
              break;
            }
          }
        }
        return Container(
          padding: const EdgeInsets.all(12),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Text('[figure: $name]'),
        );
      },
    );
  }
}
