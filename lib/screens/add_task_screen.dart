import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../utils/constants.dart';
import '../providers/task_provider.dart';
import '../utils/notification_service.dart';

class AddTaskScreen extends ConsumerStatefulWidget {
  final Task? task;

  const AddTaskScreen({super.key, this.task});

  @override
  ConsumerState<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends ConsumerState<AddTaskScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late DateTime _dueDate;
  late Priority _priority;

  late final AnimationController _entranceController;
  late final AnimationController _saveController;
  bool _isSaving = false;

  late final Animation<double> _headerFade;
  late final Animation<Offset> _headerSlide;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _descFade;
  late final Animation<Offset> _descSlide;
  late final Animation<double> _dateFade;
  late final Animation<Offset> _dateSlide;
  late final Animation<double> _priorityFade;
  late final Animation<Offset> _prioritySlide;
  late final Animation<double> _buttonFade;
  late final Animation<Offset> _buttonSlide;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descriptionController =
        TextEditingController(text: widget.task?.description ?? '');
    _dueDate =
        widget.task?.dueDate ?? DateTime.now().add(const Duration(days: 1));
    _priority = widget.task?.priority ?? Priority.medium;

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _saveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
      lowerBound: 0.0,
      upperBound: 0.06,
    );

    _headerFade = _makeFade(0.0, 0.5);
    _headerSlide = _makeSlide(0.0, 0.5);
    _titleFade = _makeFade(0.15, 0.65);
    _titleSlide = _makeSlide(0.15, 0.65);
    _descFade = _makeFade(0.25, 0.75);
    _descSlide = _makeSlide(0.25, 0.75);
    _dateFade = _makeFade(0.35, 0.85);
    _dateSlide = _makeSlide(0.35, 0.85);
    _priorityFade = _makeFade(0.45, 0.95);
    _prioritySlide = _makeSlide(0.45, 0.95);
    _buttonFade = _makeFade(0.55, 1.0);
    _buttonSlide = _makeSlide(0.55, 1.0);

    _entranceController.forward();
  }

  Animation<double> _makeFade(double start, double end) {
    return CurvedAnimation(
      parent: _entranceController,
      curve: Interval(start, end, curve: Curves.easeOut),
    );
  }

  Animation<Offset> _makeSlide(double start, double end) {
    return Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(
      parent: _entranceController,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    ));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _entranceController.dispose();
    _saveController.dispose();
    super.dispose();
  }

  IconData _priorityIcon(Priority p) {
    switch (p) {
      case Priority.high:
        return Icons.keyboard_double_arrow_up_rounded;
      case Priority.medium:
        return Icons.drag_handle_rounded;
      case Priority.low:
        return Icons.keyboard_double_arrow_down_rounded;
    }
  }

  Future<void> _selectDate() async {
    HapticFeedback.selectionClick();
    final accent = AppConstants.priorityColor(_priority);
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: accent,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.heavyImpact();
      return;
    }

    FocusScope.of(context).unfocus();
    HapticFeedback.mediumImpact();
    setState(() => _isSaving = true);
    _saveController.forward();
    _saveController.reverse();

    try {
      if (widget.task != null) {
        await NotificationService.cancelNotifications(widget.task!.id!);
        final updated = await ref.read(taskProvider.notifier).updateTask(
              widget.task!,
              title: _titleController.text,
              description: _descriptionController.text,
              dueDate: _dueDate,
              priority: _priority,
            );
        await NotificationService.scheduleTaskReminder(updated);
      } else {
        final newTask = await ref.read(taskProvider.notifier).addTask(
              title: _titleController.text,
              description: _descriptionController.text,
              dueDate: _dueDate,
              priority: _priority,
            );
        await NotificationService.scheduleTaskReminder(newTask);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save task: $e')),
        );
      }
    }
  }

  InputDecoration _fieldDecoration(BuildContext context,
      {required String label, IconData? icon}) {
    final theme = Theme.of(context);
    return InputDecoration(
      labelText: label,
      prefixIcon: icon != null
          ? Icon(icon, color: theme.colorScheme.primary.withValues(alpha: 0.7))
          : null,
      filled: true,
      fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: theme.colorScheme.error, width: 1.2),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.task != null;
    final dateFormat = DateFormat('EEE, MMM d, yyyy');
    final theme = Theme.of(context);
    final accent = AppConstants.priorityColor(_priority);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 150,
            pinned: true,
            elevation: 0,
            backgroundColor: theme.colorScheme.surface,
            iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: FadeTransition(
                opacity: _headerFade,
                child: Text(
                  isEditing ? 'Edit Task' : 'New Task',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              background: SlideTransition(
                position: _headerSlide,
                child: FadeTransition(
                  opacity: _headerFade,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          accent.withValues(alpha: 0.25),
                          theme.colorScheme.surface,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SlideTransition(
                      position: _titleSlide,
                      child: FadeTransition(
                        opacity: _titleFade,
                        child: TextFormField(
                          controller: _titleController,
                          style: theme.textTheme.titleMedium,
                          decoration: _fieldDecoration(context,
                              label: 'Title', icon: Icons.edit_rounded),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a title';
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SlideTransition(
                      position: _descSlide,
                      child: FadeTransition(
                        opacity: _descFade,
                        child: TextFormField(
                          controller: _descriptionController,
                          maxLines: 3,
                          decoration: _fieldDecoration(context,
                              label: 'Description (optional)',
                              icon: Icons.notes_rounded),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SlideTransition(
                      position: _dateSlide,
                      child: FadeTransition(
                        opacity: _dateFade,
                        child: _DateCard(
                          label: dateFormat.format(_dueDate),
                          color: accent,
                          onTap: _selectDate,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SlideTransition(
                      position: _prioritySlide,
                      child: FadeTransition(
                        opacity: _priorityFade,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Priority',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: Priority.values.map((p) {
                                final selected = p == _priority;
                                return Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      right: p != Priority.values.last ? 10 : 0,
                                    ),
                                    child: _PriorityChip(
                                      label: p.name[0].toUpperCase() +
                                          p.name.substring(1),
                                      icon: _priorityIcon(p),
                                      color: AppConstants.priorityColor(p),
                                      selected: selected,
                                      onTap: () {
                                        HapticFeedback.selectionClick();
                                        setState(() => _priority = p);
                                      },
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),
                    SlideTransition(
                      position: _buttonSlide,
                      child: FadeTransition(
                        opacity: _buttonFade,
                        child: _SaveButton(
                          isEditing: isEditing,
                          isSaving: _isSaving,
                          color: accent,
                          scaleController: _saveController,
                          onTap: _save,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateCard extends StatefulWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _DateCard({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<_DateCard> createState() => _DateCardState();
}

class _DateCardState extends State<_DateCard> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.97),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.calendar_today_rounded,
                    color: widget.color, size: 20),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Due date',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.label,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const Spacer(),
              Icon(Icons.chevron_right_rounded,
                  color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _PriorityChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _PriorityChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.14) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? color
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: selected ? 1.15 : 1.0,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutBack,
              child: Icon(
                icon,
                size: 20,
                color: selected ? color : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              style: theme.textTheme.labelMedium!.copyWith(
                color: selected ? color : theme.colorScheme.onSurfaceVariant,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  final bool isEditing;
  final bool isSaving;
  final Color color;
  final AnimationController scaleController;
  final VoidCallback onTap;

  const _SaveButton({
    required this.isEditing,
    required this.isSaving,
    required this.color,
    required this.scaleController,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: scaleController,
      builder: (context, child) {
        final scale = 1 - scaleController.value;
        return Transform.scale(scale: scale, child: child);
      },
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: Material(
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: isSaving ? null : onTap,
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  colors: [color, Color.lerp(color, Colors.black, 0.25)!],
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: isSaving
                      ? const SizedBox(
                          key: ValueKey('loading'),
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Row(
                          key: const ValueKey('label'),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isEditing
                                  ? Icons.check_rounded
                                  : Icons.add_task_rounded,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isEditing ? 'Update Task' : 'Add Task',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
