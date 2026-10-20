// screens/add_edit_task_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';

class AddEditTaskScreen extends StatefulWidget {
  final Task? task;
  final List<String> categories;

  const AddEditTaskScreen({super.key, this.task, required this.categories});

  @override
  State<AddEditTaskScreen> createState() => _AddEditTaskScreenState();
}

class _AddEditTaskScreenState extends State<AddEditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isDueDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isDueDate ? (selectedDueDate ?? DateTime.now()) : (selectedReminder ?? DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (time != null && mounted) {
        setState(() {
          final fullDate = DateTime(picked.year, picked.month, picked.day, time.hour, time.minute);
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
    final scheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(title: Text(widget.task == null ? 'إضافة مهمة' : 'تعديل المهمة')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _controller,
              decoration: const InputDecoration(labelText: 'عنوان المهمة'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'يرجى إدخال عنوان للمهمة' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: selectedCategory,
              items: widget.categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => selectedCategory = v!),
              decoration: const InputDecoration(labelText: 'التصنيف'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: selectedPriority,
              items: [1, 2, 3, 4, 5].map((p) => DropdownMenuItem(value: p, child: Text('الأولوية: $p'))).toList(),
              onChanged: (v) => setState(() => selectedPriority = v!),
              decoration: const InputDecoration(labelText: 'الأولوية'),
            ),
            const SizedBox(height: 16),
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: scheme.outlineVariant)),
              leading: const Icon(Icons.calendar_today),
              title: Text(selectedDueDate == null ? 'إضافة تاريخ استحقاق' : 'الاستحقاق: ${DateFormat('yyyy/MM/dd - hh:mm a', 'ar').format(selectedDueDate!)}'),
              onTap: () => _selectDate(context, true),
            ),
            const SizedBox(height: 16),
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: scheme.outlineVariant)),
              leading: const Icon(Icons.notifications),
              title: Text(selectedReminder == null ? 'إضافة تذكير' : 'التذكير: ${DateFormat('yyyy/MM/dd - hh:mm a', 'ar').format(selectedReminder!)}'),
              onTap: () => _selectDate(context, false),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  Navigator.pop(context, {
                    'id': widget.task?.id ?? '',
                    'title': _controller.text.trim(),
                    'category': selectedCategory,
                    'priority': selectedPriority,
                    'dueDate': selectedDueDate,
                    'reminder': selectedReminder,
                    'isEdit': widget.task != null,
                  });
                }
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }
}