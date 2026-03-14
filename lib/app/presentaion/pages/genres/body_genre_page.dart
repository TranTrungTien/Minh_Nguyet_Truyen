import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:minh_nguyet_truyen/app/domain/models/genre.dart';
import 'package:minh_nguyet_truyen/app/presentaion/blocs/remote/comic/blocs/comic_by_genre_bloc.dart';
import 'package:minh_nguyet_truyen/app/presentaion/blocs/remote/comic/comic_event.dart';
import 'package:minh_nguyet_truyen/app/presentaion/blocs/remote/comic/comic_state.dart';
import 'package:minh_nguyet_truyen/app/presentaion/blocs/remote/genre/genre_bloc.dart';
import 'package:minh_nguyet_truyen/app/presentaion/blocs/remote/genre/genre_event.dart';
import 'package:minh_nguyet_truyen/app/presentaion/blocs/remote/genre/genre_state.dart';
import 'package:minh_nguyet_truyen/app/presentaion/widgets/comic/item_comic_2.dart';
import 'package:minh_nguyet_truyen/app/presentaion/widgets/error_view.dart';
import 'package:minh_nguyet_truyen/app/presentaion/widgets/index_page.dart';
import 'package:minh_nguyet_truyen/app/presentaion/widgets/loading_widget.dart';
import 'package:minh_nguyet_truyen/core/constants/constants.dart';
import 'package:minh_nguyet_truyen/core/utils/noti.dart';
import 'package:minh_nguyet_truyen/setup.dart';
import 'package:minh_nguyet_truyen/core/constants/colors.dart';

class BodyGenrePage extends StatefulWidget {
  const BodyGenrePage({super.key});

  static void loading(BuildContext context) {
    context.read<ComicByGenreBloc>().add(GetComicByGenreEvent());
    context.read<GenreBloc>().add(GetGenresEvent());
  }

  @override
  State<BodyGenrePage> createState() => _BodyGenrePageState();
}

class _BodyGenrePageState extends State<BodyGenrePage> {
  StatusComic status = StatusComic.all;
  GenreEntity genre = sl();
  int totalPages = 1;
  int currentPage = 1;

  @override
  void initState() {
    super.initState();
    BodyGenrePage.loading(context);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ComicByGenreBloc, ComicState>(
      listener: (context, state) {
        if (state is ComicSuccesfull) {
          setState(() {
            totalPages = state.listComic!.totalPages ?? 1;
          });
        }
      },
      builder: (context, comicState) {
        return SafeArea(
          child: Column(
            children: [
              ListTile(
                title: const Text(
                  "Tình trạng:",
                  style: TextStyle(color: AppColors.textPrimary),
                ),
                trailing: DropdownButton(
                  value: status,
                  onChanged: (value) {
                    showFeatureComingSoon(context);
                    // if (value is StatusComic) {
                    //   setState(() => status = value);
                    //   context.read<ComicByGenreBloc>().add(
                    //     GetComicByGenreEvent(
                    //       status: value.name,
                    //       genreId: genre.id,
                    //     ),
                    //   );
                    // }
                  },
                  items: const [
                    DropdownMenuItem(
                      value: StatusComic.all,
                      child: Text("Tất cả",
                          style: TextStyle(color: AppColors.textSecondary)),
                    ),
                    DropdownMenuItem(
                      value: StatusComic.ongoing,
                      child: Text("Đang tiến hành",
                          style: TextStyle(color: AppColors.textSecondary)),
                    ),
                    DropdownMenuItem(
                      value: StatusComic.completed,
                      child: Text("Đã hoàn thành",
                          style: TextStyle(color: AppColors.textSecondary)),
                    ),
                  ],
                ),
              ),
              ListTile(
                title: const Text(
                  "Thể loại:",
                  style: TextStyle(color: AppColors.textPrimary),
                ),
                trailing: BlocBuilder<GenreBloc, GenreState>(
                  builder: (context, state) {
                    if (state is GenreSuccessfull) {
                      final genres = state.listGenre!;
                      return DropdownButton(
                        value:
                            genres.any((e) => e.id == genre.id) ? genre.id : null,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              genre = genres.firstWhere(
                                (e) => e.id == value,
                                orElse: () => sl(),
                              );
                              currentPage = 1;
                            });
          
                            context.read<ComicByGenreBloc>().add(
                                  GetComicByGenreEvent(
                                    genreId: genre.id,
                                    status: status.name,
                                  ),
                                );
                          }
                        },
                        items: genres
                            .map((e) => DropdownMenuItem(
                                  value: e.id,
                                  child: Text(
                                    e.name ?? "",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        color: AppColors.textSecondary),
                                  ),
                                ))
                            .toList(),
                      );
                    }
          
                    if (state is GenreLoading) {
                      return const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.primary,
                        ),
                      );
                    }
          
                    if (state is GenreFailed) {
                      return Tooltip(
                        message: state.error!.message.toString(),
                        child: const Icon(
                          Icons.error,
                          color: AppColors.danger,
                          size: 24,
                        ),
                      );
                    }
          
                    return const SizedBox();
                  },
                ),
              ),
              Expanded(
                child: _buildComicList(comicState),
              ),
              IndexPage(
                totalPages: totalPages,
                currentPage: currentPage,
                onValue: (index) {
                  if (index <= totalPages && index >= 0) {
                    setState(() {
                      currentPage = index;
                    });
                  }
                  context.read<ComicByGenreBloc>().add(
                        GetComicByGenreEvent(
                          genreId: genre.id,
                          status: status.name,
                          page: index,
                        ),
                      );
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _buildComicList(ComicState state) {
    if (state is ComicSuccesfull) {
      final listComic = state.listComic?.comics ?? [];
      return GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          childAspectRatio: 0.8,
          crossAxisCount: 3,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
        ),
        itemCount: listComic.length,
        itemBuilder: (_, i) => ItemComic2(comic: listComic[i]),
      );
    }

    if (state is ComicFailed) {
      return ErrorView(
        message: state.error?.message,
        onRetry: () {
          context.read<ComicByGenreBloc>().add(GetComicByGenreEvent());
        },
      );
    }

    return const LoadingWidget();
  }
}
