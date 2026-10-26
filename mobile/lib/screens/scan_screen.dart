import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/results.dart';
import '../services/app_state.dart';
import '../widgets/disclaimer_footer.dart';
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
    final isImage = _mime?.startsWith('image/') ?? false;
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Scan')), actions: const [SettingsAction()]),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Text(context.tr('Check a document'), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
              context.tr('A notice to leave, a contract, a dismissal letter, a land agreement...'),
              style: const TextStyle(fontSize: 15, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _pickPhoto(ImageSource.camera),
                    icon: const Icon(Icons.photo_camera),
                    label: Text(context.tr('Take photo')),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickPhoto(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: Text(context.tr('Gallery')),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.upload_file),
              label: Text(context.tr('PDF or Word file')),
            ),
            const SizedBox(height: 16),
            Container(
              height: 240,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black12),
              ),
              clipBehavior: Clip.antiAlias,
              child: _bytes == null
                  ? Center(
                      child: Text(context.tr('No document chosen yet'), style: const TextStyle(color: Colors.black54)),
                    )
                  : isImage
                      ? Image.memory(_bytes!, fit: BoxFit.contain, width: double.infinity)
                      : Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.description, size: 56),
                              const SizedBox(height: 8),
                              Text(_name ?? '', textAlign: TextAlign.center),
                            ],
                          ),
                        ),
            ),
            const SizedBox(height: 20),
            Text(context.tr('Your question (optional)'), style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _question,
              minLines: 2,
              maxLines: 4,
              maxLength: 1000,
              decoration: InputDecoration(
                hintText: context.tr('For example: Is this allowed?'),
                border: const OutlineInputBorder(),
              ),
            ),
            if (_heard != null && _heard == _question.text)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(context.tr('We heard this. You can correct it before you continue.'),
                    style: const TextStyle(fontSize: 14, color: Colors.black54)),
              ),
            MicButton(
              onText: (text) => setState(() {
                _heard = text;
                _question.text = text;
              }),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _bytes == null ? null : _analyze,
              icon: const Icon(Icons.gavel),
              label: Text(context.tr('Check against the law')),
            ),
            const SizedBox(height: 20),
            const DisclaimerFooter(),
          ],
        ),
      ),
    );
  }
}
