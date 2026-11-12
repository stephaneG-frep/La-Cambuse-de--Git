/// Découpe une ligne de commande en arguments, à la manière d'un shell simple :
/// guillemets simples et doubles, échappement `\` dans les doubles, et
/// opérateurs de redirection `>` / `>>` isolés. Aucune expansion, aucune
/// substitution : rien n'est jamais interprété ni exécuté.
List<String> tokenize(String line) {
  final out = <String>[];
  final cur = StringBuffer();
  var inToken = false;
  String? quote;
  for (var i = 0; i < line.length; i++) {
    final c = line[i];
    if (quote != null) {
      if (c == quote) {
        quote = null;
      } else if (c == r'\' && quote == '"' && i + 1 < line.length) {
        cur.write(line[++i]);
      } else {
        cur.write(c);
      }
      continue;
    }
    if (c == '"' || c == "'") {
      quote = c;
      inToken = true;
    } else if (c == ' ' || c == '\t') {
      if (inToken) {
        out.add(cur.toString());
        cur.clear();
        inToken = false;
      }
    } else if (c == '>') {
      if (inToken) {
        out.add(cur.toString());
        cur.clear();
        inToken = false;
      }
      if (i + 1 < line.length && line[i + 1] == '>') {
        out.add('>>');
        i++;
      } else {
        out.add('>');
      }
    } else if (c == ';' || c == '|' || c == '&' || c == '`' || c == r'$') {
      throw FormatException(
          '« $c » n\'est pas accepté : le bac à sable n\'enchaîne ni ne substitue de commandes.');
    } else {
      cur.write(c);
      inToken = true;
    }
  }
  if (quote != null) throw const FormatException('guillemet non fermé');
  if (inToken) out.add(cur.toString());
  return out;
}
