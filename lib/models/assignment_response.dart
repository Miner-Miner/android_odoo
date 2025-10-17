import 'package:json_annotation/json_annotation.dart';
import 'package:mobilepos/models/assignment.dart';

part 'assignment_response.g.dart';

@JsonSerializable()
class AssignmentResponse {
  final String status;
  final String? message;
  final Map<String, dynamic>? user;
  final List<Assignment> assignments;

  AssignmentResponse({
    required this.status,
    this.message,
    this.user,
    this.assignments = const [],
  });

  /// Custom factory: if the server returns JSON-RPC shape {jsonrpc, id, result: {...}}
  /// we unwrap `result` and feed it to the generated deserializer.
  factory AssignmentResponse.fromJson(Map<String, dynamic> json) {
    final result = json['result'] as Map<String, dynamic>?;
    if (result != null) {
      return _$AssignmentResponseFromJson(result);
    }

    // Fallback: try direct shape or error structure
    return AssignmentResponse(
      status: (json['status'] as String?) ?? (json['error'] != null ? 'error' : 'unknown'),
      message: json['message'] as String? ?? json['error']?['message'] as String?,
      user: json['user'] as Map<String, dynamic>?,
      assignments: const [],
    );
  }

  Map<String, dynamic> toJson() => _$AssignmentResponseToJson(this);
}
