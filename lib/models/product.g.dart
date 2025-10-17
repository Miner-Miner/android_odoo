// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductVariant _$ProductVariantFromJson(Map<String, dynamic> json) =>
    ProductVariant(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      default_code: json['default_code'],
      barcode: json['barcode'],
      list_price: (json['list_price'] as num?)?.toDouble(),
      standard_price: (json['standard_price'] as num?)?.toDouble(),
      currency: json['currency'] as String?,
      uom: json['uom'] as String?,
      weight: (json['weight'] as num?)?.toDouble(),
      volume: (json['volume'] as num?)?.toDouble(),
      description_sale: json['description_sale'] as String?,
      image: json['image'] as String?,
    );

Map<String, dynamic> _$ProductVariantToJson(ProductVariant instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'default_code': instance.default_code,
      'barcode': instance.barcode,
      'list_price': instance.list_price,
      'standard_price': instance.standard_price,
      'currency': instance.currency,
      'uom': instance.uom,
      'weight': instance.weight,
      'volume': instance.volume,
      'description_sale': instance.description_sale,
      'image': instance.image,
    };

ProductTemplate _$ProductTemplateFromJson(Map<String, dynamic> json) =>
    ProductTemplate(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      default_code: json['default_code'],
      barcode: json['barcode'],
      category: json['category'] as String?,
      categoryId: (json['category_id'] as num?)?.toInt(),
      type: json['type'] as String?,
      company: json['company'] as String?,
      list_price: (json['list_price'] as num?)?.toDouble(),
      standard_price: (json['standard_price'] as num?)?.toDouble(),
      currency: json['currency'] as String?,
      taxes: (json['taxes'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      uom: json['uom'] as String?,
      weight: (json['weight'] as num?)?.toDouble(),
      volume: (json['volume'] as num?)?.toDouble(),
      description: json['description'] as String?,
      description_sale: json['description_sale'] as String?,
      description_purchase: json['description_purchase'] as String?,
      image: json['image'] as String?,
      variants: (json['variants'] as List<dynamic>?)
          ?.map((e) => ProductVariant.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ProductTemplateToJson(ProductTemplate instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'default_code': instance.default_code,
      'barcode': instance.barcode,
      'category': instance.category,
      'category_id': instance.categoryId,
      'type': instance.type,
      'company': instance.company,
      'list_price': instance.list_price,
      'standard_price': instance.standard_price,
      'currency': instance.currency,
      'taxes': instance.taxes,
      'uom': instance.uom,
      'weight': instance.weight,
      'volume': instance.volume,
      'description': instance.description,
      'description_sale': instance.description_sale,
      'description_purchase': instance.description_purchase,
      'image': instance.image,
      'variants': instance.variants,
    };

Category _$CategoryFromJson(Map<String, dynamic> json) => Category(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  complete_name: json['complete_name'] as String?,
);

Map<String, dynamic> _$CategoryToJson(Category instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'complete_name': instance.complete_name,
};

Partner _$PartnerFromJson(Map<String, dynamic> json) => Partner(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  email: json['email'] as String?,
  phone: json['phone'] as String?,
  mobile: json['mobile'] as String?,
  company_name: json['company_name'] as String?,
  is_company: json['is_company'] as bool?,
  customer_rank: (json['customer_rank'] as num?)?.toInt(),
  supplier_rank: (json['supplier_rank'] as num?)?.toInt(),
  street: json['street'] as String?,
  city: json['city'] as String?,
  country: json['country'] as String?,
  image: json['image'] as String?,
);

Map<String, dynamic> _$PartnerToJson(Partner instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'email': instance.email,
  'phone': instance.phone,
  'mobile': instance.mobile,
  'company_name': instance.company_name,
  'is_company': instance.is_company,
  'customer_rank': instance.customer_rank,
  'supplier_rank': instance.supplier_rank,
  'street': instance.street,
  'city': instance.city,
  'country': instance.country,
  'image': instance.image,
};

ProductResponse _$ProductResponseFromJson(Map<String, dynamic> json) =>
    ProductResponse(
      status: json['status'] as String?,
      productTemplates:
          (json['product_templates'] as List<dynamic>?)
              ?.map((e) => ProductTemplate.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      categories:
          (json['category'] as List<dynamic>?)
              ?.map((e) => Category.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      partners:
          (json['partner'] as List<dynamic>?)
              ?.map((e) => Partner.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$ProductResponseToJson(ProductResponse instance) =>
    <String, dynamic>{
      'status': instance.status,
      'product_templates': instance.productTemplates,
      'category': instance.categories,
      'partner': instance.partners,
    };
