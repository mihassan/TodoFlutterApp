import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the user is currently authenticated.
///
/// Stubbed to `false` for now. Will be wired to Firebase Auth in Phase 7.
final isAuthenticatedProvider = StateProvider<bool>((_) => false);
