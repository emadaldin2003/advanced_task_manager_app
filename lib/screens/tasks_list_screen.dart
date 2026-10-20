import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import '../database/database.dart';
import '../widgets/task_item.dart';
import 'add_edit_task_screen.dart';
import 'login_screen.dart';

class TasksListScreen extends StatefulWidget {
  final String userId;
  
  TasksListScreen({required this.userId});
  
  @override
  _TasksListScreenState createState() => _TasksListScreenState();
}

class _TasksListScreenState extends State<TasksListScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Task> tasks = [];
  List<Task> filteredTasks = [];
  String selectedCategory = 'الكل';
  String sortBy = 'الأحدث';
  String searchQuery = '';
  List<String> categories = ['الكل', 'عام', 'عمل', 'شخصي', 'منزلي', 'مهم'];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final tasksFromDb = await _dbHelper.getTasksByUserId(widget.userId);
    setState(() {
      tasks = tasksFromDb;
      _applyFilters();
    });
  }

  Future<void> _addTask(String taskTitle, String category, int priority, DateTime? dueDate, DateTime? reminder) async {
    final newTask = Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: widget.userId,
      title: taskTitle,
      category: category,
      priority: priority,
      dueDate: dueDate,
      reminder: reminder,
    );
    
    await _dbHelper.insertTask(newTask);
    await _loadTasks();
  }

  Future<void> _editTask(String taskId, String newTitle, String category, int priority, DateTime? dueDate, DateTime? reminder) async {
    final taskIndex = tasks.indexWhere((task) => task.id == taskId);
    if (taskIndex >= 0) {
      final updatedTask = Task(
        id: taskId,
        userId: widget.userId,
        title: newTitle,
        category: category,
        priority: priority,
        dueDate: dueDate,
        reminder: reminder,
        isCompleted: tasks[taskIndex].isCompleted,
      );
      
      await _dbHelper.updateTask(updatedTask);
      await _loadTasks();
    }
  }

  Future<void> _deleteTask(String taskId) async {
    await _dbHelper.deleteTask(taskId);
    await _loadTasks();
  }

  Future<void> _toggleTaskStatus(String taskId) async {
    final taskIndex = tasks.indexWhere((task) => task.id == taskId);
    if (taskIndex >= 0) {
      final updatedTask = Task(
        id: taskId,
        userId: widget.userId,
        title: tasks[taskIndex].title,
        category: tasks[taskIndex].category,
        priority: tasks[taskIndex].priority,
        dueDate: tasks[taskIndex].dueDate,
        reminder: tasks[taskIndex].reminder,
        isCompleted: !tasks[taskIndex].isCompleted,
      );
      
      await _dbHelper.updateTask(updatedTask);
      await _loadTasks();
    }
  }

  void _applyFilters() {
    setState(() {
      filteredTasks = tasks.where((task) {
        final matchesCategory = selectedCategory == 'الكل' || task.category == selectedCategory;
        final matchesSearch = searchQuery.isEmpty || 
            task.title.toLowerCase().contains(searchQuery.toLowerCase());
        return matchesCategory && matchesSearch;
      }).toList();

      // Sorting logic
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
    });
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
      final String title = result['title'];
      final String category = result['category'];
      final int priority = result['priority'];
      final DateTime? dueDate = result['dueDate'];
      final DateTime? reminder = result['reminder'];
      
      if (result['isEdit']) {
        await _editTask(result['id'], title, category, priority, dueDate, reminder);
      } else {
        await _addTask(title, category, priority, dueDate, reminder);
      }
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('مهامي اليومية'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: TaskSearchDelegate(tasks, _applyFilters),
              ).then((value) {
                setState(() {
                  searchQuery = value ?? '';
                  _applyFilters();
                });
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedCategory,
                    items: categories.map((String category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedCategory = newValue!;
                        _applyFilters();
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'التصنيف',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: sortBy,
                    items: ['الأحدث', 'الأقدم', 'الأعلى أولوية', 'الأدنى أولوية', 'الأقرب موعد']
                        .map((String sort) {
                      return DropdownMenuItem<String>(
                        value: sort,
                        child: Text(sort),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        sortBy = newValue!;
                        _applyFilters();
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'ترتيب حسب',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: filteredTasks.isEmpty
                ? Center(
                    child: Text(
                      'لا توجد مهام حالياً\nاضغط على + لإضافة مهمة جديدة',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddEditScreen(),
        child: Icon(Icons.add),
      ),
    );
  }
}

class TaskSearchDelegate extends SearchDelegate<String> {
  final List<Task> tasks;
  final Function applyFilters;

  TaskSearchDelegate(this.tasks, this.applyFilters);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return Container();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestionList = query.isEmpty
        ? tasks
        : tasks.where((task) => task.title.toLowerCase().contains(query.toLowerCase())).toList();

    return ListView.builder(
      itemCount: suggestionList.length,
      itemBuilder: (context, index) {
        final task = suggestionList[index];
        return ListTile(
          title: Text(task.title),
          onTap: () {
            close(context, task.title);
          },
        );
      },
    );
  }
}