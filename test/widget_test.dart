import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/models/task.dart';
import 'package:todo_app/providers/task_provider.dart';
import 'package:todo_app/repository/task_repository.dart';
import 'package:todo_app/widgets/task_tile.dart';
import 'package:todo_app/screens/splash_screen.dart';

class FakeTaskRepository implements TaskRepository {
  final List<Task> _tasks = [];
  int _nextId = 1;

  @override
  Future<int> addTask(Task task) async {
    final id = _nextId++;
    _tasks.add(task.copyWith(id: id));
    return id;
  }

  @override
  Future<void> restoreTask(Task task) async {
    _tasks.add(task);
  }

  @override
  Future<List<Task>> getTasks() async => List.unmodifiable(_tasks);

  @override
  Future<int> updateTask(Task task) async {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) _tasks[index] = task;
    return index;
  }

  @override
  Future<int> deleteTask(int id) async {
    _tasks.removeWhere((t) => t.id == id);
    return 0;
  }
}

void main() {
  group('Task model', () {
    test('creation', () {
      final task = Task(
        id: 1,
        title: 'Test Task',
        description: 'Description',
        dueDate: DateTime(2026, 7, 20),
        priority: Priority.high,
      );

      expect(task.title, 'Test Task');
      expect(task.isCompleted, false);
      expect(task.priority, Priority.high);
    });

    test('toMap/fromMap round-trip', () {
      final task = Task(
        id: 1,
        title: 'Buy Milk',
        description: 'From Walmart',
        dueDate: DateTime(2026, 7, 20),
        priority: Priority.high,
        isCompleted: false,
      );

      final map = task.toMap();
      final fromMap = Task.fromMap(map);

      expect(fromMap.title, task.title);
      expect(fromMap.description, task.description);
      expect(fromMap.priority, task.priority);
      expect(fromMap.isCompleted, task.isCompleted);
    });

    test('copyWith preserves unmodified fields', () {
      final task = Task(
        id: 1,
        title: 'Original',
        dueDate: DateTime(2026, 7, 20),
      );

      final updated = task.copyWith(title: 'Updated', isCompleted: true);

      expect(updated.title, 'Updated');
      expect(updated.isCompleted, true);
      expect(updated.id, 1);
    });
  });

  group('TaskState filtering', () {
    test('all filter shows every task', () {
      final tasks = [
        Task(id: 1, title: 'Task 1', dueDate: DateTime.now(), isCompleted: false),
        Task(id: 2, title: 'Task 2', dueDate: DateTime.now(), isCompleted: true),
      ];

      final state = TaskState(tasks: tasks, filter: TaskFilter.all);
      expect(state.filteredTasks.length, 2);
    });

    test('active filter shows only incomplete tasks', () {
      final tasks = [
        Task(id: 1, title: 'Task 1', dueDate: DateTime.now(), isCompleted: false),
        Task(id: 2, title: 'Task 2', dueDate: DateTime.now(), isCompleted: true),
      ];

      final state = TaskState(tasks: tasks, filter: TaskFilter.active);
      expect(state.filteredTasks.length, 1);
      expect(state.filteredTasks.first.title, 'Task 1');
    });

    test('completed filter shows only done tasks', () {
      final tasks = [
        Task(id: 1, title: 'Task 1', dueDate: DateTime.now(), isCompleted: false),
        Task(id: 2, title: 'Task 2', dueDate: DateTime.now(), isCompleted: true),
      ];

      final state = TaskState(tasks: tasks, filter: TaskFilter.completed);
      expect(state.filteredTasks.length, 1);
      expect(state.filteredTasks.first.title, 'Task 2');
    });

    test('search filters by title', () {
      final tasks = [
        Task(id: 1, title: 'Buy groceries', dueDate: DateTime.now()),
        Task(id: 2, title: 'Walk the dog', dueDate: DateTime.now()),
        Task(id: 3, title: 'Buy flowers', dueDate: DateTime.now()),
      ];

      final state = TaskState(tasks: tasks, searchQuery: 'buy');
      expect(state.filteredTasks.length, 2);
    });

    test('search is case-insensitive', () {
      final tasks = [
        Task(id: 1, title: 'Buy groceries', dueDate: DateTime.now()),
        Task(id: 2, title: 'walk the dog', dueDate: DateTime.now()),
      ];

      final state = TaskState(tasks: tasks, searchQuery: 'Walk');
      expect(state.filteredTasks.length, 1);
      expect(state.filteredTasks.first.title, 'walk the dog');
    });
  });

  group('TaskState sorting', () {
    test('sort by priority puts high first', () {
      final tasks = [
        Task(id: 1, title: 'Low', dueDate: DateTime.now(), priority: Priority.low),
        Task(id: 2, title: 'High', dueDate: DateTime.now(), priority: Priority.high),
        Task(id: 3, title: 'Medium', dueDate: DateTime.now(), priority: Priority.medium),
      ];

      final state = TaskState(tasks: tasks, sort: TaskSort.priority);
      expect(state.filteredTasks.first.title, 'High');
      expect(state.filteredTasks.last.title, 'Low');
    });

    test('sort by due date puts earliest first', () {
      final tasks = [
        Task(id: 1, title: 'Later', dueDate: DateTime(2026, 12, 25)),
        Task(id: 2, title: 'Sooner', dueDate: DateTime(2026, 7, 15)),
      ];

      final state = TaskState(tasks: tasks, sort: TaskSort.dueDate);
      expect(state.filteredTasks.first.title, 'Sooner');
    });
  });

  group('TaskNotifier', () {
    late FakeTaskRepository repo;
    late TaskNotifier notifier;

    setUp(() {
      repo = FakeTaskRepository();
      notifier = TaskNotifier(repo);
    });

    test('starts with empty tasks', () async {
      await Future.delayed(Duration.zero);
      expect(notifier.state.tasks, isEmpty);
    });

    test('addTask inserts and reloads', () async {
      final task = await notifier.addTask(
        title: 'New Task',
        description: 'A desc',
        dueDate: DateTime(2026, 8, 1),
        priority: Priority.high,
      );

      expect(task.id, 1);
      expect(notifier.state.tasks.length, 1);
      expect(notifier.state.tasks.first.title, 'New Task');
    });

    test('deleteTask removes the task', () async {
      await notifier.addTask(title: 'Delete Me', dueDate: DateTime(2026, 8, 1));
      expect(notifier.state.tasks.length, 1);

      await notifier.deleteTask(1);
      expect(notifier.state.tasks.length, 0);
    });

    test('updateTask modifies fields', () async {
      await notifier.addTask(title: 'Old', dueDate: DateTime(2026, 8, 1));
      final task = notifier.state.tasks.first;

      await notifier.updateTask(
        task,
        title: 'New',
        description: 'Updated',
        dueDate: DateTime(2026, 9, 1),
        priority: Priority.high,
      );

      expect(notifier.state.tasks.first.title, 'New');
      expect(notifier.state.tasks.first.description, 'Updated');
    });

    test('toggleComplete flips isCompleted', () async {
      await notifier.addTask(title: 'Toggle', dueDate: DateTime(2026, 8, 1));
      final task = notifier.state.tasks.first;
      expect(task.isCompleted, false);

      await notifier.toggleComplete(task);
      expect(notifier.state.tasks.first.isCompleted, true);

      await notifier.toggleComplete(notifier.state.tasks.first);
      expect(notifier.state.tasks.first.isCompleted, false);
    });

    test('setFilter updates filter state', () {
      expect(notifier.state.filter, TaskFilter.all);

      notifier.setFilter(TaskFilter.active);
      expect(notifier.state.filter, TaskFilter.active);

      notifier.setFilter(TaskFilter.completed);
      expect(notifier.state.filter, TaskFilter.completed);
    });

    test('setSort updates sort state', () {
      expect(notifier.state.sort, TaskSort.dueDate);

      notifier.setSort(TaskSort.priority);
      expect(notifier.state.sort, TaskSort.priority);
    });

    test('setSearchQuery updates search state', () {
      notifier.setSearchQuery('test');
      expect(notifier.state.searchQuery, 'test');

      notifier.setSearchQuery('');
      expect(notifier.state.searchQuery, '');
    });
  });

  group('TaskTile widget', () {
    testWidgets('renders title and priority', (tester) async {
      final task = Task(
        id: 1,
        title: 'Test Tile',
        dueDate: DateTime(2026, 8, 1),
        priority: Priority.high,
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: TaskTile(
            task: task,
            onToggle: () {},
            onTap: () {},
            onDelete: () {},
          ),
        ),
      ));

      expect(find.text('Test Tile'), findsOneWidget);
      expect(find.text('High'), findsOneWidget);
    });

    testWidgets('shows line-through for completed tasks', (tester) async {
      final task = Task(
        id: 1,
        title: 'Done Task',
        dueDate: DateTime(2026, 8, 1),
        isCompleted: true,
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: TaskTile(
            task: task,
            onToggle: () {},
            onTap: () {},
            onDelete: () {},
          ),
        ),
      ));

      final textWidget = tester.widget<Text>(find.text('Done Task'));
      expect(textWidget.style?.decoration, TextDecoration.lineThrough);
    });

    testWidgets('checkbox calls onToggle', (tester) async {
      bool toggled = false;
      final task = Task(
        id: 1,
        title: 'Toggle Task',
        dueDate: DateTime(2026, 8, 1),
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: TaskTile(
            task: task,
            onToggle: () => toggled = true,
            onTap: () {},
            onDelete: () {},
          ),
        ),
      ));

      await tester.tap(find.byType(Checkbox));
      expect(toggled, true);
    });

    testWidgets('delete is triggered by swipe', (tester) async {
      bool deleted = false;
      final task = Task(
        id: 1,
        title: 'Swipe Me',
        dueDate: DateTime(2026, 8, 1),
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: TaskTile(
            task: task,
            onToggle: () {},
            onTap: () {},
            onDelete: () => deleted = true,
          ),
        ),
      ));

      await tester.drag(find.byType(Dismissible), Offset(-500, 0));
      await tester.pumpAndSettle();
      expect(deleted, true);
    });

    testWidgets('shows description when non-empty', (tester) async {
      final task = Task(
        id: 1,
        title: 'Task',
        description: 'My description',
        dueDate: DateTime(2026, 8, 1),
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: TaskTile(
            task: task,
            onToggle: () {},
            onTap: () {},
            onDelete: () {},
          ),
        ),
      ));

      expect(find.text('My description'), findsOneWidget);
    });

    testWidgets('hides description when empty', (tester) async {
      final task = Task(
        id: 1,
        title: 'Task',
        description: '',
        dueDate: DateTime(2026, 8, 1),
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: TaskTile(
            task: task,
            onToggle: () {},
            onTap: () {},
            onDelete: () {},
          ),
        ),
      ));

      expect(find.text(''), findsNothing);
    });
  });

  group('SplashScreen widget', () {
    testWidgets('renders app name and tagline', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: SplashScreen(
          nextScreen: const Scaffold(),
          appName: 'TaskFlow',
          tagline: 'Plan less. Flow more.',
        ),
      ));

      await tester.pump();

      expect(find.text('T'), findsOneWidget);
      expect(find.text('a'), findsWidgets);
      expect(find.text('Plan less. Flow more.'), findsOneWidget);
    });

    testWidgets('renders checklist labels', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: SplashScreen(
          nextScreen: const Scaffold(),
          taskLabels: const ['One', 'Two', 'Three'],
        ),
      ));

      await tester.pump();

      expect(find.byType(SplashScreen), findsOneWidget);
    });
  });
}
