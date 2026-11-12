/// Diff ligne à ligne simplifié (plus longue sous-séquence commune), au format
/// unifié de Git avec un seul bloc couvrant le fichier.
String unifiedDiff(String path, String? before, String? after) {
  List<String> lines(String? s) {
    if (s == null || s.isEmpty) return const [];
    final l = s.split('\n');
    if (l.last.isEmpty) l.removeLast();
    return l;
  }

  final a = lines(before), b = lines(after);
  final n = a.length, m = b.length;
  final lcs = List.generate(n + 1, (_) => List.filled(m + 1, 0));
  for (var i = n - 1; i >= 0; i--) {
    for (var j = m - 1; j >= 0; j--) {
      lcs[i][j] = a[i] == b[j]
          ? lcs[i + 1][j + 1] + 1
          : (lcs[i + 1][j] >= lcs[i][j + 1] ? lcs[i + 1][j] : lcs[i][j + 1]);
    }
  }
  final body = <String>[];
  var i = 0, j = 0;
  while (i < n && j < m) {
    if (a[i] == b[j]) {
      body.add(' ${a[i]}');
      i++;
      j++;
    } else if (lcs[i + 1][j] >= lcs[i][j + 1]) {
      body.add('-${a[i++]}');
    } else {
      body.add('+${b[j++]}');
    }
  }
  while (i < n) {
    body.add('-${a[i++]}');
  }
  while (j < m) {
    body.add('+${b[j++]}');
  }
  final header = StringBuffer('diff --git a/$path b/$path\n');
  if (before == null) header.write('new file mode 100644\n');
  if (after == null) header.write('deleted file mode 100644\n');
  header
    ..write('--- ${before == null ? '/dev/null' : 'a/$path'}\n')
    ..write('+++ ${after == null ? '/dev/null' : 'b/$path'}\n')
    ..write('@@ -${n == 0 ? 0 : 1},$n +${m == 0 ? 0 : 1},$m @@');
  return [header.toString(), ...body].join('\n');
}
