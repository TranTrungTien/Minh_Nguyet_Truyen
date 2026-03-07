import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:minh_nguyet_truyen/app/presentaion/blocs/remote/comic/blocs/search_comic_bloc.dart';
import 'package:minh_nguyet_truyen/app/presentaion/blocs/remote/comic/comic_event.dart';
import 'package:minh_nguyet_truyen/app/presentaion/blocs/remote/comic/comic_state.dart';
import 'package:minh_nguyet_truyen/app/presentaion/widgets/app_bar/app_bar.dart';
import 'package:minh_nguyet_truyen/app/presentaion/widgets/comic/item_comic_2.dart';
import 'package:minh_nguyet_truyen/app/presentaion/widgets/error_view.dart';
import 'package:minh_nguyet_truyen/app/presentaion/widgets/loading_widget.dart';
import 'package:minh_nguyet_truyen/app/domain/models/comic.dart';
import 'package:minh_nguyet_truyen/core/constants/colors.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _textController = TextEditingController();

  String _currentQuery = '';
  int _currentPage = 1;
  int _totalPages = 1;
  final List<ComicEntity> _allComics = [];

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _submitSearch(String query) {
    setState(() {
      _allComics.clear();
    });
    final newQuery = query.trim();
    if (newQuery.isEmpty) return;

    FocusScope.of(context).unfocus();

    if (_currentQuery != newQuery) {
      setState(() {
        _currentQuery = newQuery;
      });
      context
          .read<SearchComicBloc>()
          .add(GetComicsSearchEvent(query: newQuery, page: 1));
    }
  }

  void _loadMore() {
    if (_currentPage < _totalPages &&
        context.read<SearchComicBloc>().state is! ComicLoading) {
      context.read<SearchComicBloc>().add(
          GetComicsSearchEvent(query: _currentQuery, page: _currentPage + 1));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppBarWidget(title: 'Tìm kiếm truyện'),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.backgroundLight,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _textController,
                        autofocus: true,
                        textInputAction: TextInputAction.search,
                        onSubmitted: _submitSearch,
                        style: const TextStyle(
                            fontSize: 14, color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Tìm truyện, tác giả, thể loại...',
                          hintStyle: TextStyle(
                              color: AppColors.textSecondary.withOpacity(0.7),
                              fontSize: 14),
                          filled: true,
                          fillColor: Colors.transparent,
                          prefixIcon: const Icon(Icons.search_rounded,
                              color: AppColors.primary, size: 22),
                          prefixIconConstraints:
                              const BoxConstraints(minWidth: 36, minHeight: 36),
                          contentPadding:
                              const EdgeInsetsDirectional.only(start: 8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(
                                color: AppColors.textSecondary.withOpacity(0.4),
                                width: 1.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(
                                color: AppColors.primary, width: 2.0),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(28),
                    child: InkWell(
                      hoverColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      splashColor: Colors.transparent,
                      borderRadius: BorderRadius.circular(28),
                      onTap: () => _submitSearch(_textController.text),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.primary,
                              AppColors.primary.withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                                color: AppColors.primary.withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 6)),
                          ],
                        ),
                        child: const Icon(Icons.arrow_forward_rounded,
                            color: AppColors.textOnPrimary, size: 22),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: BlocConsumer<SearchComicBloc, ComicState>(
                listener: (context, state) {
                  if (state is ComicSuccesfull && state.listComic != null) {
                    final newComics = state.listComic!.comics ?? [];
                    final newPage = state.listComic!.currentPage ?? 1;
                    setState(() {
                      _totalPages = state.listComic!.totalPages ?? 1;
                      _currentPage = newPage;
                      if (newPage == 1) {
                        _allComics
                          ..clear()
                          ..addAll(newComics);
                      } else {
                        _allComics.addAll(newComics);
                      }
                    });
                  }
                },
                builder: (context, state) {
                  if (_currentQuery.isEmpty) {
                    return const Center(
                        child: Text("Nhập từ khóa để bắt đầu tìm kiếm",
                            style: TextStyle(
                                fontSize: 14, color: AppColors.textSecondary)));
                  }

                  if (state is ComicLoading && _allComics.isEmpty) {
                    return const LoadingWidget();
                  }
                  if (state is ComicFailed && _allComics.isEmpty) {
                    return ErrorView(
                      message: state.error?.message,
                      onRetry: () {
                        _submitSearch(_textController.text);
                      },
                    );
                  }
                  if (_allComics.isEmpty) {
                    return const Center(
                        child: Text('Không tìm thấy kết quả nào',
                            style: TextStyle(
                                fontSize: 14, color: AppColors.textSecondary)));
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 0.55,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10),
                    itemCount: _allComics.length +
                        ((_currentPage < _totalPages) ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _allComics.length) {
                        _loadMore();
                        return const Center(child: CircularProgressIndicator());
                      }
                      return ItemComic2(comic: _allComics[index]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
