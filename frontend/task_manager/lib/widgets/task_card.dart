import 'package:flutter/material.dart';
import '../models/task.dart';
import 'package:intl/intl.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final String searchQuery;

  const TaskCard({
    Key? key,
    required this.task,
    required this.onTap,
    required this.onDelete,
    this.searchQuery = '',
  }) : super(key: key);

  List<TextSpan> _highlightMatches(String text, String query, BuildContext context) {
    if (query.isEmpty) {
      return [TextSpan(text: text)];
    }

    final String lowerText = text.toLowerCase();
    final String lowerQuery = query.toLowerCase();

    final List<TextSpan> spans = [];
    int start = 0;
    int indexOfMatch;

    while ((indexOfMatch = lowerText.indexOf(lowerQuery, start)) != -1) {
      if (indexOfMatch > start) {
        spans.add(TextSpan(text: text.substring(start, indexOfMatch)));
      }
      spans.add(
        TextSpan(
          text: text.substring(indexOfMatch, indexOfMatch + query.length),
          style: TextStyle(
            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            fontWeight: FontWeight.bold,
          ),
        ),
      );
      start = indexOfMatch + query.length;
    }

    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }

    return spans;
  }

  Color _getStatusColor(String status) {
    return switch (status) {
      'To-Do' => Colors.grey.shade600,
      'In Progress' => Colors.blue.shade600,
      'Done' => Colors.green.shade600,
      _ => Colors.grey,
    };
  }

  @override
  Widget build(BuildContext context) {
    final isBlocked = task.isBlocked;

    return Opacity(
      opacity: isBlocked ? 0.5 : 1.0,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: isBlocked ? 0 : 2,
        color: isBlocked ? Colors.grey.shade100 : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: isBlocked ? null : onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isBlocked) ...[
                  const Icon(Icons.lock_outline, color: Colors.grey),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                            decoration: task.status == 'Done' ? TextDecoration.lineThrough : null,
                          ),
                          children: _highlightMatches(task.title, searchQuery, context),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        task.description.isEmpty ? 'No description' : task.description,
                        style: TextStyle(color: Colors.grey.shade700),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            task.dueDate,
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                          ),
                          if (task.isRecurring != null && task.isRecurring!.isNotEmpty) ...[
                            const SizedBox(width: 12),
                            Icon(Icons.repeat, size: 14, color: Colors.blue.shade600),
                            const SizedBox(width: 4),
                            Text(
                              task.isRecurring!,
                              style: TextStyle(color: Colors.blue.shade600, fontSize: 12),
                            ),
                          ],
                        ],
                      ),
                      if (isBlocked && task.blockerTitle != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Blocked by: ${task.blockerTitle}',
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(task.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _getStatusColor(task.status).withOpacity(0.5)),
                      ),
                      child: Text(
                        task.status,
                        style: TextStyle(
                          color: _getStatusColor(task.status),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      onPressed: onDelete,
                      tooltip: 'Delete Task',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
