import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:todo_flutter_app/core/failures.dart';
import 'package:todo_flutter_app/data/services/connectivity_service.dart';
import 'package:todo_flutter_app/domain/repositories/task_repository.dart';
import 'package:todo_flutter_app/features/tasks/controllers/sync_controller.dart';

class MockTaskRepository extends Mock implements TaskRepository {}

class MockConnectivityService extends Mock implements ConnectivityService {}

void main() {
  late MockTaskRepository repository;
  late MockConnectivityService connectivityService;
  late StreamController<bool> connectivityStream;

  setUp(() {
    repository = MockTaskRepository();
    connectivityService = MockConnectivityService();
    connectivityStream = StreamController<bool>.broadcast();

    when(
      () => connectivityService.onStatusChange,
    ).thenAnswer((_) => connectivityStream.stream);
  });

  tearDown(() async {
    await connectivityStream.close();
  });

  group('SyncController', () {
    test('start triggers sync when connected', () async {
      when(
        () => connectivityService.isConnected(),
      ).thenAnswer((_) async => true);
      when(() => repository.sync()).thenAnswer((_) async => null);

      final controller = SyncController(
        repository: repository,
        connectivityService: connectivityService,
      );
      addTearDown(controller.dispose);

      await controller.start();

      verify(() => repository.sync()).called(1);
      expect(controller.state.phase, SyncPhase.success);
    });

    test('connectivity regain triggers sync', () async {
      final responses = <bool>[false, true];
      when(
        () => connectivityService.isConnected(),
      ).thenAnswer((_) async => responses.removeAt(0));
      when(() => repository.sync()).thenAnswer((_) async => null);

      final controller = SyncController(
        repository: repository,
        connectivityService: connectivityService,
      );
      addTearDown(controller.dispose);

      await controller.start();

      connectivityStream.add(true);
      await Future<void>.delayed(Duration.zero);

      verify(() => repository.sync()).called(1);
    });

    test('triggerSync retries with exponential backoff', () async {
      when(
        () => connectivityService.isConnected(),
      ).thenAnswer((_) async => true);
      when(
        () => repository.sync(),
      ).thenAnswer((_) async => const ServerError('fail'));

      final delays = <Duration>[];
      final controller = SyncController(
        repository: repository,
        connectivityService: connectivityService,
        maxRetries: 2,
        delay: (delay) async => delays.add(delay),
      );
      addTearDown(controller.dispose);

      await controller.triggerSync();

      expect(delays, [const Duration(seconds: 1), const Duration(seconds: 2)]);
      expect(controller.state.phase, SyncPhase.error);
      expect(controller.state.failure, isA<ServerError>());
    });

    test('triggerSync returns NoConnection when offline', () async {
      when(
        () => connectivityService.isConnected(),
      ).thenAnswer((_) async => false);

      final controller = SyncController(
        repository: repository,
        connectivityService: connectivityService,
      );
      addTearDown(controller.dispose);

      await controller.triggerSync();

      expect(controller.state.phase, SyncPhase.error);
      expect(controller.state.failure, isA<NoConnection>());
      verifyNever(() => repository.sync());
    });
  });
}
