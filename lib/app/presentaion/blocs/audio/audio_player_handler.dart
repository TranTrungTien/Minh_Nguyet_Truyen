import 'dart:async';

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
  int _currentSessionId = 0;
  int _currentChunkOffset = 0;
  bool _isSkipping = false;

  AudioPlayerHandler(this._getContentOneChapter, this._getChaptersPerPage) {
    _initTts();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage("vi-VN");
    await _tts.awaitSpeakCompletion(true);

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
    if (item == null || _currentIndex == -1) return;

    var content = item.extras?['content'] as String?;
    if (content == null || content.isEmpty) {
      playbackState.add(playbackState.value.copyWith(
        processingState: AudioProcessingState.loading,
      ));

      final comicId = _currentComic?.id;
      if (comicId != null) {
        final dataState = await _getContentOneChapter(
          comicId: comicId,
          chapterId: item.id,
        );

        if (dataState is DataSuccess && dataState.data?.content != null) {
          content = _cleanContent(dataState.data!.content!);
          final updatedItem = item.copyWith(
            extras: {...?item.extras, 'content': content},
          );
          _playlist.value[_currentIndex] = updatedItem;
          mediaItem.add(updatedItem);
          _playlist.add(List.from(_playlist.value));
        }
      }
    }

    if (content == null || content.isEmpty) {
      await skipToNext();
      return;
    }

    _currentSessionId++;
    final sessionId = _currentSessionId;

    playbackState.add(playbackState.value.copyWith(
      playing: true,
      processingState: AudioProcessingState.ready,
    ));

    try {
      if (_isPaused) {
        _isPaused = false;
        if (_lastSpokenIndex >= content.length) {
          await skipToNext();
          return;
        }

        await Future.delayed(const Duration(milliseconds: 600));

        await _speakInChunks(content, sessionId, startOffset: _lastSpokenIndex);
      } else {
        _lastSpokenIndex = 0;
        await _tts.stop();

        await Future.delayed(const Duration(milliseconds: 300));
        if (sessionId != _currentSessionId) return;

        await _speakInChunks(content, sessionId, startOffset: 0);
      }
    } catch (e) {
      playbackState.add(playbackState.value.copyWith(
        processingState: AudioProcessingState.error,
      ));
    }
  }

  String _cleanContent(String content) {
    return content
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('\r\n', ' ')
        .replaceAll('\n', ' ')
        .replaceAll('\r', ' ')
        .replaceAll(RegExp(r' {2,}'), ' ')
        .trim();
  }

  Future<void> _speakInChunks(String fullContent, int sessionId,
      {int startOffset = 0}) async {
    if (fullContent.isEmpty) return;

    const int chunkSize = 1000;
    final textToRead =
        startOffset > 0 ? fullContent.substring(startOffset) : fullContent;

    int i = 0;
    while (i < textToRead.length) {
      if (sessionId != _currentSessionId || _isPaused) return;

      int end = (i + chunkSize).clamp(0, textToRead.length);
      String chunk = textToRead.substring(i, end);

      if (end < textToRead.length) {
        int lastSpace = chunk.lastIndexOf(' ');
        if (lastSpace != -1 && lastSpace > chunk.length - 100) {
          end = i + lastSpace + 1;
          chunk = textToRead.substring(i, end);
        }
      }

      _currentChunkOffset = startOffset + i;
      _lastSpokenIndex = _currentChunkOffset;

      await _tts.speak(chunk);

      if (sessionId != _currentSessionId || _isPaused) return;

      i = end;
    }

    await Future.delayed(const Duration(milliseconds: 300));

    if (sessionId == _currentSessionId &&
        !_isPaused &&
        playbackState.value.playing) {
      await skipToNext();
    }
  }

  @override
  Future<void> skipToNext() async {
    if (_isFetchingMore || _isSkipping) return;
    _isSkipping = true;

    try {
      _currentSessionId++;
      try {
        await _tts.stop();
      } catch (_) {}

      if (_currentIndex < _playlist.value.length - 1) {
        await skipToQueueItem(_currentIndex + 1);
        _isSkipping = false;
        await play();
      } else {
        if (_isLastPage || _currentComic == null) {
          await stop();
          return;
        }

        _isFetchingMore = true;
        playbackState.add(playbackState.value.copyWith(
          processingState: AudioProcessingState.loading,
        ));

        try {
          _currentPage++;
          final dataState = await _getChaptersPerPage(
            id: _currentComic!.id!,
            page: _currentPage,
          );

          if (dataState is DataSuccess && dataState.data!.isNotEmpty) {
            final newMediaItems =
                _chaptersToMediaItems(dataState.data!, _currentComic!.title!);
            final currentList = _playlist.value;
            currentList.addAll(newMediaItems);
            _playlist.add(currentList);
            queue.add(List.from(currentList));

            await skipToQueueItem(_currentIndex + 1);
            _isSkipping = false; // ✅ Reset trước khi play
            await play();
          } else {
            _isLastPage = true;
            await stop();
          }
        } catch (e) {
          print('skip e $e');
          await stop();
        } finally {
          _isFetchingMore = false;
        }
      }
    } finally {
      _isSkipping =
          false; // ✅ Vẫn giữ để catch các path còn lại (stop, error...)
    }
  }

  @override
  Future<void> pause() async {
    _isPaused = true;
    _currentSessionId++;
    try {
      await _tts.stop();
    } catch (e) {}
    playbackState.add(playbackState.value.copyWith(playing: false));
  }

  @override
  Future<void> stop() async {
    _isPaused = false;
    _isSkipping = false;
    _currentSessionId++;
    _lastSpokenIndex = 0;
    try {
      await _tts.stop();
    } catch (_) {}
    _currentIndex = -1;
    _currentComic = null;
    _currentPage = 1;
    _isLastPage = false;
    _playlist.add([]);
    queue.add([]);
    mediaItem.add(null);
    playbackState.add(playbackState.value.copyWith(
      playing: false,
      processingState: AudioProcessingState.idle,
    ));
  }

  @override
  Future<void> skipToPrevious() async {
    if (_currentIndex > 0) {
      _currentSessionId++;
      await _tts.stop();
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
