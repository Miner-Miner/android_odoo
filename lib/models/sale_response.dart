import 'package:json_annotation/json_annotation.dart';

part 'sale_response.g.dart';

int? _intFromDynamic(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  final parsed = int.tryParse(v.toString());
  return parsed;
}

double? _doubleFromDynamic(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

@JsonSerializable()
class SaleOrderResponse {
  final String status;
  final String? message;

  @JsonKey(name: 'sale_order_id', fromJson: _intFromDynamic)
  final int? saleOrderId;

  @JsonKey(name: 'sale_order_name')
  final String? saleOrderName;

  final String? customer;
  final String? salesperson;

  /// server returns numeric total — normalize to double
  @JsonKey(fromJson: _doubleFromDynamic)
  final double? total;

  SaleOrderResponse({
    required this.status,
    this.message,
    this.saleOrderId,
    this.saleOrderName,
    this.customer,
    this.salesperson,
    this.total,
  });

  /// ✅ Handles both plain and JSON-RPC wrapped responses
  factory SaleOrderResponse.fromJson(Map<String, dynamic> json) {
    // If it's JSON-RPC wrapped like { "result": {...} }
    final result = json['result'] as Map<String, dynamic>?;

    if (result != null) {
      return _$SaleOrderResponseFromJson(result);
    }

    // If it's already flat { "status": "...", "sale_order_id": ... }
    return _$SaleOrderResponseFromJson(json);
  }

  Map<String, dynamic> toJson() => _$SaleOrderResponseToJson(this);
}
