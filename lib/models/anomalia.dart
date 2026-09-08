import 'package:flutter/material.dart';

class Anomalia {
  final TextEditingController fechaRevision =
      TextEditingController();

  final TextEditingController numeroEstacion =
      TextEditingController();

  final TextEditingController anomalia =
      TextEditingController();

  final TextEditingController fechaCorreccion =
      TextEditingController();

  void dispose() {
    fechaRevision.dispose();
    numeroEstacion.dispose();
    anomalia.dispose();
    fechaCorreccion.dispose();
  }
}
