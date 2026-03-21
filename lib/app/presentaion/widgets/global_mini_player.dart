import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:minh_nguyet_truyen/app/presentaion/blocs/audio/audio_player_handler.dart';
import 'package:minh_nguyet_truyen/core/constants/colors.dart';
import 'package:minh_nguyet_truyen/services/audio_daily_limit_service.dart';
import 'package:miniplayer/miniplayer.dart';

class GlobalMiniPlayer extends StatefulWidget {
  const GlobalMiniPlayer({super.key});

  @override
  State<GlobalMiniPlayer> createState() => _GlobalMiniPlayerState();
}

class _GlobalMiniPlayerState extends State<GlobalMiniPlayer> {
  @override
  void initState() {
    super.initState();
    final handler = getIt<AudioHandler>();
    if (handler is AudioPlayerHandler) {
      handler.dailyLimitReached.listen((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Bạn đã hết ${AudioDailyLimitService.dailyLimit} lượt nghe hôm nay. Vui lòng quay lại ngày mai!'),
              duration: Duration(seconds: 4),
            ),
          );
        }
      });
    }
  }

  @override
  void dispose() {
    final handler = getIt<AudioHandler>();
    if (handler is AudioPlayerHandler) {
      handler.dailyLimitReachedController.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final MiniplayerController controller = MiniplayerController();
    const double playerMinHeight = 70.0;

    return StreamBuilder<PlaybackState>(
      stream: getIt<AudioHandler>().playbackState,
      builder: (context, snapshot) {
        final playbackState = snapshot.data;
        final processingState =
            playbackState?.processingState ?? AudioProcessingState.idle;

        // Chỉ hiển thị khi có nhạc
        if (processingState == AudioProcessingState.idle ||
            processingState == AudioProcessingState.completed ||
            processingState == AudioProcessingState.error) {
          return const SizedBox.shrink();
        }

        return Miniplayer(
          controller: controller,
          minHeight: playerMinHeight,
          maxHeight: MediaQuery.of(context).size.height,
          builder: (height, percentage) {
            return _buildMiniPlayerUI(context, height, percentage);
          },
        );
      },
    );
  }

  Widget _buildMiniPlayerUI(
      BuildContext context, double height, double percentage) {
    return Container(
      color: Theme.of(context).cardColor.withOpacity(0.98),
      child: StreamBuilder<MediaItem?>(
        stream: getIt<AudioHandler>().mediaItem,
        builder: (context, snapshot) {
          final mediaItem = snapshot.data;
          if (mediaItem == null) return const SizedBox.shrink();

          return ListTile(
            leading: const Icon(Icons.music_note, color: AppColors.primary),
            title: Text(
              mediaItem.album ?? 'Đang phát',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              mediaItem.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.skip_previous),
                  onPressed: getIt<AudioHandler>().skipToPrevious,
                ),
                StreamBuilder<PlaybackState>(
                  stream: getIt<AudioHandler>().playbackState,
                  builder: (context, snapshot) {
                    final isPlaying = snapshot.data?.playing ?? false;
                    return IconButton(
                      icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                      iconSize: 32.0,
                      onPressed: isPlaying
                          ? getIt<AudioHandler>().pause
                          : getIt<AudioHandler>().play,
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next),
                  onPressed: getIt<AudioHandler>().skipToNext,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: getIt<AudioHandler>().stop,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
