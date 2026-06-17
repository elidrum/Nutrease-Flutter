import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/error/domain_error.dart';

/// Traduce un errore Supabase/di trasporto sollevato in un [DomainError] di
/// dominio.
///
/// Puro e senza effetti collaterali, così è testabile a unità direttamente senza
/// mockare l'intero SDK. I fallimenti delle API di auth restano generici
/// ([AuthError]) per evitare la user-enumeration; i fallimenti di trasporto
/// mappano su [NetworkError].
DomainError mapSupabaseError(Object error) {
  if (error is AuthApiException) return const AuthError();
  // Errori auth retryable/sessione assente sono di trasporto, non di credenziali.
  if (error is AuthException) return const NetworkError();
  if (error is PostgrestException) return const NetworkError();
  if (error is SocketException) return const NetworkError();
  if (error is TimeoutException) return const NetworkError();
  return const UnknownError();
}
