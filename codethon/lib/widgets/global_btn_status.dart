import 'package:flutter/material.dart';

class GlobalConfig {
  static final ValueNotifier<bool> mostrarBotonAsistente = ValueNotifier(true);

  static void ocultarAsistente() {
    mostrarBotonAsistente.value = false;
  }

  static void mostrarAsistente() {
    mostrarBotonAsistente.value = true;
  }
}
