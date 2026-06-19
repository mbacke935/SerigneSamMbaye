
Voici le genre design souhaité. A chaque phase Tu t'inspire de ce document pour bosser. Tu peux ne ne pas prendre typiquement tout textuellement mais si tu peux améliorer fais le. Et aussi, il faut utiliser des icones professionnels mais pas des icones enfantins.

⸻

1. MAQUETTE COMPLÈTE (écran par écran)

 1. Home (Accueil)

Structure

[AppBar]
- Logo + nom app
- Icon recherche
[Bloc 1: Citation du jour]
- Card pleine largeur
- Texte + source
[Bloc 2: Derniers audios]
- Horizontal scroll cards
- ▶ titre + durée
[Bloc 3: Dernières vidéos]
- Grid 2 colonnes
- thumbnail + titre
[Bottom Navigation]

⸻

 2. Audios

[AppBar] "Audios"
[Search bar]
[List vertical]
- Card audio :
  - image mini
  - titre
  - durée
  - bouton play
[Mini player fixe en bas]

⸻

3. Vidéos

[AppBar] "Vidéos"
[Grid 2 columns]
Card vidéo :
- thumbnail
- durée en overlay
- titre
- vues

⸻

 4. Biographie

[AppBar]
[Hero image]
[Titre]
[Texte long scrollable]
[Sections]
- Enfance
- Parcours
- Enseignements

⸻

 5. Citations

[AppBar]
[Cards verticales]
Card:
- texte centré
- fond doux
- auteur/source

⸻

 6. Favoris

Tabs:
- Audios
- Vidéos
- Citations
Listes filtrées

⸻

 7. Notifications

Liste simple:
- titre
- description
- date
- type (audio/video/event)

⸻

 8. Profil

Avatar
Nom utilisateur
Stats:
- audios écoutés
- vidéos vues
Settings:
- thème
- langue
- logout

⸻

 2. DESIGN FLUTTER (exemple)

 ThemeData global

import 'package:flutter/material.dart';
class AppTheme {
  static const primary = Color(0xFF0F3D2E);
  static const gold = Color(0xFFC8A24A);
  static const background = Color(0xFFF7F7F5);
  static const dark = Color(0xFF0B0F14);
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: primary,
    scaffoldBackgroundColor: background,
    fontFamily: 'Poppins',
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      foregroundColor: Colors.black,
    ),
    colorScheme: const ColorScheme.light(
      primary: primary,
      secondary: gold,
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  );
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: dark,
    primaryColor: primary,
    colorScheme: const ColorScheme.dark(
      primary: primary,
      secondary: gold,
    ),
  );
}

⸻

 Audio Card Widget

class AudioCard extends StatelessWidget {
  final String title;
  final String duration;
  const AudioCard({super.key, required this.title, required this.duration});
  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(Icons.play_circle_fill, color: Colors.green),
        title: Text(title),
        subtitle: Text(duration),
        trailing: Icon(Icons.favorite_border),
      ),
    );
  }
}

⸻

 Video Card Widget

class VideoCard extends StatelessWidget {
  final String title;
  const VideoCard({super.key, required this.title});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 120,
          decoration: BoxDecoration(
            color: Colors.black12,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        const SizedBox(height: 8),
        Text(title),
      ],
    );
  }
}

⸻

 Citation Card

class QuoteCard extends StatelessWidget {
  final String text;
  const QuoteCard({super.key, required this.text});
  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFF0F0EA),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          text,
          style: const TextStyle(
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

⸻

 3. STRUCTURE FIGMA (organisation pro)

 Pages Figma

Serigne Sam Mbaye App
│
├── 01 - Design System
├── 02 - Home
├── 03 - Audios
├── 04 - Videos
├── 05 - Biography
├── 06 - Citations
├── 07 - Favorites
├── 08 - Profile

⸻

 Design System (important page)

* Colors
* Typography
* Buttons
* Cards
* Icons
* Spacing system (8px grid)

⸻

 Components à créer dans Figma

* Audio Card
* Video Card
* Quote Card
* Bottom Navigation
* AppBar
* Player mini

⸻

 CONCLUSION

Tu as maintenant :

✔ Maquette complète écran par écran

✔ Design Flutter prêt à coder

✔ Structure Figma professionnelle

⸻

