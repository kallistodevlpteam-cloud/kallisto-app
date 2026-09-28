import 'dart:async';
import 'package:flutter/foundation.dart';
import 'client_gateway.dart';
import 'client_models.dart';

class ClientController extends ChangeNotifier {
  ClientController(this.gateway);
  final ClientGateway gateway;
  ClientConnection connection = ClientConnection.loading;
  ClientSnapshot? snapshot;
  String message = '';
  bool busy = false;
  bool _disposed = false;
  int _generation = 0;
  StreamSubscription<void>? _subscription;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> initialize() async {
    _subscription ??= gateway.sessionChanges.listen((_) => refresh());
    try {
      await gateway.initialize();
      if (_disposed) return;
      await refresh();
    } on ClientFailure catch (error) {
      if (_disposed) return;
      connection = error.connection;
      message = error.message;
      _notify();
    } catch (_) {
      if (_disposed) return;
      connection = ClientConnection.unavailable;
      message = 'Could not initialize your workspace. Please retry.';
      _notify();
    }
  }

  Future<void> refresh({bool next = false}) async {
    final generation = ++_generation;
    final previous = next ? snapshot : null;
    if (!next) snapshot = null;
    connection = ClientConnection.loading;
    message = '';
    _notify();
    try {
      final result = await gateway.load(cursor: previous?.nextCursor);
      if (_disposed || generation != _generation) return;
      snapshot = result == null || previous == null
          ? result
          : ClientSnapshot(
              uid: result.uid,
              name: result.name,
              nextCursor: result.nextCursor,
              projects: [
                if (previous.uid == result.uid) ...previous.projects,
                ...result.projects.where(
                  (item) =>
                      previous.uid != result.uid ||
                      !previous.projects.any((old) => old.id == item.id),
                ),
              ],
            );
      connection = result == null
          ? ClientConnection.signedOut
          : ClientConnection.ready;
    } on ClientFailure catch (error) {
      if (_disposed || generation != _generation) return;
      snapshot = null;
      connection = error.connection;
      message = error.message;
    } catch (_) {
      if (_disposed || generation != _generation) return;
      snapshot = null;
      connection = ClientConnection.unavailable;
      message = 'Could not load your workspace. Please retry.';
    }
    _notify();
  }

  Future<void> signIn(String email, String password) async {
    if (busy) return;
    busy = true;
    message = '';
    _notify();
    try {
      await gateway.signIn(email, password);
      await refresh();
    } on ClientFailure catch (error) {
      message = error.message;
      connection = error.connection;
    } catch (_) {
      message = 'Could not sign in. Please retry.';
      connection = ClientConnection.unavailable;
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> signOut() async {
    ++_generation;
    snapshot = null;
    connection = ClientConnection.signedOut;
    _notify();
    try {
      await gateway.signOut();
    } catch (_) {
      connection = ClientConnection.unavailable;
      message = 'Sign-out could not finish. Please retry.';
      _notify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    ++_generation;
    _subscription?.cancel();
    gateway.dispose();
    super.dispose();
  }
}
