import 'package:flutter_test/flutter_test.dart';
import 'package:monitoramento/core/constants/api_constants.dart';
import 'package:monitoramento/features/auth/domain/models/auth_user.dart';

void main() {
  group('AuthUser Model Tests', () {
    test('should serialize and deserialize AuthUser correctly', () {
      final user = AuthUser(
        id: 'uuid-123',
        name: 'Dra. Renata Agrônoma',
        email: 'renata@fazenda.com.br',
        role: 'AGRONOMIST',
        accessToken: 'jwt-access-token-xyz',
        refreshToken: 'refresh-token-xyz',
      );

      final map = user.toMap();
      expect(map['id'], 'uuid-123');
      expect(map['email'], 'renata@fazenda.com.br');
      expect(map['role'], 'AGRONOMIST');

      final fromMap = AuthUser.fromMap(map);
      expect(fromMap.id, user.id);
      expect(fromMap.name, user.name);
      expect(fromMap.email, user.email);
      expect(fromMap.role, user.role);
      expect(fromMap.accessToken, user.accessToken);
      expect(fromMap.refreshToken, user.refreshToken);
    });

    test('should return correct display names for roles', () {
      final agronomist = AuthUser(
        id: '1',
        name: 'Renata',
        email: 'r@f.com',
        role: 'AGRONOMIST',
        accessToken: 't',
      );
      expect(agronomist.roleDisplayName, 'Engenheiro(a) Agrônomo(a)');

      final operator = AuthUser(
        id: '2',
        name: 'João',
        email: 'j@f.com',
        role: 'OPERATOR',
        accessToken: 't',
      );
      expect(operator.roleDisplayName, 'Técnico de Campo');

      final admin = AuthUser(
        id: '3',
        name: 'Admin',
        email: 'a@f.com',
        role: 'ADMIN',
        accessToken: 't',
      );
      expect(admin.roleDisplayName, 'Administrador');
    });

    test('ApiConstants should provide valid default URLs and endpoints', () {
      expect(ApiConstants.loginEndpoint, '/auth/login');
      expect(ApiConstants.registerEndpoint, '/auth/register');
      expect(ApiConstants.syncEndpoint, '/pest-records/sync');
      expect(ApiConstants.defaultBaseUrl, isNotEmpty);
    });
  });
}
