import 'package:json_annotation/json_annotation.dart';

part 'product.g.dart';

@JsonSerializable()
class ProductVariant {
  final int id;
  final String name;
  final dynamic default_code;
  final dynamic barcode;
  final double? list_price;
  final double? standard_price;
  final String? currency;
  final String? uom;
  final double? weight;
  final double? volume;
  final String? description_sale;
  final String? image;

  ProductVariant({
    required this.id,
    required this.name,
    this.default_code,
    this.barcode,
    this.list_price,
    this.standard_price,
    this.currency,
    this.uom,
    this.weight,
    this.volume,
    this.description_sale,
    this.image,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) =>
      _$ProductVariantFromJson(json);
  Map<String, dynamic> toJson() => _$ProductVariantToJson(this);
}

@JsonSerializable()
class ProductTemplate {
  final int id;
  final String name;
  final dynamic default_code; // can be String or false(boolean)
  final dynamic barcode; // can be String or false(boolean)
  final String? category;
  @JsonKey(name: 'category_id')
  final int? categoryId;
  final String? type;
  final String? company;
  final double? list_price;
  final double? standard_price;
  final String? currency;
  final List<String>? taxes;
  final String? uom;
  final double? weight;
  final double? volume;
  final String? description;
  final String? description_sale;
  final String? description_purchase;
  final String? image;
  final List<ProductVariant>? variants;

  ProductTemplate({
    required this.id,
    required this.name,
    this.default_code,
    this.barcode,
    this.category,
    this.categoryId,
    this.type,
    this.company,
    this.list_price,
    this.standard_price,
    this.currency,
    this.taxes,
    this.uom,
    this.weight,
    this.volume,
    this.description,
    this.description_sale,
    this.description_purchase,
    this.image,
    this.variants,
  });

  factory ProductTemplate.fromJson(Map<String, dynamic> json) =>
      _$ProductTemplateFromJson(json);
  Map<String, dynamic> toJson() => _$ProductTemplateToJson(this);
}

@JsonSerializable()
class Category {
  final int id;
  final String name;
  final String? complete_name;

  Category({required this.id, required this.name, this.complete_name});

  factory Category.fromJson(Map<String, dynamic> json) =>
      _$CategoryFromJson(json);
  Map<String, dynamic> toJson() => _$CategoryToJson(this);
}

@JsonSerializable()
class Partner {
  final int id;
  final String name;
  final String? email;
  final String? phone;
  final String? mobile;
  final String? company_name;
  final bool? is_company;
  final int? customer_rank;
  final int? supplier_rank;
  final String? street;
  final String? city;
  final String? country;
  final String? image;

  Partner({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.mobile,
    this.company_name,
    this.is_company,
    this.customer_rank,
    this.supplier_rank,
    this.street,
    this.city,
    this.country,
    this.image,
  });

  factory Partner.fromJson(Map<String, dynamic> json) =>
      _$PartnerFromJson(json);
  Map<String, dynamic> toJson() => _$PartnerToJson(this);
}

@JsonSerializable()
class ProductResponse {
  // API sample doesn't include "status" in your last dump, but keep optional
  final String? status;

  @JsonKey(name: 'product_templates', defaultValue: <ProductTemplate>[])
  final List<ProductTemplate> productTemplates;

  @JsonKey(name: 'category', defaultValue: <Category>[])
  final List<Category> categories;

  @JsonKey(name: 'partner', defaultValue: <Partner>[])
  final List<Partner> partners;

  ProductResponse({
    this.status,
    this.productTemplates = const <ProductTemplate>[],
    this.categories = const <Category>[],
    this.partners = const <Partner>[],
  });

  factory ProductResponse.fromJson(Map<String, dynamic> json) =>
      _$ProductResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ProductResponseToJson(this);
}

extension ProductTemplateCopy on ProductTemplate {
  ProductTemplate copyWith({
    int? id,
    String? name,
    dynamic default_code,
    dynamic barcode,
    String? category,
    int? categoryId,
    String? type,
    String? company,
    double? list_price,
    double? standard_price,
    String? currency,
    List<String>? taxes,
    String? uom,
    double? weight,
    double? volume,
    String? description,
    String? description_sale,
    String? description_purchase,
    String? image,
    List<ProductVariant>? variants,
  }) {
    return ProductTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      default_code: default_code ?? this.default_code,
      barcode: barcode ?? this.barcode,
      category: category ?? this.category,
      categoryId: categoryId ?? this.categoryId,
      type: type ?? this.type,
      company: company ?? this.company,
      list_price: list_price ?? this.list_price,
      standard_price: standard_price ?? this.standard_price,
      currency: currency ?? this.currency,
      taxes: taxes ?? this.taxes,
      uom: uom ?? this.uom,
      weight: weight ?? this.weight,
      volume: volume ?? this.volume,
      description: description ?? this.description,
      description_sale: description_sale ?? this.description_sale,
      description_purchase: description_purchase ?? this.description_purchase,
      image: image ?? this.image,
      variants: variants ?? this.variants,
    );
  }
}