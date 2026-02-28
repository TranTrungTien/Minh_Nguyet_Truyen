import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:minh_nguyet_truyen/app/presentaion/blocs/audio/audio_player_handler.dart';
import 'package:minh_nguyet_truyen/core/constants/colors.dart';
import 'package:miniplayer/miniplayer.dart';

class GlobalMiniPlayer extends StatelessWidget {
  const GlobalMiniPlayer({super.key});

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
                Expanded(
                    child: Row(
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
                          icon:
                              Icon(isPlaying ? Icons.pause : Icons.play_arrow),
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
                    )
                  ],
                )),
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
