import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:todo_flutter_app/core/failures.dart';
import 'package:todo_flutter_app/data/services/connectivity_service.dart';
import 'package:todo_flutter_app/domain/repositories/task_repository.dart';

enum SyncPhase { idle, syncing, success, error }

class SyncStatus {
  const SyncStatus({required this.phase, this.failure, this.lastSyncedAt});

  const SyncStatus.idle() : this(phase: SyncPhase.idle);

  const SyncStatus.syncing({DateTime? lastSyncedAt})
    : this(phase: SyncPhase.syncing, lastSyncedAt: lastSyncedAt);

  const SyncStatus.success({required DateTime lastSyncedAt})
    : this(phase: SyncPhase.success, lastSyncedAt: lastSyncedAt);

  const SyncStatus.error({
    required NetworkFailure failure,
    DateTime? lastSyncedAt,
  }) : this(
         phase: SyncPhase.error,
         failure: failure,
         lastSyncedAt: lastSyncedAt,
       );

  final SyncPhase phase;
  final NetworkFailure? failure;
  final DateTime? lastSyncedAt;

  bool get isSyncing => phase == SyncPhase.syncing;
  bool get hasError => phase == SyncPhase.error;
}

class SyncController extends StateNotifier<SyncStatus> {
  SyncController({
    required TaskRepository repository,
    required ConnectivityService connectivityService,
    Duration baseBackoff = const Duration(seconds: 1),
    Duration maxBackoff = const Duration(seconds: 30),
    int maxRetries = 3,
    Future<void> Function(Duration delay) delay = Future<void>.delayed,
  }) : _repository = repository,
       _connectivityService = connectivityService,
       _baseBackoff = baseBackoff,
       _maxBackoff = maxBackoff,
       _maxRetries = maxRetries,
       _delay = delay,
       super(const SyncStatus.idle());

  final TaskRepository _repository;
  final ConnectivityService _connectivityService;
  final Duration _baseBackoff;
  final Duration _maxBackoff;
  final int _maxRetries;
  final Future<void> Function(Duration delay) _delay;

  StreamSubscription<bool>? _subscription;
  bool _started = false;

  Future<void> start() async {
    if (_started) return;
    _started = true;

    _subscription = _connectivityService.onStatusChange.listen((isConnected) {
      if (isConnected) {
        triggerSync();
      }
    });

    final connected = await _connectivityService.isConnected();
    if (connected) {
      await triggerSync();
    }
  }

  Future<void> triggerSync() async {
    if (state.isSyncing) return;

    final connected = await _connectivityService.isConnected();
    if (!connected) {
      state = SyncStatus.error(
        failure: const NoConnection(),
        lastSyncedAt: state.lastSyncedAt,
      );
      return;
    }

    state = SyncStatus.syncing(lastSyncedAt: state.lastSyncedAt);

    NetworkFailure? failure;
    for (var attempt = 0; attempt <= _maxRetries; attempt++) {
      failure = await _repository.sync();
      if (failure == null) {
        state = SyncStatus.success(lastSyncedAt: DateTime.now().toUtc());
        return;
      }

      if (attempt < _maxRetries) {
        await _delay(_nextBackoff(attempt));
      }
    }

    state = SyncStatus.error(
      failure: failure ?? const ServerError('Sync failed.'),
      lastSyncedAt: state.lastSyncedAt,
    );
  }

  Duration _nextBackoff(int attempt) {
    final multiplier = 1 << attempt;
    final delay = Duration(
      milliseconds: _baseBackoff.inMilliseconds * multiplier,
    );
    if (delay > _maxBackoff) return _maxBackoff;
    return delay;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
