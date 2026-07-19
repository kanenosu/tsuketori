/// 相手データ（要件 9.2）。
class Person {
  const Person({
    required this.id,
    required this.name,
    this.iconPath,
    this.phone,
    this.email,
    this.memo,
    this.isHidden = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 相手ID（必須）
  final String id;

  /// 名前（必須）
  final String name;

  /// アイコン（画像URLまたはローカルパス。任意）
  final String? iconPath;

  /// 電話番号（任意）
  final String? phone;

  /// メールアドレス（任意）
  final String? email;

  /// メモ（任意）
  final String? memo;

  /// 非表示フラグ（要件 13.3：取引が残る相手を直接削除せず非表示にする）。
  final bool isHidden;

  final DateTime createdAt;
  final DateTime updatedAt;

  Person copyWith({
    String? name,
    String? iconPath,
    String? phone,
    String? email,
    String? memo,
    bool? isHidden,
    DateTime? updatedAt,
  }) {
    return Person(
      id: id,
      name: name ?? this.name,
      iconPath: iconPath ?? this.iconPath,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      memo: memo ?? this.memo,
      isHidden: isHidden ?? this.isHidden,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'iconPath': iconPath,
      'phone': phone,
      'email': email,
      'memo': memo,
      'isHidden': isHidden,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Person.fromJson(Map<String, dynamic> json) {
    return Person(
      id: json['id'] as String,
      name: json['name'] as String,
      iconPath: json['iconPath'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      memo: json['memo'] as String?,
      isHidden: (json['isHidden'] as bool?) ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
