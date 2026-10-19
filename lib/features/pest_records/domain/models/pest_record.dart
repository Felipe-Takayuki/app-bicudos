import 'package:intl/intl.dart';

class PestRecord {
  final String id;
  final String pestName;
  final int quantity;
  final String notes;
  final double latitude;
  final double longitude;
  final double? altitude;
  final double? accuracy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? imagePath;

  PestRecord({
    required this.id,
    required this.pestName,
    required this.quantity,
    this.notes = '',
    required this.latitude,
    required this.longitude,
    this.altitude,
    this.accuracy,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.imagePath,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  PestRecord copyWith({
    String? id,
    String? pestName,
    int? quantity,
    String? notes,
    double? latitude,
    double? longitude,
    double? altitude,
    double? accuracy,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? imagePath,
  }) {
    return PestRecord(
      id: id ?? this.id,
      pestName: pestName ?? this.pestName,
      quantity: quantity ?? this.quantity,
      notes: notes ?? this.notes,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      altitude: altitude ?? this.altitude,
      accuracy: accuracy ?? this.accuracy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  /// SQLite database mapping
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'pest_name': pestName,
      'quantity': quantity,
      'crop': '', // DB backwards compatibility
      'plot': '', // DB backwards compatibility
      'growth_stage': '', // DB backwards compatibility
      'notes': notes,
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
      'accuracy': accuracy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'image_path': imagePath,
    };
  }

  factory PestRecord.fromMap(Map<String, dynamic> map) {
    return PestRecord(
      id: map['id'] as String,
      pestName: map['pest_name'] as String,
      quantity: map['quantity'] as int,
      notes: (map['notes'] as String?) ?? '',
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      altitude: map['altitude'] != null ? (map['altitude'] as num).toDouble() : null,
      accuracy: map['accuracy'] != null ? (map['accuracy'] as num).toDouble() : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      imagePath: map['image_path'] as String?,
    );
  }

  /// Format date for display (e.g. 27/08/2026 16:30)
  String get formattedDate {
    return DateFormat('dd/MM/yyyy HH:mm').format(createdAt);
  }

  /// Format date only (e.g. 27/08/2026)
  String get formattedDateOnly {
    return DateFormat('dd/MM/yyyy').format(createdAt);
  }

  /// WKT (Well-Known Text) representation for GIS tools
  String get wktPoint => 'POINT($longitude $latitude)';

  /// GeoJSON Feature dictionary conforming to RFC 7946
  Map<String, dynamic> toGeoJsonFeature() {
    return {
      'type': 'Feature',
      'id': id,
      'properties': {
        'id': id,
        'praga': pestName,
        'quantidade': quantity,
        'observacoes': notes,
        'data_hora': createdAt.toIso8601String(),
        'data_formatada': formattedDate,
        'latitude': latitude,
        'longitude': longitude,
        'altitude_m': altitude,
        'precisao_gps_m': accuracy,
      },
      'geometry': {
        'type': 'Point',
        'coordinates': [
          longitude, // GeoJSON uses [X, Y] = [longitude, latitude]
          latitude,
          if (altitude != null) altitude else 0.0,
        ],
      },
    };
  }

  /// Header row for CSV export
  static List<String> get csvHeaders => [
        'id',
        'praga',
        'quantidade',
        'observacoes',
        'data_iso',
        'data_formatada',
        'latitude',
        'longitude',
        'altitude_m',
        'precisao_m',
        'wkt_geom',
      ];

  /// Data row for CSV export
  List<dynamic> toCsvRow() => [
        id,
        pestName,
        quantity,
        notes,
        createdAt.toIso8601String(),
        formattedDate,
        latitude,
        longitude,
        altitude ?? '',
        accuracy != null ? accuracy!.toStringAsFixed(1) : '',
        wktPoint,
      ];
}
