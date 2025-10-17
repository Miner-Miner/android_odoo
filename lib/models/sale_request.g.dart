// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sale_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SaleOrderRequest _$SaleOrderRequestFromJson(Map<String, dynamic> json) =>
    SaleOrderRequest(
      userId: (json['user_id'] as num).toInt(),
      customerId: (json['customer_id'] as num).toInt(),
      saleOrders: Map<String, int>.from(json['sale_orders'] as Map),
    );

Map<String, dynamic> _$SaleOrderRequestToJson(SaleOrderRequest instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'customer_id': instance.customerId,
      'sale_orders': instance.saleOrders,
    };
