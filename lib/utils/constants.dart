import 'package:flutter/material.dart';
import '../models/task.dart';

class AppConstants {
  static const String appName = 'TaskFlow';
  static const String dbName = 'taskflow.db';
  static const String tableName = 'tasks';

  static Color priorityColor(Priority priority) {
    switch (priority) {
      case Priority.high:
        return const Color(0xFFEF4444);
      case Priority.medium:
        return const Color(0xFFF59E0B);
      case Priority.low:
        return const Color(0xFF10B981);
    }
  }

  static String priorityLabel(Priority priority) {
    switch (priority) {
      case Priority.high:
        return 'High';
      case Priority.medium:
        return 'Medium';
      case Priority.low:
        return 'Low';
    }
  }
}
