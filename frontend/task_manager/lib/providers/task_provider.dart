import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/api_service.dart';

class TaskProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Task> _tasks = [];
  bool _isLoading = false;
  String? _error;

  String _searchQuery = '';
  String _statusFilter = 'All';

  List<Task> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String get statusFilter => _statusFilter;

  Future<void> fetchTasks() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _tasks = await _apiService.getTasks(
        search: _searchQuery,
        status: _statusFilter,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    fetchTasks();
  }

  void setStatusFilter(String status) {
    _statusFilter = status;
    fetchTasks();
  }

  Future<void> createTask(Task task) async {
    await _apiService.createTask(task);
    await fetchTasks();
  }

  Future<void> updateTask(int id, Task task) async {
    await _apiService.updateTask(id, task);
    await fetchTasks();
  }

  Future<void> deleteTask(int id) async {
    // Optimistic delete
    final taskIndex = _tasks.indexWhere((t) => t.id == id);
    if (taskIndex == -1) return;
    
    final task = _tasks[taskIndex];
    _tasks.removeAt(taskIndex);
    notifyListeners();

    try {
      await _apiService.deleteTask(id);
      await fetchTasks(); // Refresh to catch any blocked_by side effects
    } catch (e) {
      // Revert on error
      _tasks.insert(taskIndex, task);
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> reorderTasks(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    
    // UI update immediately (optimistic)
    final Task task = _tasks.removeAt(oldIndex);
    _tasks.insert(newIndex, task);
    notifyListeners();

    // Send to backend
    try {
      final taskIds = _tasks.map((t) => t.id).toList();
      await _apiService.reorderTasks(taskIds);
      await fetchTasks(); // refresh from DB
    } catch (e) {
      _error = "Failed to reorder: $e";
      await fetchTasks(); // revert on failure
    }
  }
}
