import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerWidget extends StatefulWidget {
  final Function(List<XFile>) onImagesSelected;
  final String? initialImagePath;
  final bool allowMultiple;
  final double? width;
  final double? height;

  const ImagePickerWidget({
    super.key,
    required this.onImagesSelected,
    this.initialImagePath,
    this.allowMultiple = false,
    this.width,
    this.height,
  });

  @override
  State<ImagePickerWidget> createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  final ImagePicker _picker = ImagePicker();
  List<XFile> _selectedImages = [];
  String? _currentImagePath;

  @override
  void initState() {
    super.initState();
    if (widget.initialImagePath != null) {
      _currentImagePath = widget.initialImagePath;
    }
  }

  Future<void> _pickImage() async {
    try {
      if (widget.allowMultiple) {
        final List<XFile> images = await _picker.pickMultiImage(
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 85,
        );
        if (images.isNotEmpty) {
          setState(() {
            _selectedImages = images;
            _currentImagePath = images.first.path;
          });
          widget.onImagesSelected(images);
        }
      } else {
        final XFile? image = await _picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 85,
        );
        if (image != null) {
          setState(() {
            _selectedImages = [image];
            _currentImagePath = image.path;
          });
          widget.onImagesSelected([image]);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _selectedImages = [image];
          _currentImagePath = image.path;
        });
        widget.onImagesSelected([image]);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error taking photo: $e')),
      );
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromCamera();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _removeImage() {
    setState(() {
      _selectedImages.clear();
      _currentImagePath = null;
    });
    widget.onImagesSelected([]);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width ?? 120,
      height: widget.height ?? 120,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: _currentImagePath != null
          ? Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(_currentImagePath!),
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: _removeImage,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            )
          : InkWell(
              onTap: _showImageSourceDialog,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_a_photo,
                    size: 32,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add Photo',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
