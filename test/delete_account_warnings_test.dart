import 'package:flutter_test/flutter_test.dart';

import 'package:kriptoanaliz/services/delete_account_warnings.dart';

void main() {
  test('free member without credits sees no warnings and no checkbox', () {
    final w = deleteAccountWarnings(role: 'free', creditBalance: 0);
    expect(w.showCredits, isFalse);
    expect(w.showProWarning, isFalse);
    expect(w.requiresAck, isFalse);
  });

  test('member with credits sees credit line and needs ack', () {
    final w = deleteAccountWarnings(role: 'free', creditBalance: 25);
    expect(w.showCredits, isTrue);
    expect(w.credits, 25);
    expect(w.showProWarning, isFalse);
    expect(w.requiresAck, isTrue);
  });

  test('pro member with zero credits sees pro box and needs ack', () {
    final w = deleteAccountWarnings(role: 'pro', creditBalance: 0);
    expect(w.showCredits, isFalse);
    expect(w.showProWarning, isTrue);
    expect(w.requiresAck, isTrue);
  });

  test('pro member with credits sees both', () {
    final w = deleteAccountWarnings(role: 'pro', creditBalance: 300);
    expect(w.showCredits, isTrue);
    expect(w.showProWarning, isTrue);
    expect(w.requiresAck, isTrue);
  });

  test('negative balance is treated as no credits', () {
    final w = deleteAccountWarnings(role: 'free', creditBalance: -5);
    expect(w.showCredits, isFalse);
    expect(w.requiresAck, isFalse);
  });

  test('delete enabled only after ack when required', () {
    final w = deleteAccountWarnings(role: 'pro', creditBalance: 10);
    expect(w.canDelete(acknowledged: false), isFalse);
    expect(w.canDelete(acknowledged: true), isTrue);
    final free = deleteAccountWarnings(role: 'free', creditBalance: 0);
    expect(free.canDelete(acknowledged: false), isTrue);
  });
}
