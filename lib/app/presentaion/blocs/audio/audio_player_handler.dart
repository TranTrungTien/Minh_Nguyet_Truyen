import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:audio_service/audio_service.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:get_it/get_it.dart';
import 'package:minh_nguyet_truyen/app/domain/models/chapter.dart';
import 'package:minh_nguyet_truyen/app/domain/models/comic.dart';
import 'package:minh_nguyet_truyen/app/domain/usecases/remote/get_chapter_per_page_usecase.dart';
import 'package:minh_nguyet_truyen/app/domain/usecases/remote/get_content_one_chapter_usecase.dart';
import 'package:minh_nguyet_truyen/core/resources/data_state.dart';
import 'package:rxdart/rxdart.dart';

final getIt = GetIt.instance;

Future<AudioHandler> initAudioService() async {
  return await AudioService.init(
    builder: () => AudioPlayerHandler(
      getIt<GetContentOneChapterUsecase>(),
      getIt<GetChapterPerPageUsecase>(),
    ),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.minhnguyet.truyen.channel.audio',
      androidNotificationChannelName: 'Audio Playback',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );
}

class AudioPlayerHandler extends BaseAudioHandler with SeekHandler {
  final GetContentOneChapterUsecase _getContentOneChapter;
  final GetChapterPerPageUsecase _getChaptersPerPage;
  final FlutterTts _tts = FlutterTts();
  final _playlist = BehaviorSubject<List<MediaItem>>.seeded([]);

  int _currentIndex = -1;
  ComicEntity? _currentComic;
  int _currentPage = 1;
  bool _isLastPage = false;
  bool _isFetchingMore = false;

  bool _isPaused = false;
  int _lastSpokenIndex = 0;
  Completer<void>?
      _speakCompleter;

