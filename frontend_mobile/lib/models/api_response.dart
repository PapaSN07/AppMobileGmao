
class ApiResponse<T> {
  List<T> items;
  PaginationInfo pagination;
  bool filtersApplied;

  ApiResponse({
    required this.items,
    required this.pagination,
    required this.filtersApplied,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json, {required String nameItem, required T Function(Map<String, dynamic>) fromJson}) {
    return ApiResponse(
      items: (json[nameItem] as List? ?? [])
          .map((e) => fromJson(e))
          .toList(),
      pagination: PaginationInfo.fromJson(json['pagination'] ?? {}),
      filtersApplied: json['filters_applied'] ?? false,
    );
  }
}

class PaginationInfo {
  String? nextCursor;
  bool hasMore;
  int count;
  int requestedLimit;

  PaginationInfo({
    this.nextCursor,
    required this.hasMore,
    required this.count,
    required this.requestedLimit,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      nextCursor: json['next_cursor'],
      hasMore: json['has_more'] ?? false,
      count: json['count'] ?? 0,
      requestedLimit: json['requested_limit'] ?? 20,
    );
  }
}
