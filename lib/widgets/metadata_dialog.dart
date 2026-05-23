import 'package:flutter/material.dart';

class MetadataDialog extends StatelessWidget {
  final Map<String, String> metadata;

  const MetadataDialog({super.key, required this.metadata});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.info_outline, color: Colors.indigo),
          SizedBox(width: 8),
          Text('Document Properties'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: metadata.length,
          itemBuilder: (context, index) {
            String key = metadata.keys.elementAt(index);
            String value = metadata[key]!;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    key,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const Divider(),
                ],
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
