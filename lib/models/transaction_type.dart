/// 取引種別（貸した／借りた）。
///
/// - [lend]  : ユーザーが相手にお金を渡した／立て替えた（受け取る予定）。
/// - [borrow]: ユーザーが相手からお金を受け取った／立て替えてもらった（返す予定）。
enum TransactionType {
  lend,
  borrow;

  /// 画面表示用のラベル。
  String get label {
    switch (this) {
      case TransactionType.lend:
        return '貸した';
      case TransactionType.borrow:
        return '借りた';
    }
  }

  /// 永続化用の文字列。
  String get storageValue => name;

  static TransactionType fromStorage(String value) {
    return TransactionType.values.firstWhere(
      (t) => t.name == value,
      orElse: () => TransactionType.lend,
    );
  }
}
