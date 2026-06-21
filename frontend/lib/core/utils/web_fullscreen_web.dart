// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Passe toute la page en plein écran navigateur (doit être appelé depuis un
/// geste utilisateur, ce qui est le cas via le bouton plein écran).
void enterWebFullscreen() {
  try {
    html.document.documentElement?.requestFullscreen();
  } catch (_) {}
}

void exitWebFullscreen() {
  try {
    if (html.document.fullscreenElement != null) {
      html.document.exitFullscreen();
    }
  } catch (_) {}
}

/// Masque/affiche le curseur au niveau du document (le `cursor:none` de
/// MouseRegion n'est pas fiable à l'échelle du plein écran sur le web).
void setWebCursorHidden(bool hidden) {
  try {
    html.document.body?.style.cursor = hidden ? 'none' : '';
  } catch (_) {}
}
