import 'package:creditbillsytems/core/database/database_helper.dart';
import 'package:creditbillsytems/core/security/password_hasher.dart';
import 'package:creditbillsytems/core/utils/id_generator.dart';
import 'package:creditbillsytems/core/auth/token_storage.dart';

/// Ensures a default admin account exists. Called after DB init.
Future<void> ensureAdminAccount(DatabaseHelper dbHelper, TokenStorage tokenStorage) async {
  const adminEmail = 'admin@gmail.com';
  const adminPassword = '123456';

  final db = await dbHelper.database;

  // Check for existing admin (case‑insensitive)
  final existing = await db.query(
    'users',
    where: 'LOWER(email) = ?',
    whereArgs: [adminEmail.toLowerCase()],
    limit: 1,
  );

  if (existing.isNotEmpty) {
    return; // Admin already present
  }

  final id = IdGenerator.generateUuid();
  final hashed = PasswordHasher.hashPassword(adminPassword);
  final now = DateTime.now().toIso8601String();

  await db.insert('users', {
    'id': id,
    'email': adminEmail,
    'password_hash': hashed,
    'display_name': 'Admin',
    'created_at': now,
  });

  // Create a session token for the admin (optional)
  final token = IdGenerator.generateUuid();
  await tokenStorage.saveToken(token, id, DateTime.now().add(const Duration(days: 30)));
}
