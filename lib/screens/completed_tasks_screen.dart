// screens/completed_tasks_screen.dart
import 'package:flutter/material.dart';
import '../database/database.dart';
import '../models/task.dart';
import '../widgets/task_item.dart';
import '../widgets/empty_state.dart';

class CompletedTasksScreen extends StatefulWidget {
  final String userId;
  const CompletedTasksScreen({super.key, required this.userId});

  @override
  State<CompletedTasksScreen> createState() => _CompletedTasksScreenState();
}

class _CompletedTasksScreenState extends State<CompletedTasksScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Task> _completedTasks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final tasks = await _dbHelper.getTasksByUserId(widget.userId);
    if (!mounted) return;
    setState(() {
      _completedTasks = tasks.where((t) => t.isCompleted).toList();
      _loading = false;
    });
  }

  Future<void> _toggleTaskStatus(String taskId) async {
    final index = _completedTasks.indexWhere((t) => t.id == taskId);
    if (index >= 0) {
      await _dbHelper.updateTask(_completedTasks[index].copyWith(isCompleted: false));
      _loadTasks();
    }
  }

  Future<void> _deleteTask(String taskId) async {
    await _dbHelper.deleteTask(taskId);
    _loadTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المهام المكتملة')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _completedTasks.isEmpty
              ? const EmptyState(
                  icon: Icons.done_all,
                  title: 'لا توجد مهام مكتملة',
                  subtitle: 'المهام التي تنجزها ستظهر هنا',
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _completedTasks.length,
                  itemBuilder: (context, index) {
                    final task = _completedTasks[index];
                    return TaskItem(
                      task: task,
                      onToggleStatus: () => _toggleTaskStatus(task.id),
                      onEdit: () {}, // لا حاجة للتعديل من هنا
                      onDelete: () => _deleteTask(task.id),
                    );
                  },
                ),
    );
  }
}