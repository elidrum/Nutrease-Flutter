import 'package:flutter/material.dart';

/// Messenger a livello di app: permette di mostrare una SnackBar anche mentre
/// lo stack delle rotte viene sostituito (es. la conferma "password reimpostata"
/// che parte mentre l'utente viene rimandato al login).
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();
