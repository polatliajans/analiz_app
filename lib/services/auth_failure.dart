import '../l10n/app_localizations.dart';

enum AuthErrorKind {
  invalidEmail,
  wrongCredentials,
  emailInUse,
  weakPassword,
  network,
  tooManyRequests,
  cancelled,
  emailUnverifiedConflict,
  unknown,
}

class AuthFailure implements Exception {
  final AuthErrorKind kind;
  const AuthFailure(this.kind);

  @override
  String toString() => 'AuthFailure($kind)';
}

AuthErrorKind authErrorKindFromCode(String firebaseCode) {
  switch (firebaseCode) {
    case 'invalid-email':
      return AuthErrorKind.invalidEmail;
    case 'user-not-found':
    case 'wrong-password':
    case 'invalid-credential':
    case 'user-disabled':
      return AuthErrorKind.wrongCredentials;
    case 'email-already-in-use':
      return AuthErrorKind.emailInUse;
    case 'weak-password':
      return AuthErrorKind.weakPassword;
    case 'network-request-failed':
      return AuthErrorKind.network;
    case 'too-many-requests':
      return AuthErrorKind.tooManyRequests;
    case 'popup-closed-by-user':
    case 'cancelled':
    case 'canceled':
      return AuthErrorKind.cancelled;
    default:
      return AuthErrorKind.unknown;
  }
}

String authErrorMessage(AppLocalizations l10n, AuthErrorKind kind) {
  switch (kind) {
    case AuthErrorKind.invalidEmail:
      return l10n.authErrorInvalidEmail;
    case AuthErrorKind.wrongCredentials:
      return l10n.authErrorWrongCredentials;
    case AuthErrorKind.emailInUse:
      return l10n.authErrorEmailInUse;
    case AuthErrorKind.weakPassword:
      return l10n.authErrorWeakPassword;
    case AuthErrorKind.network:
      return l10n.authErrorNetwork;
    case AuthErrorKind.tooManyRequests:
      return l10n.authErrorTooManyRequests;
    case AuthErrorKind.cancelled:
      return l10n.authErrorCancelled;
    case AuthErrorKind.emailUnverifiedConflict:
      return l10n.authErrorEmailUnverifiedConflict;
    case AuthErrorKind.unknown:
      return l10n.authErrorUnknown;
  }
}

/// Localized text for any error thrown by an auth action.
String authErrorText(AppLocalizations l10n, Object error) =>
    error is AuthFailure ? authErrorMessage(l10n, error.kind) : '$error';
