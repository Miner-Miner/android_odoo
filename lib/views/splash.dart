import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:mobilepos/models/assignment_response.dart';
import 'package:mobilepos/services/api_service.dart';
import 'package:mobilepos/static/api.dart';
import 'package:mobilepos/views/home.dart';

class SplashScreen extends StatefulWidget {
  final int userId;
  const SplashScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late int userId;
  late ApiService apiService;

  @override
  void initState() {
    super.initState();
    userId = widget.userId; // assign here (widget is available in initState)
    final dio = Dio(BaseOptions(baseUrl: api_root_url));
    apiService = ApiService(dio, baseUrl: api_root_url);
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Use the passed userId (no hard-coded 6)
      final AssignmentResponse assignmentResponse =
          await apiService.getAssignments({
        "jsonrpc": "2.0",
        "params": {'user_id': userId},
      });

      debugPrint('AssignmentResponse: $assignmentResponse');

      final assignments = assignmentResponse.assignments;

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomePage(
            assignments: assignments,
          ),
        ),
      );
    } catch (e, st) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
      debugPrint('Error loading assignments: $e\n$st');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
