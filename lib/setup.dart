import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:minh_nguyet_truyen/app/data/data_sources/remote/api_nettruyen_service.dart';
import 'package:minh_nguyet_truyen/app/data/repository/repository_api.dart';
import 'package:minh_nguyet_truyen/app/data/services/reading_progress_service.dart';
import 'package:minh_nguyet_truyen/app/domain/models/genre.dart';
import 'package:minh_nguyet_truyen/app/domain/repository/repository_api.dart';
import 'package:minh_nguyet_truyen/app/domain/usecases/remote/get_chapter_by_comic_id_usecase.dart';
import 'package:minh_nguyet_truyen/app/domain/usecases/remote/get_chapter_per_page_usecase.dart';
import 'package:minh_nguyet_truyen/app/domain/usecases/remote/get_comic_by_genre_usecase.dart';
import 'package:minh_nguyet_truyen/app/domain/usecases/remote/get_comic_by_id_usecase.dart';
import 'package:minh_nguyet_truyen/app/domain/usecases/remote/get_comics_search_usecase.dart';
import 'package:minh_nguyet_truyen/app/domain/usecases/remote/get_completed_comics_usecase.dart';
import 'package:minh_nguyet_truyen/app/domain/usecases/remote/get_content_one_chapter_usecase.dart';
import 'package:minh_nguyet_truyen/app/domain/usecases/remote/get_genres_usecase.dart';
import 'package:minh_nguyet_truyen/app/domain/usecases/remote/get_recent_update_comics_usecase.dart';
import 'package:minh_nguyet_truyen/app/domain/usecases/remote/get_recommend_comics_usecase.dart';
import 'package:minh_nguyet_truyen/app/domain/usecases/remote/get_trending_comics_usecase.dart';
import 'package:minh_nguyet_truyen/app/presentaion/blocs/remote/chapter/chapter_bloc.dart';
import 'package:minh_nguyet_truyen/app/presentaion/blocs/remote/chapter_per_page/chapter_per_page_bloc.dart';
import 'package:minh_nguyet_truyen/app/presentaion/blocs/remote/comic/blocs/comic_by_genre_bloc.dart';
import 'package:minh_nguyet_truyen/app/presentaion/blocs/remote/comic/blocs/comic_id_bloc.dart';
import 'package:minh_nguyet_truyen/app/presentaion/blocs/remote/comic/blocs/completed_comic_bloc.dart';
import 'package:minh_nguyet_truyen/app/presentaion/blocs/remote/comic/blocs/recent_update_comic_bloc.dart';
import 'package:minh_nguyet_truyen/app/presentaion/blocs/remote/comic/blocs/recommend_comics_bloc.dart';
import 'package:minh_nguyet_truyen/app/presentaion/blocs/remote/comic/blocs/search_comic_bloc.dart';
import 'package:minh_nguyet_truyen/app/presentaion/blocs/remote/comic/blocs/trending_comics_bloc.dart';
import 'package:minh_nguyet_truyen/app/presentaion/blocs/remote/genre/genre_bloc.dart';
import 'package:minh_nguyet_truyen/services/audio_daily_limit_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:minh_nguyet_truyen/app/data/services/bookmark_service.dart';

final sl = GetIt.instance;

Future<void> initlizeDependencies() async {
  sl.registerLazySingleton<GenreEntity>(() => const GenreEntity(
      id: "all", name: "Tất cả", description: "Tất cả thể loại truyện tranh"));

  sl.registerLazySingleton<Dio>(() => Dio());
  sl.registerLazySingleton<ApiNettruyenService>(
      () => ApiNettruyenService(dio: sl()));

  sl.registerLazySingleton<RepositoryApi>(
      () => RepositoryApiImpl(service: sl()));

  // use case
  sl.registerLazySingleton<GetChapterByComicIdUsecase>(
      () => GetChapterByComicIdUsecase(sl()));

  sl.registerLazySingleton<GetComicByGenreUsecase>(
      () => GetComicByGenreUsecase(sl()));

  sl.registerLazySingleton<GetComicByIdUsecase>(
      () => GetComicByIdUsecase(sl()));

  sl.registerLazySingleton<GetComicsSearchUsecase>(
      () => GetComicsSearchUsecase(sl()));

  sl.registerLazySingleton<GetCompletedComicsUsecase>(
      () => GetCompletedComicsUsecase(sl()));

  sl.registerLazySingleton<GetContentOneChapterUsecase>(
      () => GetContentOneChapterUsecase(sl()));

  sl.registerLazySingleton<GetGenresUsecase>(() => GetGenresUsecase(sl()));

  sl.registerLazySingleton<GetRecentUpdateComicsUsecase>(
      () => GetRecentUpdateComicsUsecase(sl()));

  sl.registerLazySingleton<GetRecommendComicsUsecase>(
      () => GetRecommendComicsUsecase(sl()));

  sl.registerLazySingleton<GetTrendingComicsUsecase>(
      () => GetTrendingComicsUsecase(sl()));

  sl.registerLazySingleton<GetChapterPerPageUsecase>(
      () => GetChapterPerPageUsecase(sl()));

  // blocs
  // chapter
  sl.registerFactory<ChapterBloc>(() => ChapterBloc(sl(), sl()));
  sl.registerFactory<ChapterPerPageBloc>(() => ChapterPerPageBloc(sl()));
  // genre
  sl.registerFactory<GenreBloc>(() => GenreBloc(sl()));

  // comics
  sl.registerFactory<ComicByIdBloc>(() => ComicByIdBloc(sl()));

  sl.registerFactory<ComicByGenreBloc>(() => ComicByGenreBloc(sl()));

  sl.registerFactory<CompletedComicBloc>(() => CompletedComicBloc(sl()));

  sl.registerFactory<RecentUpdateComicsBloc>(
      () => RecentUpdateComicsBloc(sl()));

  sl.registerFactory<RecommendComicsBloc>(() => RecommendComicsBloc(sl()));

  sl.registerFactory<SearchComicBloc>(() => SearchComicBloc(sl()));

  sl.registerFactory<TrendingComicsBloc>(() => TrendingComicsBloc(sl()));

  // Shared Preferences
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);

  // Bookmark Service
  sl.registerLazySingleton(() => BookmarkService(sl()));

  // Reading Progress Service
  sl.registerLazySingleton(() => ReadingProgressService(sl()));
  sl.registerLazySingleton(() => AudioDailyLimitService(sl()));
}
