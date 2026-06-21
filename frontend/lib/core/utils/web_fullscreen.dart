// Plein écran navigateur + masquage du curseur, web uniquement.
// Sur les autres plateformes, les fonctions sont des no-op.
export 'web_fullscreen_stub.dart'
    if (dart.library.html) 'web_fullscreen_web.dart';
