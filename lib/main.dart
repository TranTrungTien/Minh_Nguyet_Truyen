import 'package:audio_service/audio_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:minh_nguyet_truyen/app/presentaion/blocs/audio/audio_player_handler.dart';
import 'package:minh_nguyet_truyen/app/presentaion/blocs/remote/chapter/chapter_bloc.dart';
import 'package:minh_nguyet_truyen/app/presentaion/blocs/remote/chapter_per_page/chapter_per_page_bloc.dart';
import 'package:minh_nguyet_truyen/app/presentaion/blocs/remote/comic/blocs/comic_by_genre_bloc.dart';
import 'package:minh_nguyet_truyen/app/presentaion/blocs/remote/comic/blocs/comic_id_bloc.dart';
import 'package:minh_nguyet_truyen/app/presentaion/blocs/remote/comic/blocs/completed_comic_bloc.dart';
import 'package:minh_nguyet_truyen/app/presentaion/blocs/remote/comic/blocs/recent_update_comic_bloc.dart';
import 'package:minh_nguyet_truyen/app/presentaion/blocs/remote/comic/blocs/recommend_comics_bloc.dart';
import 'package:minh_nguyet_truyen/app/presentaion/blocs/remote/comic/blocs/search_comic_bloc.dart';
import 'package:minh_nguyet_truyen/app/presentaion/blocs/remote/comic/blocs/trending_comics_bloc.dart';
import 'package:minh_nguyet_truyen/app/presentaion/blocs/remote/comic/comic_event.dart';
import 'package:minh_nguyet_truyen/app/presentaion/blocs/remote/genre/genre_bloc.dart';
import 'package:minh_nguyet_truyen/app/presentaion/widgets/global_mini_player.dart';
import 'package:minh_nguyet_truyen/app/presentaion/widgets/update_dialogs.dart';
import 'package:minh_nguyet_truyen/config/routes/custome_route.dart';
import 'package:minh_nguyet_truyen/core/constants/api.dart';
import 'package:minh_nguyet_truyen/core/constants/colors.dart';
import 'package:minh_nguyet_truyen/firebase_options.dart';
import 'package:minh_nguyet_truyen/services/update_service.dart';
import 'package:minh_nguyet_truyen/setup.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initlizeDependencies();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final audioHandler = await initAudioService();
  getIt.registerSingleton<AudioHandler>(audioHandler);
  await apiVersionService.initialize(); // Initialize ApiVersionService
  await UpdateService.initialize();
  final updateInfo = await UpdateService.checkUpdate();
  runApp(MyApp(updateInfo: updateInfo));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.updateInfo});
  final UpdateInfo updateInfo;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ComicByIdBloc>(
          create: (context) => sl(),
        ),
        BlocProvider<ComicByGenreBloc>(
          create: (context) => sl(),
        ),
        BlocProvider<CompletedComicBloc>(
          create: (context) => sl()..add(GetCompletedComicsEvent()),
        ),
        BlocProvider<RecentUpdateComicsBloc>(
          create: (context) => sl()..add(GetRecentUpdateComicsEvent()),
        ),
        BlocProvider<RecommendComicsBloc>(
          create: (context) => sl()..add(GetRecommendComicsEvent()),
        ),
        BlocProvider<SearchComicBloc>(
          create: (context) => sl(),
        ),
        BlocProvider<TrendingComicsBloc>(
          create: (context) => sl()..add(GetTrendingComicsEvent()),
        ),
        BlocProvider<GenreBloc>(create: (context) => sl()),
        BlocProvider<ChapterBloc>(create: (context) => sl()),
        BlocProvider<ChapterPerPageBloc>(create: (context) => sl()),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'Free Story',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          appBarTheme: const AppBarTheme(backgroundColor: AppColors.primary),
          colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
          useMaterial3: true,
        ),
        onGenerateRoute: (settings) => AppRouter.generate(settings),
        initialRoute: "/",
        builder: (context, child) {
          // Logic for update dialog
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            final currentContext = navigatorKey.currentContext;
            if (currentContext == null || !currentContext.mounted) return;
            if (updateInfo.type == UpdateType.none) return;

            if (updateInfo.type == UpdateType.force) {
              showDialog(
                context: currentContext,
                barrierDismissible: false,
                builder: (_) => UpdateDialog(
                  title: updateInfo.title,
                  message: updateInfo.message,
                  isForce: updateInfo.type == UpdateType.force,
                ),
              );
              return;
            }

            final navigator = Navigator.of(currentContext);
            final currentRouteName = navigator.widget.pages.firstOrNull?.name ??
                ModalRoute.of(currentContext)?.settings.name;

            if (currentRouteName == '/' || currentRouteName == null) {
              showDialog(
                context: currentContext,
                builder: (_) => UpdateDialog(
                  title: updateInfo.title,
                  message: updateInfo.message,
                  isForce: updateInfo.type == UpdateType.force,
                ),
              );
            }
          });

          if (child == null) return const SizedBox.shrink();

          return StreamBuilder<PlaybackState>(
            stream: getIt<AudioHandler>().playbackState,
            builder: (context, snapshot) {
              final playbackState = snapshot.data;
              final processingState =
                  playbackState?.processingState ?? AudioProcessingState.idle;

              final isPlayerVisible =
                  processingState != AudioProcessingState.idle &&
                      processingState != AudioProcessingState.completed &&
                      processingState != AudioProcessingState.error;

              const miniPlayerHeight = 70.0;

              return Stack(
                children: [
                  // Apply padding to the main content when player is visible
                  Padding(
                    padding: EdgeInsets.only(
                        bottom: isPlayerVisible ? miniPlayerHeight : 0),
                    child: child,
                  ),
                  // The player is positioned at the bottom
                  const Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: SafeArea(child: GlobalMiniPlayer()),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
