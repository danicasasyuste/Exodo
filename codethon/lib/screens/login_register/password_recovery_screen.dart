import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:codethon/widgets/global_btn_status.dart';
import 'package:http/http.dart' as http;

class PasswordRecoveryPage extends StatefulWidget {
  const PasswordRecoveryPage({super.key});

  @override
  _PasswordRecoveryPageState createState() => _PasswordRecoveryPageState();
}

class _PasswordRecoveryPageState extends State<PasswordRecoveryPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  String? _message;

  Future<void> _recoverPassword() async {
    if (_formKey.currentState!.validate()) {
      String email = _emailController.text;

      try {
        // Enviar solicitud HTTP al backend PHP
        final response = await http.post(
          Uri.parse('https://tu-sitio-web.com/send_password_reset.php'),  // URL del backend PHP
          body: {'email': email},
        );

        final responseData = json.decode(response.body);
        
        if (responseData['status'] == 'success') {
          setState(() {
            _message = 'Correo enviado con éxito. Revisa tu bandeja de entrada.';
          });
        } else {
          setState(() {
            _message = 'Error: ${responseData['message']}';
          });
        }
      } catch (e) {
        setState(() {
          _message = 'Error al conectar con el servidor: $e';
          GlobalConfig.mostrarAsistente();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recuperar Contraseña'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Título
              const Text(
                'Ingrese su correo electrónico para recuperar la contraseña',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Campo de texto para el correo electrónico
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese un correo electrónico';
                  }
                  if (!RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$").hasMatch(value)) {
                    return 'Ingrese un correo válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Botón para recuperar la contraseña
              ElevatedButton(
                onPressed: _recoverPassword,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                child: const Text('Recuperar contraseña'),
              ),

              // Mostrar mensaje de éxito o error
              if (_message != null)
                Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: Text(
                    _message!,
                    style: TextStyle(
                      fontSize: 16,
                      color: _message!.contains('error') ? Colors.red : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
