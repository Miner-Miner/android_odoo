import 'package:json_annotation/json_annotation.dart';

part 'sale_request.g.dart';

@JsonSerializable(explicitToJson: true)
class SaleOrderRequest {
  @JsonKey(name: 'user_id')
  final int userId;

  @JsonKey(name: 'customer_id')
  final int customerId;

  /// JSON expects keys as strings (parent product ids) and values as quantities.
  /// Example: { "21": 4, "42": 2 }
  @JsonKey(name: 'sale_orders')
  final Map<String, int> saleOrders;

  SaleOrderRequest({
    required this.userId,
    required this.customerId,
    required this.saleOrders,
  });

  factory SaleOrderRequest.fromJson(Map<String, dynamic> json) =>
      _$SaleOrderRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SaleOrderRequestToJson(this);
}
