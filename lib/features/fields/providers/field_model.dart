class FieldModel {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double sizeSqm;
  final String visualId;
  final String? activeCropId;
  final String? activeCropName;

  // Recommendation status placeholder
  // It could be 'IRRIGATE', 'WAIT', 'GOOD', etc. when integrated
  // Default to 'GOOD' for now
  final String recommendationStatus;

  FieldModel({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.sizeSqm,
    required this.visualId,
    this.activeCropId,
    this.activeCropName,
    this.recommendationStatus = 'GOOD',
  });

  factory FieldModel.fromJson(Map<String, dynamic> json) {
    return FieldModel(
      id: json['id'],
      name: json['name'],
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      sizeSqm: (json['sizeSqm'] as num).toDouble(),
      visualId: json['visualId']?.toString() ?? 'VALLEY',
      activeCropId: json['activeCropId'],      activeCropName: json['activeCropName'],
      recommendationStatus: 'GOOD', // TODO: Map from backend if available
    );
  }
}
