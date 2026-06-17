import 'package:supabase_flutter/supabase_flutter.dart';

import 'env.dart';

/// Il client Supabase condiviso.
///
/// Valido solo dopo che [initSupabase] è terminata.
SupabaseClient get supabase => Supabase.instance.client;

/// Inizializza Supabase con i segreti presi da [Env].
///
/// Va atteso in `main()` **prima** di `runApp`. Al termine la sessione
/// precedente (se c'era) è già stata ripristinata dallo storage locale, così il
/// gate di sessione può leggerla in modo sincrono.
Future<void> initSupabase() async {
  await Supabase.initialize(
    url: Env.supabaseUrl,
    // Il valore configurato è una publishable key Supabase (`sb_publishable_…`).
    publishableKey: Env.supabaseAnonKey,
  );
}
