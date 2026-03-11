import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

class FilePickerWidget extends StatefulWidget {
  final Function(List<PlatformFile>) onFilesSelected;
  final bool allowMultiple;
  final List<String>? allowedExtensions;
  final double? maxSizeMB;

  const FilePickerWidget({
    super.key,
    required this.onFilesSelected,
    this.allowMultiple = true,
    this.allowedExtensions,
    this.maxSizeMB = 10,
  });

  @override
  State<FilePickerWidget> createState() => _FilePickerWidgetState();
}

class _FilePickerWidgetState extends State<FilePickerWidget> {
  final ImagePicker _imagePicker = ImagePicker();

  Future<void> _pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: widget.allowedExtensions != null ? FileType.custom : FileType.any,
        allowedExtensions: widget.allowedExtensions,
        allowMultiple: widget.allowMultiple,
      );

      if (result != null && result.files.isNotEmpty) {
        // Filter valid files
        List<PlatformFile> validFiles = [];

        for (var file in result.files) {
          // Check if file has a path
          if (file.path == null) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${file.name} could not be accessed'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
            continue;
          }

          // Check file size
          if (file.size <= (widget.maxSizeMB! * 1024 * 1024)) {
            validFiles.add(file);
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${file.name} exceeds ${widget.maxSizeMB}MB limit',
                  ),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          }
        }

        if (validFiles.isNotEmpty) {
          widget.onFilesSelected(validFiles);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking files: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );

      if (image != null) {
        final file = File(image.path);
        final fileSize = await file.length();

        // Check file size
        if (fileSize <= (widget.maxSizeMB! * 1024 * 1024)) {
          final platformFile = PlatformFile(
            name: image.name,
            path: image.path,
            size: fileSize,
          );
          widget.onFilesSelected([platformFile]);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Image exceeds ${widget.maxSizeMB}MB limit'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error taking photo: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      if (widget.allowMultiple) {
        final List<XFile> images = await _imagePicker.pickMultiImage(
          maxWidth: 1800,
          maxHeight: 1800,
          imageQuality: 85,
        );

        if (images.isNotEmpty) {
          List<PlatformFile> platformFiles = [];

          for (var image in images) {
            final file = File(image.path);
            final fileSize = await file.length();

            if (fileSize <= (widget.maxSizeMB! * 1024 * 1024)) {
              platformFiles.add(
                PlatformFile(
                  name: image.name,
                  path: image.path,
                  size: fileSize,
                ),
              );
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${image.name} exceeds ${widget.maxSizeMB}MB limit',
                    ),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            }
          }

          if (platformFiles.isNotEmpty) {
            widget.onFilesSelected(platformFiles);
          }
        }
      } else {
        final XFile? image = await _imagePicker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1800,
          maxHeight: 1800,
          imageQuality: 85,
        );

        if (image != null) {
          final file = File(image.path);
          final fileSize = await file.length();

          if (fileSize <= (widget.maxSizeMB! * 1024 * 1024)) {
            final platformFile = PlatformFile(
              name: image.name,
              path: image.path,
              size: fileSize,
            );
            widget.onFilesSelected([platformFile]);
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Image exceeds ${widget.maxSizeMB}MB limit'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting images: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showFileSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Add Attachment',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.folder_outlined, color: Colors.blue),
                ),
                title: const Text('Choose from Files'),
                subtitle: const Text('Documents, images, PDFs'),
                onTap: () {
                  Navigator.pop(context);
                  _pickFiles();
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.photo_library_outlined,
                    color: Colors.purple,
                  ),
                ),
                title: const Text('Choose from Gallery'),
                subtitle: const Text('Select images from gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickFromGallery();
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.camera_alt_outlined,
                    color: Colors.green,
                  ),
                ),
                title: const Text('Take Photo'),
                subtitle: const Text('Use camera to capture'),
                onTap: () {
                  Navigator.pop(context);
                  _pickFromCamera();
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _showFileSourceDialog,
      child: Icon(
        Icons.cloud_upload_outlined,
        size: 48,
        color: Colors.grey[400],
      ),
    );
  }
}
