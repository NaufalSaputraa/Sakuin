/// Domain models for multi-currency support.
///
/// [CurrencyModel] describes a supported currency (code, name, symbol).
/// [CurrencyRateModel] holds an offline exchange rate relative to IDR.

class CurrencyModel {
  final String code; // 'IDR', 'USD', 'SGD', ...
  final String name; // 'Indonesian Rupiah'
  final String symbol; // 'Rp ', '$', ...

  const CurrencyModel({
    required this.code,
    required this.name,
    required this.symbol,
  });

  factory CurrencyModel.fromJson(Map<String, dynamic> json) {
    return CurrencyModel(
      code: json['code'] as String,
      name: json['name'] as String,
      symbol: json['symbol'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'code': code,
        'name': name,
        'symbol': symbol,
      };

  CurrencyModel copyWith({
    String? code,
    String? name,
    String? symbol,
  }) {
    return CurrencyModel(
      code: code ?? this.code,
      name: name ?? this.name,
      symbol: symbol ?? this.symbol,
    );
  }
}

class CurrencyRateModel {
  final String code;
  final String name;
  final double rateToIdr; // 1 unit of currency = rateToIdr IDR
  final bool isBase;
  final DateTime updatedAt;

  const CurrencyRateModel({
    required this.code,
    required this.name,
    required this.rateToIdr,
    required this.isBase,
    required this.updatedAt,
  });

  factory CurrencyRateModel.fromJson(Map<String, dynamic> json) {
    return CurrencyRateModel(
      code: json['code'] as String,
      name: json['name'] as String,
      rateToIdr: (json['rateToIdr'] as num).toDouble(),
      isBase: json['isBase'] as bool? ?? false,
      updatedAt: json['updatedAt'] is String
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.fromMillisecondsSinceEpoch(json['updatedAt'] as int),
    );
  }

  Map<String, dynamic> toJson() => {
        'code': code,
        'name': name,
        'rateToIdr': rateToIdr,
        'isBase': isBase,
        'updatedAt': updatedAt.toIso8601String(),
      };

  /// Build from a Drift [CurrencyRatesData] entry.
  factory CurrencyRateModel.fromEntry(dynamic entry) {
    return CurrencyRateModel(
      code: entry.code as String,
      name: entry.name as String,
      rateToIdr: (entry.rateToIdr as num).toDouble(),
      isBase: entry.isBase as bool,
      updatedAt: entry.updatedAt as DateTime,
    );
  }

  CurrencyRateModel copyWith({
    String? code,
    String? name,
    double? rateToIdr,
    bool? isBase,
    DateTime? updatedAt,
  }) {
    return CurrencyRateModel(
      code: code ?? this.code,
      name: name ?? this.name,
      rateToIdr: rateToIdr ?? this.rateToIdr,
      isBase: isBase ?? this.isBase,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
