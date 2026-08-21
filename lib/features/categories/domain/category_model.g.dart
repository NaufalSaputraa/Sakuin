// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CategoryModel _$CategoryModelFromJson(Map<String, dynamic> json) =>
    CategoryModel(
      id: (json['id'] as num).toInt(),
      key: json['key'] as String,
      name: json['name'] as String,
      nameId: json['nameId'] as String?,
      icon: json['icon'] as String,
      color: json['color'] as String,
      parentId: (json['parentId'] as num?)?.toInt(),
      isDefault: json['isDefault'] as bool? ?? false,
      isIncome: json['isIncome'] as bool? ?? false,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$CategoryModelToJson(CategoryModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'key': instance.key,
      'name': instance.name,
      'nameId': instance.nameId,
      'icon': instance.icon,
      'color': instance.color,
      'parentId': instance.parentId,
      'isDefault': instance.isDefault,
      'isIncome': instance.isIncome,
      'sortOrder': instance.sortOrder,
    };
