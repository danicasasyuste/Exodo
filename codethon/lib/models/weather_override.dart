class WeatherOverride {
  bool lluvia = true; // Por defecto se asume que sí llueve
  bool overrideActiva = false;

  WeatherOverride({this.lluvia = true, this.overrideActiva = false});
}
