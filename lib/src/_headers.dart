class LinkHeader {
  final String next;
  final String prev;
  final String first;
  final String last;

  const LinkHeader({this.next, this.prev, this.first, this.last});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LinkHeader &&
          runtimeType == other.runtimeType &&
          next == other.next &&
          prev == other.prev &&
          first == other.first &&
          last == other.last;

  @override
  int get hashCode =>
      (next?.hashCode ?? 0) ^
      (prev?.hashCode ?? 0) ^
      (first?.hashCode ?? 0) ^
      (last?.hashCode ?? 0);

  @override
  String toString() {
    return '{next: $next, prev: $prev, first: $first, last: $last}';
  }
}

LinkHeader parseLinkHeader(String value) {
  if (value == null) return null;
  String next, prev, first, last;
  final parts = value.split(",");
  parts.map((p) => p.split(";")).forEach((itemParts) {
    if (itemParts.length != 2) return null;
    String linkPart = _linkFrom(itemParts[0]);
    String rel = _parseRel(itemParts[1].trim());
    switch (rel) {
      case 'next':
        next = linkPart;
        break;
      case 'prev':
        prev = linkPart;
        break;
      case 'first':
        first = linkPart;
        break;
      case 'last':
        last = linkPart;
    }
  });
  if (first == null && last == null && prev == null && next == null) {
    return null;
  }
  return LinkHeader(first: first, last: last, prev: prev, next: next);
}

String _linkFrom(String part) {
  final i = part.indexOf('<');
  if (i < 0) return null;
  final j = part.indexOf('>', i);
  if (j <= i + 1) return null;
  return part.substring(i + 1, j);
}

String _parseRel(String rel) {
  if (!rel.startsWith('rel="') || !rel.endsWith('"')) {
    return null;
  }
  return rel.substring('rel="'.length, rel.length - 1);
}
