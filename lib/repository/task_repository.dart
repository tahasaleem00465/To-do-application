import '../models/task.dart';
import '../database/database_helper.dart';

class TaskRepository {
  Future<int> addTask(Task task) async {
    return await DatabaseHelper.insertTask(task);
  }

  Future<void> restoreTask(Task task) async {
    return await DatabaseHelper.restoreTask(task);
  }

  Future<List<Task>> getTasks() async {
    return await DatabaseHelper.getTasks();
  }

  Future<int> updateTask(Task task) async {
    return await DatabaseHelper.updateTask(task);
  }

  Future<int> deleteTask(int id) async {
    return await DatabaseHelper.deleteTask(id);
  }
}
