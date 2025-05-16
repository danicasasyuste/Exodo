import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';

class MunicipioValenciano {
  final String nombre;
  final String query;
  MunicipioValenciano({required this.nombre, required this.query});
}

final List<MunicipioValenciano> municipiosValencianos = [
  MunicipioValenciano(nombre: 'Valencia', query: '39.4699,-0.3763'),
  MunicipioValenciano(nombre: 'Manises', query: '39.4893,-0.4632'),
  MunicipioValenciano(nombre: 'Gandía', query: '38.9685,-0.1819'),
  MunicipioValenciano(nombre: 'Ontinyent', query: '38.8210,-0.6095'),
  MunicipioValenciano(nombre: 'Sagunto', query: '39.6792,-0.2733'),
  MunicipioValenciano(nombre: 'Xirivella', query: '39.4663,-0.4301'),
  MunicipioValenciano(nombre: 'Alzira', query: '39.1511,-0.4396'),
  MunicipioValenciano(nombre: 'Mislata', query: '39.4750,-0.4143'),
  MunicipioValenciano(nombre: 'Cullera', query: '39.1610,-0.2529'),
];

final List<Map<String, String>> climasLottie = [
  {'label': 'Soleado', 'asset': 'assets/lottie/weather/sunny.json'},
  {'label': 'Nublado', 'asset': 'assets/lottie/weather/cloudy.json'},
  {'label': 'Lluvia', 'asset': 'assets/lottie/weather/rain-light.json'},
  {'label': 'Tormenta', 'asset': 'assets/lottie/weather/lighting.json'},
  {'label': 'Niebla', 'asset': 'assets/lottie/weather/fog.json'},
  {'label': 'Noche clara', 'asset': 'assets/lottie/weather/night.json'},
  {'label': 'Noche nublada', 'asset': 'assets/lottie/weather/night-cloud.json'},
  {'label': 'Noche lluviosa', 'asset': 'assets/lottie/weather/night-rain.json'},
];

class EncuestaClimaPopup extends StatefulWidget {
  const EncuestaClimaPopup({super.key});

  @override
  State<EncuestaClimaPopup> createState() => _EncuestaClimaPopupState();
}

class _EncuestaClimaPopupState extends State<EncuestaClimaPopup> {
  MunicipioValenciano? municipioSeleccionado;
  int climaIndex = 0;
  bool isSending = false;
  final PageController _pageController = PageController(viewportFraction: 0.4);

  void enviarVoto() async {
    if (!mounted || municipioSeleccionado == null) return;

    final clima = climasLottie[climaIndex % climasLottie.length]['label'];
    setState(() => isSending = true);

    try {
      await FirebaseFirestore.instance.collection('reportes_clima').add({
        'clima': clima,
        'query': municipioSeleccionado!.query.trim(),
        'timestamp': Timestamp.now(),
      });

      if (!mounted) return;
      Navigator.of(context).pop(); // cerrar el popup
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // cerrar el popup
    } finally {
      if (mounted) setState(() => isSending = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      setState(() {
        climaIndex = _pageController.page!.round();
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pageController.jumpToPage(5000); // para efecto circular
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final cardColor = Theme.of(context).cardColor;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).pop(),
      child: Center(
        child: Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 40,
          ),
          backgroundColor: Colors.transparent,
          child: GestureDetector(
            onTap: () {},
            child: SizedBox(
              height: 570,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 16,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '¿Qué clima observas ahora?',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<MunicipioValenciano>(
                          value: municipioSeleccionado,
                          isExpanded: true,
                          hint: const Row(
                            children: [
                              Icon(Icons.location_on, color: Colors.blue),
                              SizedBox(width: 8),
                              Text("Selecciona tu municipio"),
                            ],
                          ),
                          items:
                              municipiosValencianos.map((m) {
                                return DropdownMenuItem(
                                  value: m,
                                  child: Text(m.nombre),
                                );
                              }).toList(),
                          onChanged:
                              (val) =>
                                  setState(() => municipioSeleccionado = val),
                          dropdownColor: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(
                            16,
                          ), // ✅ esquinas redondas
                          menuMaxHeight:
                              kMinInteractiveDimension *
                              4.5, // ✅ solo 4-5 elementos visibles
                        ),
                      ),
                    ),
                    const SizedBox(height: 60),
                    SizedBox(
                      height: 220,
                      child: PageView.builder(
                        controller: _pageController,
                        itemBuilder: (context, index) {
                          final current = index % climasLottie.length;
                          final clima = climasLottie[current];
                          final selected =
                              climaIndex % climasLottie.length == current;
                          return AnimatedOpacity(
                            duration: const Duration(milliseconds: 300),
                            opacity: selected ? 1 : 0.3,
                            child: Transform.scale(
                              scale: selected ? 1.15 : 0.9,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    height: 130,
                                    child: Lottie.asset(
                                      clima['asset']!,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    clima['label']!,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 72),
                    ElevatedButton(
                      onPressed: isSending ? null : enviarVoto,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 14,
                        ),
                        backgroundColor: const Color(0xFF42A5F5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      child:
                          isSending
                              ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                              : const Text(
                                'Enviar voto',
                                style: TextStyle(color: Colors.white),
                              ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
