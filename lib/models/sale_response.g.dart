// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sale_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SaleOrderResponse _$SaleOrderResponseFromJson(Map<String, dynamic> json) =>
    SaleOrderResponse(
      status: json['status'] as String,
      message: json['message'] as String?,
      saleOrderId: _intFromDynamic(json['sale_order_id']),
      saleOrderName: json['sale_order_name'] as String?,
      customer: json['customer'] as String?,
      salesperson: json['salesperson'] as String?,
      total: _doubleFromDynamic(json['total']),
    );

Map<String, dynamic> _$SaleOrderResponseToJson(SaleOrderResponse instance) =>
    <String, dynamic>{
      'status': instance.status,
      'message': instance.message,
      'sale_order_id': instance.saleOrderId,
      'sale_order_name': instance.saleOrderName,
      'customer': instance.customer,
      'salesperson': instance.salesperson,
      'total': instance.total,
    };
