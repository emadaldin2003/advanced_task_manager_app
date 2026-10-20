// screens/tasks_list_screen.dart
import 'package:flutter/material.dart';
import '../models/task.dart';
import '../database/database.dart';
import '../widgets/task_item.dart';
import '../widgets/empty_state.dart';
import 'add_edit_task_screen.dart';
import 'completed_tasks_screen.dart';
import 'settings_screen.dart';

class TasksListScreen extends StatefulWidget {
  final String userId;
  const TasksListScreen({super.key, required this.userId});

  @override
  State<TasksListScreen> createState() => _TasksListScreenState();
}

class _TasksListScreenState extends State<TasksListScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Task> tasks = [];
  List<Task> filteredTasks = [];
  
  String selectedCategory = 'الكل';
  String sortBy = 'الأحدث';
  String searchQuery = '';
  bool _isSearching = false;
  final _searchController = TextEditingController();
  
  final List<String> categories = ['الكل', 'عام', 'عمل', 'شخصي', 'منزلي', 'مهم'];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    final tasksFromDb = await _dbHelper.getTasksByUserId(widget.userId);
    if (!mounted) return;
    setState(() {
      tasks = tasksFromDb;
      _applyFilters();
    });
  }

  Future<void> _deleteTask(String taskId) async {
    await _dbHelper.deleteTask(taskId);
    await _loadTasks();
  }

  Future<void> _toggleTaskStatus(String taskId) async {
    final index = tasks.indexWhere((t) => t.id == taskId);
    if (index >= 0) {
      final updated = tasks[index].copyWith(isCompleted: !tasks[index].isCompleted);
      await _dbHelper.updateTask(updated);
      await _loadTasks();
    }
  }

  void _applyFilters() {
    filteredTasks = tasks.where((task) {
      final matchesCategory = selectedCategory == 'الكل' || task.category == selectedCategory;
      final matchesSearch = searchQuery.isEmpty || task.title.toLowerCase().contains(searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

    if (sortBy == 'الأحدث') {
      filteredTasks.sort((a, b) => b.id.compareTo(a.id));
    } else if (sortBy == 'الأقدم') {
      filteredTasks.sort((a, b) => a.id.compareTo(b.id));
    } else if (sortBy == 'الأعلى أولوية') {
      filteredTasks.sort((a, b) => b.priority.compareTo(a.priority));
    } else if (sortBy == 'الأدنى أولوية') {
      filteredTasks.sort((a, b) => a.priority.compareTo(b.priority));
    } else if (sortBy == 'الأقرب موعد') {
      filteredTasks.sort((a, b) {
        if (a.dueDate == null && b.dueDate == null) return 0;
        if (a.dueDate == null) return 1;
        if (b.dueDate == null) return -1;
        return a.dueDate!.compareTo(b.dueDate!);
      });
    }
  }

  void _navigateToAddEditScreen({Task? task}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditTaskScreen(
          task: task,
          categories: categories.where((cat) => cat != 'الكل').toList(),
        ),
      ),
    );

    if (result != null && result is Map) {
      if (result['isEdit']) {
        final updatedTask = tasks.firstWhere((t) => t.id == result['id']).copyWith(
          title: result['title'],
          category: result['category'],
          priority: result['priority'],
          dueDate: result['dueDate'],
          reminder: result['reminder'],
        );
        await _dbHelper.updateTask(updatedTask);
      } else {
        final newTask = Task(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: widget.userId,
          title: result['title'],
          category: result['category'],
          priority: result['priority'],
          dueDate: result['dueDate'],
          reminder: result['reminder'],
        );
        await _dbHelper.insertTask(newTask);
      }
      await _loadTasks();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      // إضافة الـ Drawer
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [scheme.primary, scheme.primaryContainer],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: scheme.onPrimary,
                    child: Icon(Icons.person, size: 40, color: scheme.primary),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'مرحباً بك',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.list_alt),
              title: const Text('مهامي الحالية'),
              selected: true,
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.done_all),
              title: const Text('المهام المكتملة'),
              onTap: () {
                Navigator.pop(context); // إغلاق القائمة الجانبية
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => CompletedTasksScreen(userId: widget.userId)),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('الإعدادات'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SettingsScreen(userId: widget.userId)),
                );
              },
            ),
          ],
        ),
      ),
      
      appBar: AppBar(
        title: _isSearching 
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(hintText: 'بحث...', border: InputBorder.none),
                onChanged: (v) => setState(() { searchQuery = v; _applyFilters(); }),
              )
            : const Text('مهامي'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  searchQuery = '';
                  _searchController.clear();
                  _applyFilters();
                }
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // لوحة التحكم العلوية
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                Expanded(child: _buildDashboardCard('الإجمالي', tasks.length.toString(), scheme.primary, scheme)),
                const SizedBox(width: 8),
                Expanded(child: _buildDashboardCard('مكتملة', tasks.where((t) => t.isCompleted).length.toString(), Colors.green, scheme)),
                const SizedBox(width: 8),
                Expanded(child: _buildDashboardCard('قيد التنفيذ', tasks.where((t) => !t.isCompleted).length.toString(), Colors.orange, scheme)),
              ],
            ),
          ),
          
          // فلاتر
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: selectedCategory,
                    isExpanded: true,
                    items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (v) => setState(() { selectedCategory = v!; _applyFilters(); }),
                    decoration: const InputDecoration(labelText: 'التصنيف', contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: sortBy,
                    isExpanded: true,
                    items: ['الأحدث', 'الأقدم', 'الأعلى أولوية', 'الأدنى أولوية', 'الأقرب موعد'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (v) => setState(() { sortBy = v!; _applyFilters(); }),
                    decoration: const InputDecoration(labelText: 'ترتيب', contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          
          // القائمة
          Expanded(
            child: filteredTasks.isEmpty
                ? const EmptyState(icon: Icons.task_outlined, title: 'لا توجد مهام', subtitle: 'اضغط + لإضافة مهمة جديدة')
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: filteredTasks.length,
                    itemBuilder: (context, index) {
                      final task = filteredTasks[index];
                      return TaskItem(
                        task: task,
                        onToggleStatus: () => _toggleTaskStatus(task.id),
                        onEdit: () => _navigateToAddEditScreen(task: task),
                        onDelete: () => _deleteTask(task.id),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddEditScreen(),
        icon: const Icon(Icons.add),
        label: const Text('مهمة'),
      ),
    );
  }

  Widget _buildDashboardCard(String label, String count, Color color, ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(count, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}