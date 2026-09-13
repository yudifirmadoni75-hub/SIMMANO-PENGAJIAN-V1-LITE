import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();
  static final instance = AppDatabase._();
  Database? _database;

  Future<void> initialize() async {
    if (_database != null) return;
    final path = p.join(await getDatabasesPath(), 'simmano_pengajian_v1_lite.db');
    _database = await openDatabase(path, version: 2, onCreate: _create, onUpgrade: _upgrade);
  }

  Future<void> _create(Database db, int version) async {
    await db.execute('CREATE TABLE users (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, role TEXT NOT NULL, member_id INTEGER, is_active INTEGER NOT NULL DEFAULT 1, created_at TEXT NOT NULL)');
    await db.execute('CREATE TABLE app_settings (key TEXT PRIMARY KEY, value TEXT)');
    await _createGroupTables(db);
  }

  Future<void> _upgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) await _createGroupTables(db);
  }

  Future<void> _createGroupTables(Database db) async {
    await db.execute('CREATE TABLE groups (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, description TEXT, is_active INTEGER NOT NULL DEFAULT 1, created_at TEXT NOT NULL)');
    await db.execute('CREATE TABLE subgroups (id INTEGER PRIMARY KEY AUTOINCREMENT, group_id INTEGER NOT NULL, name TEXT NOT NULL, is_active INTEGER NOT NULL DEFAULT 1, created_at TEXT NOT NULL, UNIQUE(group_id, name), FOREIGN KEY(group_id) REFERENCES groups(id))');
    await db.execute('CREATE TABLE members (id INTEGER PRIMARY KEY AUTOINCREMENT, member_code TEXT NOT NULL UNIQUE, name TEXT NOT NULL, phone TEXT, address TEXT, is_active INTEGER NOT NULL DEFAULT 1, notes TEXT, created_at TEXT NOT NULL)');
    await db.execute('CREATE TABLE membership_histories (id INTEGER PRIMARY KEY AUTOINCREMENT, member_id INTEGER NOT NULL, subgroup_id INTEGER NOT NULL, effective_from TEXT NOT NULL, effective_until TEXT, created_at TEXT NOT NULL, FOREIGN KEY(member_id) REFERENCES members(id), FOREIGN KEY(subgroup_id) REFERENCES subgroups(id))');
  }

  Database get db => _database ?? (throw StateError('Database belum diinisialisasi.'));

  Future<List<Map<String, Object?>>> groups() => db.query('groups', orderBy: 'is_active DESC, name ASC');
  Future<int> addGroup(String name, String description) => db.insert('groups', {'name': name, 'description': description, 'is_active': 1, 'created_at': DateTime.now().toIso8601String()});
  Future<int> toggleGroup(int id, bool active) => db.update('groups', {'is_active': active ? 1 : 0}, where: 'id=?', whereArgs: [id]);
  Future<List<Map<String, Object?>>> subgroups(int groupId) => db.query('subgroups', where: 'group_id=?', whereArgs: [groupId], orderBy: 'is_active DESC, name ASC');
  Future<int> addSubgroup(int groupId, String name) => db.insert('subgroups', {'group_id': groupId, 'name': name, 'is_active': 1, 'created_at': DateTime.now().toIso8601String()});
  Future<int> toggleSubgroup(int id, bool active) => db.update('subgroups', {'is_active': active ? 1 : 0}, where: 'id=?', whereArgs: [id]);
  Future<List<Map<String, Object?>>> members() => db.rawQuery('''SELECT m.*, s.name AS subgroup_name, g.name AS group_name FROM members m LEFT JOIN membership_histories h ON h.member_id=m.id AND h.effective_until IS NULL LEFT JOIN subgroups s ON s.id=h.subgroup_id LEFT JOIN groups g ON g.id=s.group_id ORDER BY m.is_active DESC, m.name ASC''');
  Future<int> addMember(String code, String name, String phone, String address) => db.insert('members', {'member_code': code, 'name': name, 'phone': phone, 'address': address, 'is_active': 1, 'created_at': DateTime.now().toIso8601String()});
  Future<int> toggleMember(int id, bool active) => db.update('members', {'is_active': active ? 1 : 0}, where: 'id=?', whereArgs: [id]);
  Future<void> assignMember(int memberId, int subgroupId, String effectiveFrom) async {
    await db.transaction((txn) async {
      await txn.update('membership_histories', {'effective_until': effectiveFrom}, where: 'member_id=? AND effective_until IS NULL', whereArgs: [memberId]);
      await txn.insert('membership_histories', {'member_id': memberId, 'subgroup_id': subgroupId, 'effective_from': effectiveFrom, 'created_at': DateTime.now().toIso8601String()});
    });
  }
}
