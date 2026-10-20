import 'package:flutter/material.dart';
import '../models/task.dart';
import '../database/database.dart';

class AddEditTaskScreen extends StatefulWidget {
  final Task? task;
  final List<String> categories;

  AddEditTaskScreen({this.task, required this.categories});

  @override
  _AddEditTaskScreenState createState() => _AddEditTaskScreenState();
}

class _AddEditTaskScreenState extends State<AddEditTaskScreen> {
  final TextEditingController _controller = TextEditingController();
  String selectedCategory = 'عام';
  int selectedPriority = 3;
  DateTime? selectedDueDate;
  DateTime? selectedReminder;

  @override
  void initState() {
    super.initState();
    if (widget.task != null) {
      _controller.text = widget.task!.title;
      selectedCategory = widget.task!.category;
      selectedPriority = widget.task!.priority;
      selectedDueDate = widget.task!.dueDate;
      selectedReminder = widget.task!.reminder;
    }
  }

  Future<void> _selectDate(BuildContext context, bool isDueDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (time != null) {
        setState(() {
          final DateTime fullDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );
          if (isDueDate) {
            selectedDueDate = fullDate;
          } else {
            selectedReminder = fullDate;
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task == null ? 'إضافة مهمة' : 'تعديل المهمة'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _controller,
                decoration: InputDecoration(
                  labelText: 'اكتب المهمة هنا',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                items: widget.categories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedCategory = newValue!;
                  });
                },
                decoration: InputDecoration(
                  labelText: 'التصنيف',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              DropdownButtonFormField<int>(
                value: selectedPriority,
                items: [1, 2, 3, 4, 5].map((int priority) {
                  return DropdownMenuItem<int>(
                    value: priority,
                    child: Text('الأولوية: $priority'),
                  );
                }).toList(),
                onChanged: (int? newValue) {
                  setState(() {
                    selectedPriority = newValue!;
                  });
                },
                decoration: InputDecoration(
                  labelText: 'الأولوية',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              ListTile(
                title: Text(
                  selectedDueDate == null
                      ? 'إضافة تاريخ استحقاق'
                      : 'تاريخ الاستحقاق: ${selectedDueDate!.toString().substring(0, 16)}',
                ),
                trailing: Icon(Icons.calendar_today),
                onTap: () => _selectDate(context, true),
              ),
              ListTile(
                title: Text(
                  selectedReminder == null
                      ? 'إضافة تذكير'
                      : 'التذكير: ${selectedReminder!.toString().substring(0, 16)}',
                ),
                trailing: Icon(Icons.notifications),
                onTap: () => _selectDate(context, false),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_controller.text.isNotEmpty) {
                    Navigator.pop(context, {
                      'id': widget.task?.id ?? '',
                      'title': _controller.text,
                      'category': selectedCategory,
                      'priority': selectedPriority,
                      'dueDate': selectedDueDate,
                      'reminder': selectedReminder,
                      'isEdit': widget.task != null,
                    });
                  }
                },
                child: Text('حفظ'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}