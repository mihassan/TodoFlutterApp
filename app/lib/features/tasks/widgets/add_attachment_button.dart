import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AddAttachmentButton extends StatelessWidget {
  const AddAttachmentButton({
    super.key,
    required this.onFileSelected,
    this.isUploading = false,
  });

  final Function(String filePath) onFileSelected;
  final bool isUploading;

  Future<void> _pickFile(BuildContext context) async {
    final ImagePicker picker = ImagePicker();

    // Show menu to choose between gallery and file picker
    await showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.image),
                title: const Text('Pick from Gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image = await picker.pickImage(
                    source: ImageSource.gallery,
                  );
                  if (image != null) {
                    onFileSelected(image.path);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Take Photo'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image = await picker.pickImage(
                    source: ImageSource.camera,
                  );
                  if (image != null) {
                    onFileSelected(image.path);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: isUploading ? null : () => _pickFile(context),
      icon: isUploading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.attach_file),
      label: Text(isUploading ? 'Uploading...' : 'Add Attachment'),
    );
  }
}
