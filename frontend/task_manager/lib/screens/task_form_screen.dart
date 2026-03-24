import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';

class TaskFormScreen extends StatefulWidget {
  final Task? task; // null for creation, present for edit

  const TaskFormScreen({Key? key, this.task}) : super(key: key);

  @override
  _TaskFormScreenState createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  
  String? _dueDate;
  String _status = 'To-Do';
  int? _blockedBy;
  String? _isRecurring;

  bool _isSaving = false;

  static const _draftTitleKey = 'draft_title';
  static const _draftDescKey = 'draft_description';
  static const _draftDateKey = 'draft_due_date';

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();

    if (widget.task != null) {
      // Edit mode: populate existing
      _titleController.text = widget.task!.title;
      _descriptionController.text = widget.task!.description;
      _dueDate = widget.task!.dueDate;
      _status = widget.task!.status;
      _blockedBy = widget.task!.blockedBy;
      _isRecurring = widget.task!.isRecurring;
    } else {
      // Create mode: load drafts
      _loadDrafts();
    }

    _titleController.addListener(_saveDrafts);
    _descriptionController.addListener(_saveDrafts);
  }

  @override
  void dispose() {
    _titleController.removeListener(_saveDrafts);
    _descriptionController.removeListener(_saveDrafts);
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadDrafts() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (prefs.containsKey(_draftTitleKey)) {
        _titleController.text = prefs.getString(_draftTitleKey)!;
      }
      if (prefs.containsKey(_draftDescKey)) {
        _descriptionController.text = prefs.getString(_draftDescKey)!;
      }
      if (prefs.containsKey(_draftDateKey)) {
        _dueDate = prefs.getString(_draftDateKey);
      }
    });
  }

  Future<void> _saveDrafts() async {
    if (widget.task != null) return; // Don't save drafts when editing
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_draftTitleKey, _titleController.text);
    await prefs.setString(_draftDescKey, _descriptionController.text);
    if (_dueDate != null) {
      await prefs.setString(_draftDateKey, _dueDate!);
    }
  }

  Future<void> _clearDrafts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_draftTitleKey);
    await prefs.remove(_draftDescKey);
    await prefs.remove(_draftDateKey);
  }

  Future<void> _selectDate() async {
    DateTime initialDate = DateTime.now();
    if (_dueDate != null) {
      try {
        initialDate = DateTime.parse(_dueDate!);
      } catch (_) {}
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked != null) {
      setState(() {
        _dueDate = DateFormat('yyyy-MM-dd').format(picked);
      });
      _saveDrafts();
    }
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a due date')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final provider = context.read<TaskProvider>();
    
    final newTaskData = Task(
      id: widget.task?.id ?? 0,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      dueDate: _dueDate!,
      status: _status,
      blockedBy: _blockedBy,
      isRecurring: _isRecurring,
      sortOrder: widget.task?.sortOrder ?? 0,
    );

    try {
      if (widget.task == null) {
        await provider.createTask(newTaskData);
        await _clearDrafts();
      } else {
        await provider.updateTask(widget.task!.id, newTaskData);
      }
      
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving task: $e')),
        );
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine available tasks for 'Blocked By' (excluding current task if editing)
    final availableTasks = context.read<TaskProvider>().tasks.where((t) {
      return widget.task == null || t.id != widget.task!.id;
    }).toList();

    return WillPopScope(
      onWillPop: () async {
        // Double check not saving before pop directly
        return !_isSaving;
      },
      child: Stack(
        children: [
          Scaffold(
            appBar: AppBar(
              title: Text(widget.task == null ? 'New Task' : 'Edit Task'),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      enabled: !_isSaving,
                      decoration: const InputDecoration(
                        labelText: 'Title *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value == null || value.trim().isEmpty ? 'Required field' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      enabled: !_isSaving,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value == null || value.trim().isEmpty ? 'Required field' : null,
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: _isSaving ? null : _selectDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Due Date *',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(_dueDate ?? 'Select Date'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _status,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                      ),
                      items: ['To-Do', 'In Progress', 'Done']
                          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: _isSaving ? null : (v) {
                        setState(() => _status = v!);
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int?>(
                      value: _blockedBy,
                      decoration: const InputDecoration(
                        labelText: 'Blocked By (Optional)',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('None'),
                        ),
                        ...availableTasks.map((t) => DropdownMenuItem<int?>(
                          value: t.id,
                          child: Text(t.title),
                        ))
                      ],
                      onChanged: _isSaving ? null : (v) {
                        setState(() => _blockedBy = v);
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String?>(
                      value: _isRecurring,
                      decoration: const InputDecoration(
                        labelText: 'Recurring (Optional)',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('None')),
                        DropdownMenuItem(value: 'Daily', child: Text('Daily')),
                        DropdownMenuItem(value: 'Weekly', child: Text('Weekly')),
                      ],
                      onChanged: _isSaving ? null : (v) {
                        setState(() => _isRecurring = v);
                      },
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: _isSaving ? null : _saveTask,
                      child: const Text('Save Task', style: TextStyle(fontSize: 16)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isSaving)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Saving...', style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
