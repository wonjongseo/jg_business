import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:jg_business/shared/models/location_coordinate.dart';

/// 모바일 기기에서 주소를 좌표로 바꾸는 서비스다.
class LocationResolverService {
  /// 같은 주소를 반복 변환하지 않도록 메모리 캐시를 둔다.
  final _cache = <String, LocationCoordinate?>{};

  /// 원본 주소를 몇 가지 형태로 정리해가며 geocoding 을 시도한다.
  Future<LocationCoordinate?> resolve(String? address) async {
    final normalized = address?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }

    if (_cache.containsKey(normalized)) {
      return _cache[normalized];
    }

    // 일본 주소는 우편번호, 층수, 빌딩명 때문에 실패하는 경우가 많아서
    // 단순화한 후보 문자열을 순서대로 재시도한다.
    for (final candidate in _buildCandidates(normalized)) {
      try {
        final locations = await locationFromAddress(candidate);
        final first = locations.isNotEmpty ? locations.first : null;
        final coordinate =
            first == null
                ? null
                : LocationCoordinate(
                  latitude: first.latitude,
                  longitude: first.longitude,
                );

        if (coordinate != null) {
          _cache[normalized] = coordinate;
          debugPrint(
            'location_resolver_success'
            ' | original=$normalized'
            ' | candidate=$candidate'
            ' | lat=${coordinate.latitude}'
            ' | lng=${coordinate.longitude}',
          );
          return coordinate;
        }
      } catch (error) {
        debugPrint(
          'location_resolver_failed'
          ' | original=$normalized'
          ' | candidate=$candidate'
          ' | error=$error',
        );
      }
    }

    // 모든 후보가 실패하면 null 을 캐시에 남겨 같은 실패를 반복하지 않는다.
    _cache[normalized] = null;
    return null;
  }

  /// geocoding 성공률을 높이기 위해 주소를 점진적으로 단순화한다.
  List<String> _buildCandidates(String address) {
    final compact = address
        .replaceAll('〒', '')
        .replaceAll('−', '-')
        .replaceAll('ー', '-')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    final withoutFloor = compact.replaceAll(
      RegExp(r'[, ]+\S*(?:\d+F|[0-9]+階)\s*$', caseSensitive: false),
      '',
    );
    final commaParts = withoutFloor
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();

    final candidates = <String>[
      compact,
      withoutFloor,
      if (commaParts.length >= 4) commaParts.take(4).join(', '),
      if (commaParts.length >= 3) commaParts.take(3).join(', '),
      if (commaParts.isNotEmpty) commaParts.last,
    ];

    return candidates.toSet().where((value) => value.isNotEmpty).toList();
  }
}
