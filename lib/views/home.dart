// home.dart
import 'package:flutter/material.dart';
import 'package:mobilepos/models/assignment.dart';
import 'package:mobilepos/views/assignment_map.dart';

class HomePage extends StatelessWidget {
  final List<Assignment> assignments;

  const HomePage({super.key, required this.assignments});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assignments'),
      ),
      body: assignments.isEmpty
          ? const Center(child: Text('No assignments available'))
          : ListView.builder(
              itemCount: assignments.length,
              itemBuilder: (context, index) {
                final assignment = assignments[index];
                return InkWell(
                  onTap: () {
                    // Navigate to map page and pass shops (if any)
                    final shops = assignment.route?.shops ?? <Shop>[];
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AssignmentMapPage(
                          assignmentName: assignment.name,
                          shops: shops,
                          tasks: assignment.tasks,
                        ),
                      ),
                    );
                  },
                  child: Card(
                    margin: const EdgeInsets.all(8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Assignment header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                assignment.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              Chip(
                                label: Text(
                                  assignment.state.toUpperCase(),
                                  style: const TextStyle(color: Colors.white),
                                ),
                                backgroundColor: _getStateColor(assignment.state),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Assigner info
                          if (assignment.assigner != null)
                            Text('Assigned by: ${assignment.assigner!.name}'),

                          // Route info
                          if (assignment.route != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      'Route: ${assignment.route!.name ?? '—'} (${assignment.route!.waypoint} shops)'),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: assignment.route!.shops
                                        .map((shop) => Chip(
                                              label: Text(shop.name ?? 'Shop ${shop.id}'),
                                            ))
                                        .toList(),
                                  ),
                                ],
                              ),
                            ),

                          // Tasks + specials
                          if (assignment.tasks.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: assignment.tasks.map((task) {
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Task: ${task.name}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      if (task.specials.isNotEmpty)
                                        Wrap(
                                          spacing: 4,
                                          children: task.specials
                                              .map((s) => Chip(label: Text(s.name)))
                                              .toList(),
                                        ),
                                      const SizedBox(height: 6),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  // Color based on assignment state
  Color _getStateColor(String state) {
    switch (state) {
      case 'in_progress':
        return Colors.orange;
      case 'done':
        return Colors.green;
      case 'cancel':
        return Colors.red;
      case 'draft':
      default:
        return Colors.grey;
    }
  }
}
