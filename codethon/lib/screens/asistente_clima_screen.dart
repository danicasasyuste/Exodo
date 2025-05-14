import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

class Mensaje {
  final String texto;
  final bool esUsuario;

  Mensaje(this.texto, this.esUsuario);
}

class AsistenteClimaScreen extends StatefulWidget {
  const AsistenteClimaScreen({super.key});

  static final List<Mensaje> _mensajesGuardados = [];

  @override
  State<AsistenteClimaScreen> createState() => _AsistenteClimaScreenState();
}

class _AsistenteClimaScreenState extends State<AsistenteClimaScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Mensaje> _mensajes = List.from(AsistenteClimaScreen._mensajesGuardados);

  bool _isLoading = false;
  final Logger _logger = Logger();

  Future<void> enviarPregunta() async {
    final pregunta = _controller.text.trim();
    if (pregunta.isEmpty) return;

    final mensajeUsuario = Mensaje(pregunta, true);

    setState(() {
      _isLoading = true;
      _mensajes.insert(0, mensajeUsuario);
      AsistenteClimaScreen._mensajesGuardados.insert(0, mensajeUsuario);
      _controller.clear();
    });

    final url = Uri.parse('https://tristan1212.app.n8n.cloud/webhook/asistente-clima');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'pregunta': pregunta}),
      );

      _logger.i('🔁 Código de estado: ${response.statusCode}');
      _logger.i('📦 Body recibido: "${response.body}"');

      if (response.body.isEmpty) {
        throw Exception('Respuesta vacía del servidor IA');
      }

      final data = jsonDecode(response.body);
      final respuesta = data['respuesta'] ?? 'Sin respuesta';

      final mensajeIA = Mensaje(respuesta, false);
      setState(() {
        _mensajes.insert(0, mensajeIA);
        AsistenteClimaScreen._mensajesGuardados.insert(0, mensajeIA);
      });
    } catch (e) {
      final errorMensaje = Mensaje('Lo siento, no puedo responder a esa pregunta: $e', false);
      setState(() {
        _mensajes.insert(0, errorMensaje);
        AsistenteClimaScreen._mensajesGuardados.insert(0, errorMensaje);
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Nuevo encabezado estilizado
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Asistente ClimaColab',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.1,
                      color: Colors.blueGrey,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.blueGrey),
                  onPressed: () => Navigator.of(context).pop(),
                )
              ],
            ),
          ),

          // Línea decorativa degradada
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            height: 2,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.blueAccent, Colors.lightBlueAccent],
              ),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),

          // Lista de mensajes
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: _mensajes.length,
              itemBuilder: (context, index) {
                final mensaje = _mensajes[index];
                final isUser = mensaje.esUsuario;

                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    decoration: BoxDecoration(
                      color: isUser
                          ? const Color(0xFFD0E8FF)
                          : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isUser ? 16 : 4),
                        bottomRight: Radius.circular(isUser ? 4 : 16),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 6,
                          offset: const Offset(2, 3),
                        )
                      ],
                    ),
                    child: Text(
                      mensaje.texto,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 15.5,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // Input y botón enviar
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  style: const TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    hintText: 'Haz una pregunta sobre el clima...',
                    hintStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Colors.blueGrey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _isLoading
                  ? const SizedBox(
                      width: 30,
                      height: 30,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Container(
                      decoration: const BoxDecoration(
                        color: Colors.blueAccent,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white),
                        onPressed: enviarPregunta,
                      ),
                    ),
            ],
          ),
        ],
      ),
    );
  }
}
