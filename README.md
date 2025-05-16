# 🌦️ ClimaColab: App Meteorológica Colaborativa

ClimaColab es una aplicación móvil desarrollada con Flutter que combina datos oficiales del clima con reportes ciudadanos en tiempo real para mejorar la precisión meteorológica local en la Comunidad Valenciana. Esta app forma parte de un Trabajo de Fin de Grado.

## 🎬 Vídeo de Demostración

📺 Mira el funcionamiento de la app aquí:  
👉 [Ver en YouTube](https://www.youtube.com/watch?v=(https://youtu.be/fSdDE5TKrpQ))

## 📱 Funcionalidades principales

- Visualización del clima actual, por horas y por días.
- Comparación entre datos oficiales (API) y datos colaborativos (Firebase).
- Votaciones ciudadanas sobre el clima observado.
- Mapa interactivo con condiciones climáticas por municipio.
- Calendario inteligente con alertas meteorológicas.
- Notificaciones push si se detecta mal clima para un evento.
- Sistema de reporte verificado para catástrofes.
- Chats por ciudad con mensajes guardados en tiempo real (Supabase).
- Historias tipo Instagram con clima visual y efímero (24h).

## 🧩 Tecnologías utilizadas

- Flutter + Dart
- Firebase (Firestore, FCM)
- Supabase (mensajes y multimedia)
- OpenWeatherMap API / AEMET API
- Lottie para animaciones
- Google Maps
- OneSignal (REST API)
- Notificaciones programadas
- PageView, Dropdowns, Carousels, y diseño responsive.

## 🚀 Instalación

```bash
git clone https://github.com//ClimaColab.git
cd ClimaColab
flutter pub get
flutter run
