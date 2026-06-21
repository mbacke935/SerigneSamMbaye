import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../core/models/audio_model.dart';
import '../core/models/video_model.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/onboarding/screens/onboarding_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/profile_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/audio/screens/audio_list_screen.dart';
import '../features/audio/screens/audio_player_screen.dart';
import '../features/video/screens/video_list_screen.dart';
import '../features/video/screens/video_player_screen.dart';
import '../features/albums/screens/album_detail_screen.dart';
import '../features/biography/screens/biography_screen.dart';
import '../features/citations/screens/citation_reader_screen.dart';
import '../features/citations/screens/citations_screen.dart';
import '../features/notifications/screens/notifications_screen.dart';
import '../features/search/screens/search_screen.dart';
import '../features/favorites/screens/favorites_screen.dart';
import '../widgets/app_scaffold.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    routes: [
      // Écrans sans bottom nav
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/connexion',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/inscription',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/recherche',
        name: 'search',
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: '/favoris',
        name: 'favorites',
        builder: (context, state) => const FavoritesScreen(),
      ),
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      // Lecteur audio (plein écran, sans bottom nav)
      GoRoute(
        path: '/audios/lecteur',
        name: 'audioPlayer',
        builder: (context, state) {
          final audio = state.extra as AudioModel?;
          if (audio == null) return const _PlaceholderScreen(title: 'Lecteur');
          return AudioPlayerScreen(audio: audio);
        },
      ),
      // Biographie (hors shell, push depuis accueil)
      GoRoute(
        path: '/biographie',
        name: 'biography',
        builder: (context, state) => const BiographyScreen(),
      ),
      // Détail d'un album (hors shell)
      GoRoute(
        path: '/albums/:id',
        name: 'album',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          final titre = state.extra is String ? state.extra as String : null;
          return AlbumDetailScreen(albumId: id, titre: titre);
        },
      ),
      // Lecture plein écran des citations (hors shell)
      GoRoute(
        path: '/citations/lecture',
        name: 'citationReader',
        builder: (context, state) {
          final args = state.extra as CitationReaderArgs?;
          if (args == null) return const _PlaceholderScreen(title: 'Citations');
          return CitationReaderScreen(
            citations: args.citations,
            initialIndex: args.initialIndex,
          );
        },
      ),
      // Lecteur vidéo (plein écran, sans bottom nav)
      GoRoute(
        path: '/videos/lecteur',
        name: 'videoPlayer',
        builder: (context, state) {
          final video = state.extra as VideoModel?;
          if (video == null) return const _PlaceholderScreen(title: 'Vidéo');
          return VideoPlayerScreen(video: video);
        },
      ),

      // Shell principal avec bottom navigation
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppScaffold(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/',
              name: 'home',
              builder: (context, state) => const HomeScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/audios',
              name: 'audios',
              builder: (context, state) => const AudioListScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/videos',
              name: 'videos',
              builder: (context, state) => const VideoListScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/citations',
              name: 'citations',
              builder: (context, state) => const CitationsScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/profil',
              name: 'profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ]),
        ],
      ),
    ],
  );
}

class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
          child:
              Text(title, style: Theme.of(context).textTheme.headlineSmall)),
    );
  }
}
