import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../config/languages.dart';
import 'settings_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({
    super.key,
    required this.language,
    this.onLanguageChanged,
  });

  final LanguageOption language;
  final Future<void> Function(String languageCode)? onLanguageChanged;

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;

  Future<void> _pickImage() async {
    final image = await _picker.pickImage(source: ImageSource.camera);
    if (image == null) return;
    setState(() {
      _selectedImage = image;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SettingsScreen(
                    language: widget.language,
                    onLanguageChanged: widget.onLanguageChanged ?? (_) async {},
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Scan a document',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'Take a photo of an eviction notice, contract, letter or other legal document.',
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: const Text('Take photo'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Document upload flow is ready for the API integration phase.')),
                        );
                      },
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Upload'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (_selectedImage != null)
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selected file: ${_selectedImage!.name}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                File(_selectedImage!.path),
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: const Center(
                      child: Text(
                        'No document selected yet',
                        style: TextStyle(color: Colors.black54),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
