// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'assignment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Assignment _$AssignmentFromJson(Map<String, dynamic> json) => Assignment(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  state: json['state'] as String,
  assignTime: json['assign_time'] as String?,
  completeTime: json['complete_time'] as String?,
  cancelTime: json['cancel_time'] as String?,
  route: json['route'] == null
      ? null
      : RouteData.fromJson(json['route'] as Map<String, dynamic>),
  tasks:
      (json['tasks'] as List<dynamic>?)
          ?.map((e) => Task.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  assigner: json['assigner'] == null
      ? null
      : User.fromJson(json['assigner'] as Map<String, dynamic>),
);

Map<String, dynamic> _$AssignmentToJson(Assignment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'state': instance.state,
      'assign_time': instance.assignTime,
      'complete_time': instance.completeTime,
      'cancel_time': instance.cancelTime,
      'route': instance.route,
      'tasks': instance.tasks,
      'assigner': instance.assigner,
    };

RouteData _$RouteDataFromJson(Map<String, dynamic> json) => RouteData(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String?,
  waypoint: (json['waypoint'] as num?)?.toInt(),
  shops:
      (json['shops'] as List<dynamic>?)
          ?.map((e) => Shop.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$RouteDataToJson(RouteData instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'waypoint': instance.waypoint,
  'shops': instance.shops,
};

Shop _$ShopFromJson(Map<String, dynamic> json) => Shop(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String?,
  street: json['street'] as String?,
  city: json['city'] as String?,
  country: json['country'] as String?,
  latitude: (json['latitude'] as num?)?.toDouble(),
  longitude: (json['longitude'] as num?)?.toDouble(),
);

Map<String, dynamic> _$ShopToJson(Shop instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'street': instance.street,
  'city': instance.city,
  'country': instance.country,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
};

Task _$TaskFromJson(Map<String, dynamic> json) => Task(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  taskType: json['taskType'] as String?,
  complete: json['complete'] as bool?,
  specials:
      (json['specials'] as List<dynamic>?)
          ?.map((e) => Special.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$TaskToJson(Task instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'taskType': instance.taskType,
  'complete': instance.complete,
  'specials': instance.specials,
};

Special _$SpecialFromJson(Map<String, dynamic> json) => Special(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  lines:
      (json['lines'] as List<dynamic>?)
          ?.map((e) => SpecialLine.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$SpecialToJson(Special instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'lines': instance.lines,
};

SpecialLine _$SpecialLineFromJson(Map<String, dynamic> json) => SpecialLine(
  lineId: (json['line_id'] as num).toInt(),
  productId: (json['product_id'] as num).toInt(),
  productName: json['product_name'] as String?,
  defaultCode: json['default_code'] as String?,
  uom: json['uom'] as String?,
);

Map<String, dynamic> _$SpecialLineToJson(SpecialLine instance) =>
    <String, dynamic>{
      'line_id': instance.lineId,
      'product_id': instance.productId,
      'product_name': instance.productName,
      'default_code': instance.defaultCode,
      'uom': instance.uom,
    };

User _$UserFromJson(Map<String, dynamic> json) =>
    User(id: (json['id'] as num).toInt(), name: json['name'] as String);

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
};
