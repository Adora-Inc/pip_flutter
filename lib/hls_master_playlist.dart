import 'package:pip_flutter/drm_init_data.dart';
import 'package:pip_flutter/format.dart';
import 'package:pip_flutter/playlist.dart';
import 'package:pip_flutter/rendition.dart';
import 'package:pip_flutter/variant.dart';

class HlsMasterPlaylist extends HlsPlaylist {
  HlsMasterPlaylist({
    super.baseUri,
    super.tags = const [], // ignore: always_specify_types
    this.variants = const [], // ignore: always_specify_types
    this.videos = const [], // ignore: always_specify_types
    this.audios = const [], // ignore: always_specify_types
    this.subtitles = const [], // ignore: always_specify_types
    this.closedCaptions = const [], // ignore: always_specify_types
    this.muxedAudioFormat,
    this.muxedCaptionFormats = const [], // ignore: always_specify_types
    super.hasIndependentSegments = false,
    this.variableDefinitions = const {}, // ignore: always_specify_types
    this.sessionKeyDrmInitData = const [], // ignore: always_specify_types
  })  : mediaPlaylistUrls = _getMediaPlaylistUrls(
            variants, [videos, audios, subtitles, closedCaptions]);

  /// All of the media playlist URLs referenced by the playlist.
  final List<Uri?> mediaPlaylistUrls;

  /// The variants declared by the playlist.
  final List<Variant> variants;

  /// The video renditions declared by the playlist.
  final List<Rendition> videos;

  /// The audio renditions declared by the playlist.
  final List<Rendition> audios;

  /// The subtitle renditions declared by the playlist.
  final List<Rendition> subtitles;

  /// The closed caption renditions declared by the playlist.
  final List<Rendition> closedCaptions;

  ///The format of the audio muxed in the variants. May be null if the playlist does not declare any mixed audio.
  final Format? muxedAudioFormat;

  ///The format of the closed captions declared by the playlist. May be empty if the playlist
  ///explicitly declares no captions are available, or null if the playlist does not declare any
  ///captions information.
  final List<Format>? muxedCaptionFormats;

  /// Contains variable definitions, as defined by the #EXT-X-DEFINE tag.
  final Map<String?, String> variableDefinitions;

  /// DRM initialization data derived from #EXT-X-SESSION-KEY tags.
  final List<DrmInitData> sessionKeyDrmInitData;

  static List<Uri?> _getMediaPlaylistUrls(
      List<Variant> variants, List<List<Rendition>> renditionList) {
    final uriList = <Uri?>[];
    for (var element in variants) {
      uriList.add(element.url);
    }
    for (var element in renditionList) {
      for (final value in element) {
        uriList.add(value.url);
      }
    }
    return uriList;
  }
}
