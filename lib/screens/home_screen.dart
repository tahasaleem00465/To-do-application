import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';

import '../utils/notification_service.dart';
import '../widgets/task_tile.dart';
import '../widgets/empty_widget.dart';
import 'add_task_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final VoidCallback? onToggleTheme;

  const HomeScreen({super.key, this.onToggleTheme});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  bool _isSearchOpen = false;
  final _searchController = TextEditingController();

  late final AnimationController _fabController;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fabController.dispose();
    super.dispose();
  }

  Route _premiumRoute(Widget page) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 380),
      reverseTransitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved =
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.06),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  void _openAddScreen() async {
    HapticFeedback.mediumImpact();
    await _fabController.reverse();
    if (!mounted) return;
    _fabController.forward();
    Navigator.push(context, _premiumRoute(const AddTaskScreen()));
  }

  void _openEditScreen(Task task) {
    Navigator.push(context, _premiumRoute(AddTaskScreen(task: task)));
  }

  void _showSortDialog() {
    final currentSort = ref.read(taskProvider).sort;
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sort by',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              ...TaskSort.values.map((sort) {
                final selected = currentSort == sort;
                return InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref.read(taskProvider.notifier).setSort(sort);
                    Navigator.pop(context);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: selected
                          ? theme.colorScheme.primary.withValues(alpha: 0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          selected
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: selected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          sort == TaskSort.dueDate ? 'Due Date' : 'Priority',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  String _emptyMessage(TaskFilter filter) {
    switch (filter) {
      case TaskFilter.all:
        return 'No tasks yet';
      case TaskFilter.active:
        return 'No active tasks';
      case TaskFilter.completed:
        return 'No completed tasks';
    }
  }

  Widget _buildTaskList(BuildContext context, List<Task> tasks) {
    return ListView.builder(
      key: const ValueKey('list'),
      padding: const EdgeInsets.only(bottom: 96, top: 4),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return _StaggeredItem(
          index: index,
          child: TaskTile(
            task: task,
            onToggle: () {
              HapticFeedback.selectionClick();
              ref.read(taskProvider.notifier).toggleComplete(task);
            },
            onTap: () => _openEditScreen(task),
            onDelete: () {
              if (task.id == null) return;
              NotificationService.cancelNotifications(task.id!);
              ref.read(taskProvider.notifier).deleteTask(task.id!);
              final messenger = ScaffoldMessenger.of(context);
              messenger.clearSnackBars();
              messenger.showSnackBar(
                SnackBar(
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  content: Text('Task "${task.title}" deleted'),
                  action: SnackBarAction(
                    label: 'Undo',
                    onPressed: () {
                      ref.read(taskProvider.notifier).restoreTask(task);
                    },
                  ),
                ),
              );
              Future.delayed(const Duration(seconds: 4), () {
                if (mounted) messenger.hideCurrentSnackBar();
              });
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final taskState = ref.watch(taskProvider);
    final tasks = taskState.filteredTasks;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 2,
        backgroundColor: theme.colorScheme.surface,
        titleSpacing: 20,
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 240),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SizeTransition(
              sizeFactor: anim,
              axis: Axis.horizontal,
              axisAlignment: -1,
              child: child,
            ),
          ),
          child: _isSearchOpen
              ? TextField(
                  key: const ValueKey('search'),
                  controller: _searchController,
                  autofocus: true,
                  style: theme.textTheme.titleMedium,
                  decoration: InputDecoration(
                    hintText: 'Search tasks...',
                    border: InputBorder.none,
                    hintStyle: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  onChanged: (value) {
                    ref.read(taskProvider.notifier).setSearchQuery(value);
                  },
                )
              : Text(
                  'TaskFlow',
                  key: const ValueKey('title'),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
        ),
        actions: [
          IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, anim) => RotationTransition(
                turns: anim,
                child: FadeTransition(opacity: anim, child: child),
              ),
              child: Icon(
                _isSearchOpen ? Icons.close_rounded : Icons.search_rounded,
                key: ValueKey(_isSearchOpen),
              ),
            ),
            onPressed: () {
              setState(() {
                _isSearchOpen = !_isSearchOpen;
                if (!_isSearchOpen) {
                  _searchController.clear();
                  ref.read(taskProvider.notifier).setSearchQuery('');
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.sort_rounded),
            onPressed: _showSortDialog,
          ),
          if (widget.onToggleTheme != null)
            IconButton(
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, anim) => RotationTransition(
                  turns: Tween<double>(begin: 0.75, end: 1).animate(anim),
                  child: FadeTransition(opacity: anim, child: child),
                ),
                child: Icon(
                  Theme.of(context).brightness == Brightness.light
                      ? Icons.dark_mode_rounded
                      : Icons.light_mode_rounded,
                  key: ValueKey(Theme.of(context).brightness),
                ),
              ),
              onPressed: widget.onToggleTheme,
            ),
          const SizedBox(width: 6),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: _SegmentedFilter(
              selected: taskState.filter,
              onChanged: (f) {
                HapticFeedback.selectionClick();
                ref.read(taskProvider.notifier).setFilter(f);
              },
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              child: taskState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : taskState.error != null
                      ? _AnimatedEmpty(
                          key: const ValueKey('error'),
                          message: 'Error loading tasks. Pull to refresh.',
                        )
                      : tasks.isEmpty
                          ? _AnimatedEmpty(
                              key: ValueKey('empty-${taskState.filter}'),
                              message: _emptyMessage(taskState.filter),
                            )
                          : _buildTaskList(context, tasks),
            ),
          ),
        ],
      ),
      floatingActionButton: ScaleTransition(
        scale: CurvedAnimation(
          parent: _fabController,
          curve: Curves.easeOutBack,
        ),
        child: _GradientFab(onTap: _openAddScreen),
      ),
    );
  }
}

