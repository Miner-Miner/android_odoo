import 'package:json_annotation/json_annotation.dart';

part 'assignment.g.dart';

double? _toNullableDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is String) {
    if (v.trim().isEmpty) return null;
    return double.tryParse(v);
  }
  return null;
}

dynamic _fromNullableDouble(double? v) => v;

@JsonSerializable()
class Assignment {
  final int id;
  final String name;
  final String state;

  @JsonKey(name: 'assign_time')
  final String? assignTime;

  @JsonKey(name: 'complete_time')
  final String? completeTime;

  @JsonKey(name: 'cancel_time')
  final String? cancelTime;

  final RouteData? route;
  final List<Task> tasks;
  final User? assigner;

  Assignment({
    required this.id,
    required this.name,
    required this.state,
    this.assignTime,
    this.completeTime,
    this.cancelTime,
    this.route,
    this.tasks = const [],
    this.assigner,
  });

  factory Assignment.fromJson(Map<String, dynamic> json) =>
      _$AssignmentFromJson(json);
  Map<String, dynamic> toJson() => _$AssignmentToJson(this);
}

@JsonSerializable()
class RouteData {
  final int id;
  final String? name;
  final int? waypoint;
  final List<Shop> shops;

  RouteData({
    required this.id,
    this.name,
    this.waypoint,
    this.shops = const [],
  });

  factory RouteData.fromJson(Map<String, dynamic> json) =>
      _$RouteDataFromJson(json);
  Map<String, dynamic> toJson() => _$RouteDataToJson(this);
}

@JsonSerializable()
class Shop {
  final int id;
  final String? name;
  final String? street;
  final String? city;
  final String? country;

  @JsonKey(fromJson: _toNullableDouble, toJson: _fromNullableDouble)
  final double? latitude;

  @JsonKey(fromJson: _toNullableDouble, toJson: _fromNullableDouble)
  final double? longitude;

  Shop({
    required this.id,
    this.name,
    this.street,
    this.city,
    this.country,
    this.latitude,
    this.longitude,
  });

  factory Shop.fromJson(Map<String, dynamic> json) => _$ShopFromJson(json);
  Map<String, dynamic> toJson() => _$ShopToJson(this);
}

@JsonSerializable()
class Task {
  final int id;
  final String name;

  @JsonKey(name: 'task_type')
  final String? taskType;

  final bool? complete;
  final List<Special> specials;

  Task({
    required this.id,
    required this.name,
    this.taskType,
    this.complete,
    this.specials = const [],
  });

  factory Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);
  Map<String, dynamic> toJson() => _$TaskToJson(this);
}

@JsonSerializable()
class Special {
  final int id;
  final String name;
  final List<SpecialLine> lines;

  Special({
    required this.id,
    required this.name,
    this.lines = const [],
  });

  factory Special.fromJson(Map<String, dynamic> json) =>
      _$SpecialFromJson(json);
  Map<String, dynamic> toJson() => _$SpecialToJson(this);
}

@JsonSerializable()
class SpecialLine {
  @JsonKey(name: 'line_id')
  final int lineId;

  @JsonKey(name: 'product_id')
  final int productId;

  @JsonKey(name: 'product_name')
  final String? productName;

  @JsonKey(name: 'default_code')
  final String? defaultCode;

  final String? uom;

  SpecialLine({
    required this.lineId,
    required this.productId,
    this.productName,
    this.defaultCode,
    this.uom,
  });

  factory SpecialLine.fromJson(Map<String, dynamic> json) =>
      _$SpecialLineFromJson(json);
  Map<String, dynamic> toJson() => _$SpecialLineToJson(this);
}

@JsonSerializable()
class User {
  final int id;
  final String name;

  User({required this.id, required this.name});

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
}
