import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../providers/task_provider.dart';
import '../widgets/task_card.dart';
import 'task_form_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  final List<String> _statuses = ['All', 'To-Do', 'In Progress', 'Done'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().fetchTasks();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      context.read<TaskProvider>().setSearchQuery(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Flodo Tasks', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: Consumer<TaskProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading && provider.tasks.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.error != null && provider.tasks.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(provider.error!),
                        ElevatedButton(
                          onPressed: () => provider.fetchTasks(),
                          child: const Text('Retry'),
                        )
                      ],
                    ),
                  );
                }

                if (provider.tasks.isEmpty) {
                  return const Center(
                    child: Text(
                      'No tasks found. Create one!',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => provider.fetchTasks(),
                  child: ReorderableListView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: provider.tasks.length,
                    onReorder: (oldIndex, newIndex) {
                      provider.reorderTasks(oldIndex, newIndex);
                    },
                    itemBuilder: (context, index) {
                      final task = provider.tasks[index];
                      return TaskCard(
                        key: ValueKey(task.id),
                        task: task,
                        searchQuery: provider.searchQuery,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TaskFormScreen(task: task),
                            ),
                          );
                        },
                        onDelete: () => _confirmDelete(context, task.id),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const TaskFormScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('New Task'),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search tasks...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 40,
            child: Consumer<TaskProvider>(
              builder: (context, provider, _) {
                return ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _statuses.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final status = _statuses[index];
                    final isSelected = provider.statusFilter == status;
                    return ChoiceChip(
                      label: Text(status),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          provider.setStatusFilter(status);
                        }
                      },
                      selectedColor: Theme.of(context).colorScheme.primaryContainer,
                      labelStyle: TextStyle(
                        color: isSelected ? Theme.of(context).colorScheme.primary : Colors.black87,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, int id) async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      context.read<TaskProvider>().deleteTask(id);
    }
  }
}