class _SegmentedFilter extends StatelessWidget {
  final TaskFilter selected;
  final ValueChanged<TaskFilter> onChanged;

  const _SegmentedFilter({required this.selected, required this.onChanged});

  String _label(TaskFilter f) {
    switch (f) {
      case TaskFilter.all:
        return 'All';
      case TaskFilter.active:
        return 'Active';
      case TaskFilter.completed:
        return 'Done';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filters = TaskFilter.values;
    final index = filters.indexOf(selected);

    return LayoutBuilder(
      builder: (context, constraints) {
        final segmentWidth = (constraints.maxWidth - 8) / filters.length;
        return Container(
          height: 44,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Stack(
            children: [
              AnimatedAlign(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                alignment: Alignment(-1 + (2 * index) / (filters.length - 1), 0),
                child: FractionallySizedBox(
                  widthFactor: 1 / filters.length,
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Row(
                children: filters.map((f) {
                  final isSelected = f == selected;
                  return SizedBox(
                    width: segmentWidth,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onChanged(f),
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 220),
                          style: TextStyle(
                            color: isSelected
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurfaceVariant,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 14,
                          ),
                          child: Text(_label(f)),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StaggeredItem extends StatefulWidget {
  final int index;
  final Widget child;

  const _StaggeredItem({required this.index, required this.child});

  @override
  State<_StaggeredItem> createState() => _StaggeredItemState();
}

class _StaggeredItemState extends State<_StaggeredItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    final delayMs = 30 * widget.index.clamp(0, 10);
    Future.delayed(Duration(milliseconds: delayMs), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

class _AnimatedEmpty extends StatelessWidget {
  final String message;

  const _AnimatedEmpty({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.scale(scale: 0.9 + (0.1 * value), child: child),
        );
      },
      child: EmptyWidget(message: message),
    );
  }
}

class _GradientFab extends StatelessWidget {
  final VoidCallback onTap;

  const _GradientFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Material(
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [primary, Color.lerp(primary, Colors.black, 0.25)!],
            ),
            boxShadow: [
              BoxShadow(
                color: primary.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}
