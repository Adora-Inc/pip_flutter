import 'dart:io';
import 'dart:math';

import 'package:collection/collection.dart' show IterableExtension;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pip_flutter/pipflutter_player_asms_audio_track.dart';
import 'package:pip_flutter/pipflutter_player_asms_track.dart';
import 'package:pip_flutter/pipflutter_player_clickable_widget.dart';
import 'package:pip_flutter/pipflutter_player_controller.dart';
import 'package:pip_flutter/pipflutter_player_controls_configuration.dart';
import 'package:pip_flutter/pipflutter_player_event.dart';
import 'package:pip_flutter/pipflutter_player_event_type.dart';
import 'package:pip_flutter/pipflutter_player_subtitles_source.dart';
import 'package:pip_flutter/pipflutter_player_subtitles_source_type.dart';
import 'package:pip_flutter/pipflutter_player_utils.dart';
import 'package:pip_flutter/video_player.dart';

///Base class for both material and cupertino controls
abstract class PipFlutterPlayerControlsState<T extends StatefulWidget>
    extends State<T> {
  ///Min. time of buffered video to hide loading timer (in milliseconds)
  static const int _bufferingInterval = 20000;

  PipFlutterPlayerController? get pipFlutterPlayerController;

  PipFlutterPlayerControlsConfiguration
      get pipFlutterPlayerControlsConfiguration;

  VideoPlayerValue? get latestValue;

  bool controlsNotVisible = true;

  void cancelAndRestartTimer();

  bool isVideoFinished(VideoPlayerValue? videoPlayerValue) {
    return videoPlayerValue?.position != null &&
        videoPlayerValue?.duration != null &&
        videoPlayerValue!.position.inMilliseconds != 0 &&
        videoPlayerValue.duration!.inMilliseconds != 0 &&
        videoPlayerValue.position >= videoPlayerValue.duration!;
  }

  Future<void> skipBack() async {
    if (latestValue != null) {
      cancelAndRestartTimer();
      final beginning = const Duration().inMilliseconds;
      final skip = (latestValue!.position -
              Duration(
                  milliseconds: pipFlutterPlayerControlsConfiguration
                      .backwardSkipTimeInMilliseconds))
          .inMilliseconds;
      await pipFlutterPlayerController!
          .seekTo(Duration(milliseconds: max(skip, beginning)));
    }
  }

  Future<void> skipForward() async {
    if (latestValue != null) {
      cancelAndRestartTimer();
      final end = latestValue!.duration!.inMilliseconds;
      final skip = (latestValue!.position +
              Duration(
                  milliseconds: pipFlutterPlayerControlsConfiguration
                      .forwardSkipTimeInMilliseconds))
          .inMilliseconds;
      await pipFlutterPlayerController!
          .seekTo(Duration(milliseconds: min(skip, end)));
    }
  }

  Future<void> onShowMoreClicked() async {
    await _showModalBottomSheet([_buildMoreOptionsList()]);
  }

  Widget _buildMoreOptionsList() {
    final translations = pipFlutterPlayerController!.translations;
    return SingleChildScrollView(
      // ignore: avoid_unnecessary_containers
      child: Container(
        child: Column(
          children: [
            if (pipFlutterPlayerControlsConfiguration.enablePlaybackSpeed)
              _buildMoreOptionsListRow(
                  pipFlutterPlayerControlsConfiguration.playbackSpeedIcon,
                  translations.overflowMenuPlaybackSpeed, () async {
                Navigator.of(context).pop();
                await _showSpeedChooserWidget();
              }),
            if (pipFlutterPlayerControlsConfiguration.enableSubtitles)
              _buildMoreOptionsListRow(
                  pipFlutterPlayerControlsConfiguration.subtitlesIcon,
                  translations.overflowMenuSubtitles, () async {
                Navigator.of(context).pop();
                await _showSubtitlesSelectionWidget();
              }),
            if (pipFlutterPlayerControlsConfiguration.enableQualities)
              _buildMoreOptionsListRow(
                  pipFlutterPlayerControlsConfiguration.qualitiesIcon,
                  translations.overflowMenuQuality, () async {
                Navigator.of(context).pop();
                await _showQualitiesSelectionWidget();
              }),
            if (pipFlutterPlayerControlsConfiguration.enableAudioTracks)
              _buildMoreOptionsListRow(
                  pipFlutterPlayerControlsConfiguration.audioTracksIcon,
                  translations.overflowMenuAudioTracks, () async {
                Navigator.of(context).pop();
                await _showAudioTracksSelectionWidget();
              }),
            if (pipFlutterPlayerControlsConfiguration
                .overflowMenuCustomItems.isNotEmpty)
              ...pipFlutterPlayerControlsConfiguration.overflowMenuCustomItems
                  .map(
                (customItem) => _buildMoreOptionsListRow(
                  customItem.icon,
                  customItem.title,
                  () {
                    Navigator.of(context).pop();
                    customItem.onClicked.call();
                  },
                ),
              )
          ],
        ),
      ),
    );
  }

  Widget _buildMoreOptionsListRow(
      IconData icon, String name, void Function() onTap) {
    return PipFlutterPlayerMaterialClickableWidget(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Row(
          children: [
            const SizedBox(width: 8),
            Icon(
              icon,
              color:
                  pipFlutterPlayerControlsConfiguration.overflowMenuIconsColor,
            ),
            const SizedBox(width: 16),
            Text(
              name,
              style: _getOverflowMenuElementTextStyle(false),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showSpeedChooserWidget() async {
    await _showModalBottomSheet([
      _buildSpeedRow(0.25),
      _buildSpeedRow(0.5),
      _buildSpeedRow(0.75),
      _buildSpeedRow(1.0),
      _buildSpeedRow(1.25),
      _buildSpeedRow(1.5),
      _buildSpeedRow(1.75),
      _buildSpeedRow(2.0),
    ]);
  }

  Widget _buildSpeedRow(double value) {
    final bool isSelected =
        pipFlutterPlayerController!.videoPlayerController!.value.speed == value;

    return PipFlutterPlayerMaterialClickableWidget(
      onTap: () async {
        Navigator.of(context).pop();
        await pipFlutterPlayerController!.setSpeed(value);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            SizedBox(width: isSelected ? 8 : 16),
            Visibility(
                visible: isSelected,
                child: Icon(
                  Icons.check_outlined,
                  color: pipFlutterPlayerControlsConfiguration
                      .overflowModalTextColor,
                )),
            const SizedBox(width: 16),
            Text(
              "$value x",
              style: _getOverflowMenuElementTextStyle(isSelected),
            )
          ],
        ),
      ),
    );
  }

  ///Latest value can be null
  bool isLoading(VideoPlayerValue? latestValue) {
    if (latestValue != null) {
      if (!latestValue.isPlaying && latestValue.duration == null) {
        return true;
      }

      final Duration position = latestValue.position;

      Duration? bufferedEndPosition;
      if (latestValue.buffered.isNotEmpty == true) {
        bufferedEndPosition = latestValue.buffered.last.end;
      }

      if (bufferedEndPosition != null) {
        final difference = bufferedEndPosition - position;

        if (latestValue.isPlaying &&
            latestValue.isBuffering &&
            difference.inMilliseconds < _bufferingInterval) {
          return true;
        }
      }
    }
    return false;
  }

  Future<void> _showSubtitlesSelectionWidget() async {
    final subtitles = List.of(
        pipFlutterPlayerController!.pipFlutterPlayerSubtitlesSourceList);
    final noneSubtitlesElementExists = subtitles.firstWhereOrNull((source) =>
            source.type == PipFlutterPlayerSubtitlesSourceType.none) !=
        null;
    if (!noneSubtitlesElementExists) {
      subtitles.add(PipFlutterPlayerSubtitlesSource(
          type: PipFlutterPlayerSubtitlesSourceType.none));
    }

    await _showModalBottomSheet(
        subtitles.map((source) => _buildSubtitlesSourceRow(source)).toList());
  }

  Widget _buildSubtitlesSourceRow(
      PipFlutterPlayerSubtitlesSource subtitlesSource) {
    final selectedSourceType =
        pipFlutterPlayerController!.pipFlutterPlayerSubtitlesSource;
    final bool isSelected = (subtitlesSource == selectedSourceType) ||
        (subtitlesSource.type == PipFlutterPlayerSubtitlesSourceType.none &&
            subtitlesSource.type == selectedSourceType!.type);

    return PipFlutterPlayerMaterialClickableWidget(
      onTap: () async {
        Navigator.of(context).pop();
        await pipFlutterPlayerController!.setupSubtitleSource(subtitlesSource);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            SizedBox(width: isSelected ? 8 : 16),
            Visibility(
                visible: isSelected,
                child: Icon(
                  Icons.check_outlined,
                  color: pipFlutterPlayerControlsConfiguration
                      .overflowModalTextColor,
                )),
            const SizedBox(width: 16),
            Text(
              subtitlesSource.type == PipFlutterPlayerSubtitlesSourceType.none
                  ? pipFlutterPlayerController!.translations.generalNone
                  : subtitlesSource.name ??
                      pipFlutterPlayerController!.translations.generalDefault,
              style: _getOverflowMenuElementTextStyle(isSelected),
            ),
          ],
        ),
      ),
    );
  }

  ///Build both track and resolution selection
  ///Track selection is used for HLS / DASH videos
  ///Resolution selection is used for normal videos
  Future<void> _showQualitiesSelectionWidget() async {
    // HLS / DASH
    final List<String> asmsTrackNames = pipFlutterPlayerController!
            .pipFlutterPlayerDataSource!.asmsTrackNames ??
        [];
    final List<PipFlutterPlayerAsmsTrack> asmsTracks =
        pipFlutterPlayerController!.pipFlutterPlayerAsmsTracks;
    final List<Widget> children = [];
    for (var index = 0; index < asmsTracks.length; index++) {
      final track = asmsTracks[index];

      String? preferredName;
      if (track.height == 0 && track.width == 0 && track.bitrate == 0) {
        preferredName = pipFlutterPlayerController!.translations.qualityAuto;
      } else {
        preferredName =
            asmsTrackNames.length > index ? asmsTrackNames[index] : null;
      }
      children.add(_buildTrackRow(asmsTracks[index], preferredName));
    }

    // normal videos
    final resolutions =
        pipFlutterPlayerController!.pipFlutterPlayerDataSource!.resolutions;
    resolutions?.forEach((key, value) {
      children.add(_buildResolutionSelectionRow(key, value));
    });

    if (children.isEmpty) {
      children.add(
        _buildTrackRow(PipFlutterPlayerAsmsTrack.defaultTrack(),
            pipFlutterPlayerController!.translations.qualityAuto),
      );
    }

    await _showModalBottomSheet(children);
  }

  Widget _buildTrackRow(
      PipFlutterPlayerAsmsTrack track, String? preferredName) {
    final int width = track.width ?? 0;
    final int height = track.height ?? 0;
    final int bitrate = track.bitrate ?? 0;
    final String mimeType = (track.mimeType ?? '').replaceAll('video/', '');
    final String trackName = preferredName ??
        "${width}x$height ${PipFlutterPlayerUtils.formatBitrate(bitrate)} $mimeType";

    final PipFlutterPlayerAsmsTrack? selectedTrack =
        pipFlutterPlayerController!.pipFlutterPlayerAsmsTrack;
    final bool isSelected = selectedTrack != null && selectedTrack == track;

    return PipFlutterPlayerMaterialClickableWidget(
      onTap: () async {
        Navigator.of(context).pop();
        await pipFlutterPlayerController!.setTrack(track);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            SizedBox(width: isSelected ? 8 : 16),
            Visibility(
                visible: isSelected,
                child: Icon(
                  Icons.check_outlined,
                  color: pipFlutterPlayerControlsConfiguration
                      .overflowModalTextColor,
                )),
            const SizedBox(width: 16),
            Text(
              trackName,
              style: _getOverflowMenuElementTextStyle(isSelected),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResolutionSelectionRow(String name, String url) {
    final bool isSelected =
        url == pipFlutterPlayerController!.pipFlutterPlayerDataSource!.url;
    return PipFlutterPlayerMaterialClickableWidget(
      onTap: () async {
        Navigator.of(context).pop();
        await pipFlutterPlayerController!.setResolution(url);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            SizedBox(width: isSelected ? 8 : 16),
            Visibility(
                visible: isSelected,
                child: Icon(
                  Icons.check_outlined,
                  color: pipFlutterPlayerControlsConfiguration
                      .overflowModalTextColor,
                )),
            const SizedBox(width: 16),
            Text(
              name,
              style: _getOverflowMenuElementTextStyle(isSelected),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAudioTracksSelectionWidget() async {
    //HLS / DASH
    final List<PipFlutterPlayerAsmsAudioTrack>? asmsTracks =
        pipFlutterPlayerController!.pipFlutterPlayerAsmsAudioTracks;
    final List<Widget> children = [];
    final PipFlutterPlayerAsmsAudioTrack? selectedAsmsAudioTrack =
        pipFlutterPlayerController!.pipFlutterPlayerAsmsAudioTrack;
    if (asmsTracks != null) {
      for (var index = 0; index < asmsTracks.length; index++) {
        final bool isSelected = selectedAsmsAudioTrack != null &&
            selectedAsmsAudioTrack == asmsTracks[index];
        children.add(_buildAudioTrackRow(asmsTracks[index], isSelected));
      }
    }

    if (children.isEmpty) {
      children.add(
        _buildAudioTrackRow(
          PipFlutterPlayerAsmsAudioTrack(
            label: pipFlutterPlayerController!.translations.generalDefault,
          ),
          true,
        ),
      );
    }

    await _showModalBottomSheet(children);
  }

  Widget _buildAudioTrackRow(
      PipFlutterPlayerAsmsAudioTrack audioTrack, bool isSelected) {
    return PipFlutterPlayerMaterialClickableWidget(
      onTap: () async {
        Navigator.of(context).pop();
        await pipFlutterPlayerController!.setAudioTrack(audioTrack);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            SizedBox(width: isSelected ? 8 : 16),
            Visibility(
                visible: isSelected,
                child: Icon(
                  Icons.check_outlined,
                  color: pipFlutterPlayerControlsConfiguration
                      .overflowModalTextColor,
                )),
            const SizedBox(width: 16),
            Text(
              audioTrack.label!,
              style: _getOverflowMenuElementTextStyle(isSelected),
            ),
          ],
        ),
      ),
    );
  }

  TextStyle _getOverflowMenuElementTextStyle(bool isSelected) {
    return TextStyle(
      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      color: isSelected
          ? pipFlutterPlayerControlsConfiguration.overflowModalTextColor
          : pipFlutterPlayerControlsConfiguration.overflowModalTextColor
              .withOpacity(0.7),
    );
  }

  Future<void> _showModalBottomSheet(List<Widget> children) async {
    return Platform.isAndroid
        ? _showMaterialBottomSheet(children)
        : _showCupertinoModalBottomSheet(children);
  }

  Future<void> _showCupertinoModalBottomSheet(List<Widget> children) async {
    await showCupertinoModalPopup<void>(
      barrierColor: Colors.transparent,
      context: context,
      useRootNavigator: pipFlutterPlayerController
              ?.pipFlutterPlayerConfiguration.useRootNavigator ??
          false,
      builder: (context) {
        return SafeArea(
          top: false,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              decoration: BoxDecoration(
                color: pipFlutterPlayerControlsConfiguration.overflowModalColor,
                /*shape: RoundedRectangleBorder(side: Bor,borderRadius: 24,)*/
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24.0),
                    topRight: Radius.circular(24.0)),
              ),
              child: Column(
                children: children,
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showMaterialBottomSheet(List<Widget> children) async {
    await showModalBottomSheet<void>(
      backgroundColor: Colors.transparent,
      context: context,
      useRootNavigator: pipFlutterPlayerController
              ?.pipFlutterPlayerConfiguration.useRootNavigator ??
          false,
      builder: (context) {
        return SafeArea(
          top: false,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              decoration: BoxDecoration(
                color: pipFlutterPlayerControlsConfiguration.overflowModalColor,
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24.0),
                    topRight: Radius.circular(24.0)),
              ),
              child: Column(
                children: children,
              ),
            ),
          ),
        );
      },
    );
  }

  ///Builds directionality widget which wraps child widget and forces left to
  ///right directionality.
  Widget buildLTRDirectionality(Widget child) {
    return Directionality(textDirection: TextDirection.ltr, child: child);
  }

  ///Called when player controls visibility should be changed.
  void changePlayerControlsNotVisible(bool notVisible) {
    setState(() {
      if (notVisible) {
        pipFlutterPlayerController?.postEvent(PipFlutterPlayerEvent(
            PipFlutterPlayerEventType.controlsHiddenStart));
      }
      controlsNotVisible = notVisible;
    });
  }
}
