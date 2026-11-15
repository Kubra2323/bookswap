import 'package:bookswap/data/auth_repository.dart';
import 'package:bookswap/viewmodels/auth_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

void main() {
  late FakeAuthRepository repo;
  late AuthViewModel vm;

  setUp(() {
    repo = FakeAuthRepository();
    vm = AuthViewModel(repo);
  });

  tearDown(() => vm.dispose());

  test('rejects a non-university email without calling the repository', () async {
    await vm.register('ali@gmail.com', 'secret123');
    expect(vm.error, isNotNull);
    expect(repo.registerCalls, 0);
  });

  test('rejects a short password', () async {
    await vm.signIn('ali@agu.edu.tr', '123');
    expect(vm.error, contains('6 characters'));
  });

  test('sign in updates the user', () async {
    await vm.signIn('ali@agu.edu.tr', 'secret123');
    await Future<void>.delayed(Duration.zero); // let the stream deliver
    expect(vm.user?.email, 'ali@agu.edu.tr');
    expect(vm.error, isNull);
    expect(vm.busy, isFalse);
  });

  test('shows the friendly error from the repository', () async {
    repo.failWith = 'Wrong email or password.';
    await vm.signIn('ali@agu.edu.tr', 'secret123');
    expect(vm.error, 'Wrong email or password.');
    expect(vm.busy, isFalse);
  });

  test('register gives an unverified user', () async {
    await vm.register('ali@agu.edu.tr', 'secret123');
    await Future<void>.delayed(Duration.zero);
    expect(vm.user?.emailVerified, isFalse);
  });

  test('refreshUser loads the verified user', () async {
    await vm.register('ali@agu.edu.tr', 'secret123');
    await vm.refreshUser();
    expect(vm.user?.emailVerified, isTrue);
  });

  test('sign out clears the user', () async {
    await vm.signIn('ali@agu.edu.tr', 'secret123');
    await vm.signOut();
    await Future<void>.delayed(Duration.zero);
    expect(vm.user, isNull);
  });

  test('AuthFailure prints its message', () {
    expect(const AuthFailure('x').toString(), 'x');
  });
}
