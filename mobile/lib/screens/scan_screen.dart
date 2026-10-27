import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/results.dart';
import '../services/app_state.dart';
import '../widgets/disclaimer_footer.dart';
import '../widgets/layout.dart';
import '../widgets/mic_button.dart';
import '../widgets/settings_action.dart';
import '../widgets/tr.dart';
import 'result_screen.dart';

/// Take a photo of a document (or pick a PDF or Word file), optionally ask about it by text or voice,
/// and get one result: what it is, red flags linked to the law, what is missing, and citations.
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

enum _Source { camera, photos, files }

class _ScanScreenState extends State<ScanScreen> {
  // The current host refuses uploads over about 4.5 MB.
  static const _maxBytes = 4 * 1024 * 1024;
  static const _mimeTypes = {
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'webp': 'image/webp',
    'heic': 'image/heic',
    'pdf': 'application/pdf',
    'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  };

  final _picker = ImagePicker();
  final _question = TextEditingController();
  Uint8List? _bytes;
  String? _mime;
  String? _name;
  String? _heard;

  @override
  void dispose() {
    _question.dispose();
    super.dispose();
  }

  Future<void> _choose() async {
    final source = await showModalBottomSheet<_Source>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(sheet.tr('Camera')),
              subtitle: Text(sheet.tr('Take a photo of the page')),
              onTap: () => Navigator.pop(sheet, _Source.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(sheet.tr('Photos')),
              subtitle: Text(sheet.tr('Choose a photo you already took')),
              onTap: () => Navigator.pop(sheet, _Source.photos),
            ),
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: Text(sheet.tr('Files')),
              subtitle: Text(sheet.tr('A PDF or Word (.docx) file')),
              onTap: () => Navigator.pop(sheet, _Source.files),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    switch (source) {
      case _Source.camera:
        await _pickPhoto(ImageSource.camera);
      case _Source.photos:
        await _pickPhoto(ImageSource.gallery);
      case _Source.files:
        await _pickFile();
      case null:
        break;
    }
  }

  Future<void> _pickPhoto(ImageSource source) async {
    // Shrunk on the phone to about 1600px on the long side, which Gemma reads well and uploads fast.
    final image = await _picker.pickImage(source: source, maxWidth: 1600, maxHeight: 1600, imageQuality: 82);
    if (image != null) _setFile(await image.readAsBytes(), image.name);
  }

  Future<void> _pickFile() async {
    final result =
        await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'docx'], withData: true);
    final file = result?.files.single;
    if (file?.bytes != null) _setFile(file!.bytes!, file.name);
  }

  void _setFile(Uint8List bytes, String name) {
    final app = context.read<AppState>();
    final ext = name.split('.').last.toLowerCase();
    final mime = _mimeTypes[ext];
    if (mime == null) {
      _say(app.t('Please choose a photo, a PDF or a Word (.docx) file.'));
      return;
    }
    if (bytes.length > _maxBytes) {
      _say(app.t('This file is too large. Please take a photo of the page instead.'));
      return;
    }
    setState(() {
      _bytes = bytes;
      _mime = mime;
      _name = name;
    });
  }

  void _say(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

  void _analyze() {
    final app = context.read<AppState>();
    final bytes = _bytes!;
    final name = _name!;
    final mime = _mime!;
    final question = _question.text.trim();
    final heard = _heard != null && _heard == question ? _heard : null;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResultScreen(
          isScan: true,
          firstRequest: () async {
            final result = await app.api.analyze(
              bytes: bytes,
              fileName: name,
              mimeType: mime,
              language: app.language.code,
              question: question.isEmpty ? null : question,
            );
            return Turn.scan(question: question, scan: result, heard: heard);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isImage = _mime?.startsWith('image/') ?? false;
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Scan')), actions: const [AppBarActions()]),
      body: PageBody(
        maxWidth: 720,
        children: [
          Text(context.tr('Check a document'), style: theme.textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            context.tr('A notice to leave, a contract, a dismissal letter, a land agreement...'),
            style: theme.textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          if (_bytes == null)
            Card.outlined(
              margin: EdgeInsets.zero,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: _choose,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
                  child: Column(
                    children: [
                      ExcludeSemantics(child: Icon(Icons.document_scanner_outlined, size: 56, color: scheme.primary)),
                      const SizedBox(height: kGap),
                      Text(context.tr('No document chosen yet'), style: theme.textTheme.bodyLarge),
                      const SizedBox(height: kGap),
                      FilledButton.icon(
                        onPressed: _choose,
                        icon: const Icon(Icons.add_a_photo_outlined),
                        label: Text(context.tr('Choose document')),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Card.outlined(
              margin: EdgeInsets.zero,
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (isImage)
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 320),
                      child: ColoredBox(
                        color: scheme.surfaceContainerHighest,
                        child: Image.memory(_bytes!, fit: BoxFit.contain, semanticLabel: context.tr('Your document')),
                      ),
                    ),
                  ListTile(
                    leading: Icon(isImage ? Icons.image_outlined : Icons.description_outlined),
                    title: Text(_name ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: OutlinedButton(onPressed: _choose, child: Text(context.tr('Change'))),
                  ),
                ],
              ),
            ),
          SectionTitle(context.tr('Your question (optional)')),
          TextField(
            controller: _question,
            minLines: 2,
            maxLines: 4,
            maxLength: 1000,
            decoration: InputDecoration(hintText: context.tr('For example: Is this allowed?')),
          ),
          if (_heard != null && _heard == _question.text)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(context.tr('We heard this. You can correct it before you continue.'),
                  style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
            ),
          MicButton(
            onText: (text) => setState(() {
              _heard = text;
              _question.text = text;
            }),
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: _bytes == null ? null : _analyze,
              icon: const Icon(Icons.gavel),
              label: Text(context.tr('Explain this document')),
            ),
          ),
          const DisclaimerFooter(),
        ],
      ),
    );
  }
}