  AudioPlayerHandler(this._getContentOneChapter, this._getChaptersPerPage) {
    _tts.setLanguage("vi-VN");

    _tts.setProgressHandler((text, start, end, word) {
      _lastSpokenIndex = end;
    });

    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.play,
        MediaControl.pause,
        MediaControl.stop,
        MediaControl.skipToNext,
        MediaControl.skipToPrevious,
      ],
      processingState: AudioProcessingState.idle,
    ));
  }

  Future<void> startPlayback({
    required ComicEntity comic,
    required List<ChapterEntity> initialChapters,
    int startIndex = 0,
    int initialPage = 1,
  }) async {
    await stop();

    _currentComic = comic;
    _currentPage = initialPage;
    _isLastPage = false;

    final mediaItems = _chaptersToMediaItems(
        initialChapters, comic.title ?? 'Không có tiêu đề');
    _playlist.add(mediaItems);
    queue.add(mediaItems);

    if (startIndex >= 0 && startIndex < mediaItems.length) {
      await skipToQueueItem(startIndex);
      await play();
    }
  }

  @override
  Future<void> play() async {
    final item = mediaItem.value;
    if (item == null || _currentIndex == -1) {
      return;
    }

    var content = item.extras?['content'] as String?;

    if (content == null || content.isEmpty) {
      final comicId = _currentComic?.id;
      if (comicId != null) {
        final dataState = await _getContentOneChapter(
          comicId: comicId,
          chapterId: item.id,
        );

        if (dataState is DataSuccess && dataState.data?.content != null) {
          content = dataState.data!.content!;
          final updatedItem = item.copyWith(
            extras: {...?item.extras, 'content': content},
          );
          _playlist.value[_currentIndex] = updatedItem;
          mediaItem.add(updatedItem);
          _playlist.add(List.from(_playlist.value));
        } else {
          content = null;
        }
      }
    }

    if (content == null || content.isEmpty) {
      await skipToNext();
      return;
    }

    playbackState.add(playbackState.value.copyWith(
      playing: true,
      processingState: AudioProcessingState.loading,
    ));

    try {
      if (_isPaused) {
        if (_lastSpokenIndex >= content.length) {
          _isPaused = false;
          await skipToNext();
          return;
        }

        String remaining = content.substring(_lastSpokenIndex);

        playbackState.add(playbackState.value.copyWith(
          processingState: AudioProcessingState.ready,
        ));

        _isPaused = false;
        await _speakInChunks(remaining);
        return;
      }

      _lastSpokenIndex = 0;
      await _tts.stop();

      playbackState.add(playbackState.value.copyWith(
        processingState: AudioProcessingState.ready,
      ));

      await _speakInChunks(content);
    } catch (e) {
      playbackState.add(playbackState.value.copyWith(
        processingState: AudioProcessingState.error,
      ));
      await skipToNext();
    }
  }

  Future<void> _speakInChunks(String content) async {
    if (content.isEmpty) return;

    int chunkSize = 3500;

    try {
      if (Platform.isAndroid) {
        int? maxLength = await _tts.getMaxSpeechInputLength ?? 4000;
        chunkSize = min(chunkSize, maxLength - 200); // Dự phòng
      }
      // Delay 0.8s để engine khởi động
      await Future.delayed(const Duration(milliseconds: 800));
      await _tts.speak(" ");
      await Future.delayed(const Duration(milliseconds: 500));

      _speakCompleter =
          Completer<void>();

      for (int i = 0; i < content.length; i += chunkSize) {
        int end = (i + chunkSize).clamp(0, content.length);
        String chunk = content.substring(i, end);

        if (end < content.length) {
          int lastSpace = chunk.lastIndexOf(RegExp(r'\s'));
          if (lastSpace != -1 && lastSpace > chunk.length - 100) {
            end = i + lastSpace + 1;
            chunk = content.substring(i, end);
          }
        }

        await _tts.speak(chunk);
        await _tts.awaitSpeakCompletion(true);
        await Future.delayed(
            const Duration(milliseconds: 300));

        if (_isPaused) {
          break;
        }
      }

      _speakCompleter?.complete();

      if (playbackState.value.playing) {
        await skipToNext();
      }
    } catch (e) {
      _speakCompleter?.completeError(e);
      await skipToNext();
    }
  }

  @override
  Future<void> skipToNext() async {
    if (_isFetchingMore) return;

    if (_currentIndex < _playlist.value.length - 1) {
      await skipToQueueItem(_currentIndex + 1);
      await play();
    } else {
      if (_isLastPage || _currentComic == null) {
        await stop();
        return;
      }

      _isFetchingMore = true;
      playbackState.add(playbackState.value
          .copyWith(processingState: AudioProcessingState.loading));

      try {
        _currentPage++;
        final dataState = await _getChaptersPerPage(
            id: _currentComic!.id!, page: _currentPage);

        if (dataState is DataSuccess && dataState.data!.isNotEmpty) {
          final newChapters = dataState.data!;
          final newMediaItems =
              _chaptersToMediaItems(newChapters, _currentComic!.title!);

          final currentList = _playlist.value;
          currentList.addAll(newMediaItems);
          _playlist.add(currentList);
          queue.add(List.from(currentList));

          await skipToQueueItem(_currentIndex + 1);
          await play();
        } else {
          _isLastPage = true;
          await stop();
        }
      } catch (e) {
        await stop();
      } finally {
        _isFetchingMore = false;
      }
    }
  }

  @override
  Future<void> pause() async {
    _isPaused = true;
    await _tts.pause();
    playbackState.add(playbackState.value.copyWith(playing: false));
  }

  @override
  Future<void> stop() async {
    _isPaused = false;
    _lastSpokenIndex = 0;
    await _tts.stop();
    _currentIndex = -1;
    _currentComic = null;
    _currentPage = 1;
    _isLastPage = false;
    _playlist.add([]);
    queue.add([]);
    mediaItem.add(null);
    playbackState.add(playbackState.value
        .copyWith(playing: false, processingState: AudioProcessingState.idle));
  }

  @override
  Future<void> skipToPrevious() async {
    if (_currentIndex > 0) {
      await skipToQueueItem(_currentIndex - 1);
      await play();
    }
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= _playlist.value.length) return;
    _currentIndex = index;
    mediaItem.add(_playlist.value[index]);
  }

  List<MediaItem> _chaptersToMediaItems(
      List<ChapterEntity> chapters, String comicTitle) {
    return chapters
        .map((chapter) => MediaItem(
              id: chapter.id,
              title: chapter.name ?? 'Chương không tên',
              album: comicTitle,
              artist: 'Minh Nguyệt Truyện',
              extras: const {'content': null},
            ))
        .toList();
  }

  @override
  Future<void> addQueueItems(List<MediaItem> mediaItems) async {
    final newList = _playlist.value..addAll(mediaItems);
    _playlist.add(newList);
    queue.add(newList);
  }
}
