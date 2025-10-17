import 'package:flutter/material.dart';
import 'package:mobilepos/models/assignment.dart';

class TaskPage extends StatelessWidget {
  final List<Task> tasks;
  final Shop shop;

  const TaskPage({super.key, required this.shop, required this.tasks});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Tasks — ${shop.name}')),
      body: tasks.isEmpty
          ? const Center(child: Text('No tasks assigned'))
          : ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return ListTile(
                  leading: const Icon(Icons.task),
                  title: Text(task.name),
                  subtitle: task.specials.isNotEmpty
                      ? Text(task.specials.map((s) => s.name).join(', '))
                      : null,
                );
              },
            ),
    );
  }
}
