class FamilyModel {
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final int memberCount;

  FamilyModel({
    required this.id,
    required this.name,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.deletedAt,
    this.memberCount = 0,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  FamilyModel copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    int? memberCount,
  }) {
    return FamilyModel(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      memberCount: memberCount ?? this.memberCount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      if (deletedAt != null) 'deletedAt': deletedAt!.toIso8601String(),
      'memberCount': memberCount,
    };
  }

  Map<String, dynamic> toFirestore() {
    return toMap();
  }

  factory FamilyModel.fromMap(Map<String, dynamic> map) {
    return FamilyModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      createdAt: map['createdAt'] != null ? DateTime.tryParse(map['createdAt'] as String) : null,
      updatedAt: map['updatedAt'] != null ? DateTime.tryParse(map['updatedAt'] as String) : null,
      deletedAt: map['deletedAt'] != null ? DateTime.tryParse(map['deletedAt'] as String) : null,
      memberCount: map['memberCount'] ?? 0,
    );
  }

  factory FamilyModel.fromFirestore(Map<String, dynamic> doc) {
    return FamilyModel.fromMap(doc);
  }
}

