import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task.dart';
import '../repository/task_repository.dart';

class TaskState {
  final List<Task> tasks;
  final TaskFilter filter;
  final TaskSort sort;
  final String searchQuery;
  final bool isLoading;
  final String? error;

  TaskState({
    this.tasks = const [],
    this.filter = TaskFilter.all,
    this.sort = TaskSort.dueDate,
    this.searchQuery = '',
    this.isLoading = true,
    this.error,
  });

  TaskState copyWith({
    List<Task>? tasks,
    TaskFilter? filter,
    TaskSort? sort,
    String? searchQuery,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return TaskState(
      tasks: tasks ?? this.tasks,
      filter: filter ?? this.filter,
      sort: sort ?? this.sort,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  List<Task> get filteredTasks {
    var result = List<Task>.from(tasks);

    switch (filter) {
      case TaskFilter.active:
        result = result.where((t) => !t.isCompleted).toList();
        break;
      case TaskFilter.completed:
        result = result.where((t) => t.isCompleted).toList();
        break;
      case TaskFilter.all:
        break;
    }

    if (searchQuery.isNotEmpty) {
      result = result
          .where(
              (t) => t.title.toLowerCase().contains(searchQuery.toLowerCase()))
          .toList();
    }

    switch (sort) {
      case TaskSort.dueDate:
        result.sort((a, b) => a.dueDate.compareTo(b.dueDate));
        break;
      case TaskSort.priority:
        result.sort((a, b) => b.priority.index.compareTo(a.priority.index));
        break;
    }

    return result;
  }
}

class TaskNotifier extends StateNotifier<TaskState> {
  final TaskRepository _repository;

  TaskNotifier(this._repository) : super(TaskState()) {
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    try {
      final tasks = await _repository.getTasks();
      state = state.copyWith(tasks: tasks, isLoading: false, clearError: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<Task> addTask({
    required String title,
    String description = '',
    required DateTime dueDate,
    Priority priority = Priority.medium,
  }) async {
    final task = Task(
      title: title,
      description: description,
      dueDate: dueDate,
      priority: priority,
    );
    final id = await _repository.addTask(task);
    await _loadTasks();
    return task.copyWith(id: id);
  }

  Future<Task> updateTask(
    Task task, {
    required String title,
    String? description,
    required DateTime dueDate,
    required Priority priority,
  }) async {
    final updated = task.copyWith(
      title: title,
      description: description,
      dueDate: dueDate,
      priority: priority,
    );
    await _repository.updateTask(updated);
    await _loadTasks();
    return updated;
  }

  Future<void> deleteTask(int id) async {
    await _repository.deleteTask(id);
    await _loadTasks();
  }

  Future<void> restoreTask(Task task) async {
    await _repository.restoreTask(task);
    await _loadTasks();
  }

  Future<void> toggleComplete(Task task) async {
    final updated = task.copyWith(isCompleted: !task.isCompleted);
    await _repository.updateTask(updated);
    await _loadTasks();
  }

  void setFilter(TaskFilter filter) {
    state = state.copyWith(filter: filter);
  }

  void setSort(TaskSort sort) {
    state = state.copyWith(sort: sort);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }
}

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository();
});

final taskProvider = StateNotifierProvider<TaskNotifier, TaskState>((ref) {
  final repository = ref.watch(taskRepositoryProvider);
  return TaskNotifier(repository);
});
