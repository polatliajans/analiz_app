import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kriptoanaliz/data/auth_api.dart';
import 'package:kriptoanaliz/providers/auth_provider.dart';
import 'package:kriptoanaliz/services/firebase_auth_service.dart';

final _log = <String>[];

class _Firebase implements FirebaseAuthService {
  final String? code;
  final bool revokeThrows;
  _Firebase({this.code, this.revokeThrows = false});

  @override
  Future<String?> prepareAppleRevocation() async {
    _log.add('prepare');
    return code;
  }

  @override
  Future<void> revokeAppleToken(String authorizationCode) async {
    _log.add('revoke:$authorizationCode');
    if (revokeThrows) throw Exception('revoke failed');
  }

  @override
  Future<void> signOut() async => _log.add('signOut');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Api extends AuthApi {
  final bool fail;
  _Api({this.fail = false});

  @override
  Future<void> deleteAccount(String token) async {
    _log.add('serverDelete');
    if (fail) throw AuthException('server down');
  }
}

class _Storage implements FlutterSecureStorage {
  @override
  Future<String?> read({
    required String key,
    dynamic iOptions,
    dynamic aOptions,
    dynamic lOptions,
    dynamic webOptions,
    dynamic mOptions,
    dynamic wOptions,
  }) async => 'tok';

  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

Future<ProviderContainer> _signedIn(_Firebase fb, _Api api) async {
  _log.clear();
  final c = ProviderContainer(
    overrides: [
      firebaseAuthServiceProvider.overrideWithValue(fb),
      authApiProvider.overrideWithValue(api),
      secureStorageProvider.overrideWithValue(_Storage()),
    ],
  );
  addTearDown(c.dispose);
  c.listen(authProvider, (_, _) {});
  c.read(authProvider.notifier).state = const AuthState(token: 'tok');
  return c;
}

void main() {
  test('Apple: server deletes first, then the token is revoked', () async {
    final c = await _signedIn(_Firebase(code: 'abc'), _Api());
    await c.read(authProvider.notifier).deleteAccount();
    expect(_log, ['prepare', 'serverDelete', 'revoke:abc', 'signOut']);
    expect(c.read(authProvider).token, isNull);
  });

  test('server failure: Apple token is NOT revoked, session kept', () async {
    final c = await _signedIn(_Firebase(code: 'abc'), _Api(fail: true));
    await expectLater(
      c.read(authProvider.notifier).deleteAccount(),
      throwsA(isA<AuthException>()),
    );
    expect(_log, ['prepare', 'serverDelete']);
    expect(_log.any((e) => e.startsWith('revoke')), isFalse);
    expect(c.read(authProvider).token, 'tok');
  });

  test('revoke failure does not block the finished deletion', () async {
    final c = await _signedIn(
      _Firebase(code: 'abc', revokeThrows: true),
      _Api(),
    );
    await c.read(authProvider.notifier).deleteAccount();
    expect(_log, ['prepare', 'serverDelete', 'revoke:abc', 'signOut']);
    expect(c.read(authProvider).token, isNull);
  });

  test('non-Apple users never revoke', () async {
    final c = await _signedIn(_Firebase(), _Api());
    await c.read(authProvider.notifier).deleteAccount();
    expect(_log, ['prepare', 'serverDelete', 'signOut']);
  });
}
