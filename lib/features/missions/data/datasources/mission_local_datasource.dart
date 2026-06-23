import 'dart:convert';

import 'package:hive/hive.dart';

abstract class MissionLocalDatasource {
  String? getRawMissions();
  Future<void> saveRawMissions(String json);
}

class MissionLocalDatasourceImpl implements MissionLocalDatasource {
  final Box<String> _box;
  static const _key = 'active';

  MissionLocalDatasourceImpl(this._box);

  @override
  String? getRawMissions() => _box.get(_key);

  @override
  Future<void> saveRawMissions(String json) => _box.put(_key, json);
}
