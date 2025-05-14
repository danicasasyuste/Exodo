import 'package:flutter/material.dart';
import '../screens/asistente_clima_screen.dart';
import '../widgets/global_btn_status.dart';
import 'package:lottie/lottie.dart';

class BotonAsistente extends StatelessWidget {
  final Alignment alignment;
  final EdgeInsets margin;

  const BotonAsistente({
    super.key,
    this.alignment = Alignment.bottomRight,
    this.margin = const EdgeInsets.only(bottom: 0, right: 0),
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Container(
        margin: margin,
        decoration: BoxDecoration(
          color: const Color(0xFFE6F0FA),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFB0C4DE), width: 4.0), // Grosor aumentado
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 8,
              offset: const Offset(2, 4),
            ),
          ],
        ),
        child: IconButton(
          iconSize: 68,
          icon: Lottie.asset(
            'assets/lottie/asistente.json',
            width: 60,
            height: 60,
            fit: BoxFit.contain,
          ),
          tooltip: 'Asistente climático',
          onPressed: () {
            GlobalConfig.mostrarBotonAsistente.value = false;

            showGeneralDialog(
              context: context,
              barrierColor: Colors.black45,
              barrierDismissible: false,
              transitionDuration: const Duration(milliseconds: 300),
              transitionBuilder: (context, animation, secondaryAnimation, child) {
                final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutBack);
                return ScaleTransition(scale: curved, child: FadeTransition(opacity: animation, child: child));
              },
              pageBuilder: (context, animation, secondaryAnimation) {
                return Center(
                  child: Dialog(
                    elevation: 10,
                    backgroundColor: Colors.white,
                    insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.9,
                      height: MediaQuery.of(context).size.height * 0.7,
                      child: const AsistenteClimaScreen(),
                    ),
                  ),
                );
              },
            ).whenComplete(() {
              GlobalConfig.mostrarBotonAsistente.value = true;
            });
          },
        ),
      ),
    );
  }
}
