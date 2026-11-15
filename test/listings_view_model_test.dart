import 'package:bookswap/viewmodels/listings_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

void main() {
  late FakeListingRepository repo;
  late ListingsViewModel vm;

  setUp(() {
    repo = FakeListingRepository();
    vm = ListingsViewModel(repo)..start();
  });

  tearDown(() async {
    vm.dispose();
    await repo.controller.close();
  });

  test('starts in loading state, then shows listings', () async {
    expect(vm.loading, isTrue);
    repo.controller.add([sampleListing()]);
    await Future<void>.delayed(Duration.zero);
    expect(vm.loading, isFalse);
    expect(vm.visible, hasLength(1));
  });

  test('search filters by title and ISBN', () async {
    repo.controller.add([
      sampleListing(id: 'a', title: 'Calculus', isbn: '9780000000002'),
      sampleListing(id: 'b', title: 'Data Structures', isbn: '9780000000019'),
    ]);
    await Future<void>.delayed(Duration.zero);

    vm.setQuery('calc');
    expect(vm.visible.map((l) => l.id), ['a']);

    vm.setQuery('0019');
    expect(vm.visible.map((l) => l.id), ['b']);

    vm.setQuery('');
    expect(vm.visible, hasLength(2));
  });

  test('stream error shows a message', () async {
    repo.controller.addError(Exception('permission-denied'));
    await Future<void>.delayed(Duration.zero);
    expect(vm.loading, isFalse);
    expect(vm.error, isNotNull);
  });

  test('markSold calls the repository', () async {
    await vm.markSold('l1');
    expect(repo.soldIds, ['l1']);
  });
}
