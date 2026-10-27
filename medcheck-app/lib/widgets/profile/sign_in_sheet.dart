import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';
import 'package:pill_reminder_app/config/colors.dart';

class SignInSheet extends StatelessWidget {
  final VoidCallback onGoogleTap;

  const SignInSheet({super.key, required this.onGoogleTap});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.90,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.adaptiveTileBackground(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(child: Lottie.asset('assets/lotties/login.json')),
                const SizedBox(height: 8),
                Text(
                  'Iniciar sesión',
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Inicia sesión para sincronizar tus datos y acceder desde cualquier dispositivo.',
                  style: tt.bodyMedium?.copyWith(
                    color: AppColors.adaptiveTextSecondary(context),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: onGoogleTap,
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.adaptiveTileBackground(context),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.adaptiveTileBorder(context),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          'assets/icons/google.svg',
                          width: 20,
                          height: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Continuar con Google',
                          style: TextStyle(
                            color: AppColors.adaptiveTextPrimary(context),
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    height: 52,
                    alignment: Alignment.center,
                    child: Text(
                      'Cancelar',
                      style: TextStyle(
                        color: AppColors.adaptiveTextSecondary(context),
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
