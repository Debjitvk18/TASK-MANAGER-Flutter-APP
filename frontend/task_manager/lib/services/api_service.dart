import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/task.dart';

class ApiService {
  // Use 10.0.2.2 for Android emulator to access localhost, use localhost for iOS emulator / web
  static const String baseUrl = 'http://127.0.0.1:8000';

  Future<List<Task>> getTasks({String? search, String? status}) async {
    final queryParams = <String, String>{};
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (status != null && status != 'All') queryParams['status'] = status;

    final uri = Uri.parse('$baseUrl/tasks').replace(queryParameters: queryParams);
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Task.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load tasks');
    }
  }

  Future<Task> createTask(Task task) async {
    final response = await http.post(
      Uri.parse('$baseUrl/tasks'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(task.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Task.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create task');
    }
  }

  Future<Task> updateTask(int id, Task task) async {
    final response = await http.put(
      Uri.parse('$baseUrl/tasks/$id'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(task.toJson()),
    );

    if (response.statusCode == 200) {
      return Task.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to update task');
    }
  }

  Future<void> deleteTask(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/tasks/$id'));

    if (response.statusCode != 200) {
      throw Exception('Failed to delete task');
    }
  }
  
  Future<void> reorderTasks(List<int> taskIds) async {
    final response = await http.put(
      Uri.parse('$baseUrl/tasks/reorder'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'task_ids': taskIds}),
    );
    
    if (response.statusCode != 200) {
      throw Exception('Failed to reorder tasks');
    }
  }
}
