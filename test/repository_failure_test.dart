import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:tsuketori/repositories/app_repository.dart';
import 'package:tsuketori/services/backup_codec.dart';
import 'package:tsuketori/state/app_state.dart';

class RejectingStore extends InMemorySharedPreferencesStore {
  RejectingStore() : super.empty();
  bool rejectWrite = false;
  bool rejectRead = false;

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    if (rejectWrite) return false;
    return super.setValue(valueType, key, value);
  }

  @override
  Future<Map<String, Object>> getAll() async {
    if (rejectRead) throw StateError('storage offline');
    return super.getAll();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final readAlsoFails in [false, true]) {
    test(
      'failed platform write cannot leak imported data through cache; reload failure=$readAlsoFails',
      () async {
        SharedPreferences.setMockInitialValues({});
        final store = RejectingStore();
        SharedPreferencesStorePlatform.instance = store;
        final repository = AppRepository();
        final state = AppState(repository: repository);
        await state.load();
        await state.addPerson(name: 'Preserve fixture');
        final empty = BackupCodec.decode(
          BackupCodec.encode(const AppData.empty()),
        );
        store.rejectWrite = true;
        store.rejectRead = readAlsoFails;
        await expectLater(
          state.restoreBackup(empty, expectedRevision: state.revision),
          throwsStateError,
        );
        expect(state.people.single.name, 'Preserve fixture');
        if (readAlsoFails) {
          await expectLater(repository.load(), throwsStateError);
        }
        store.rejectRead = false;
        expect(
          (await repository.load()).people.single.name,
          'Preserve fixture',
        );
        store.rejectWrite = false;
        await state.restoreBackup(empty, expectedRevision: state.revision);
        expect((await repository.load()).people, isEmpty);
      },
    );
  }
}
