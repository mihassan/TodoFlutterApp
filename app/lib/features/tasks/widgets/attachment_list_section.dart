import 'package:flutter/material.dart';

import 'package:todo_flutter_app/domain/entities/attachment.dart';
import 'attachment_tile.dart';

class AttachmentListSection extends StatelessWidget {
  const AttachmentListSection({
    super.key,
    required this.attachments,
    this.onRetry,
    this.onDelete,
  });

  final List<Attachment> attachments;
  final Function(String attachmentId)? onRetry;
  final Function(String attachmentId)? onDelete;

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Text(
          'No attachments',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Attachments',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: attachments.length,
            itemBuilder: (context, index) {
              final attachment = attachments[index];
              return AttachmentTile(
                attachment: attachment,
                onRetry: onRetry != null ? () => onRetry!(attachment.id) : null,
                onDelete: onDelete != null
                    ? () => onDelete!(attachment.id)
                    : null,
              );
            },
          ),
        ],
      ),
    );
  }
}
