// The Orchard path's kit (JRN-03, REW-04), ported from the prototype
// (orchard.html, 16 Nov: `OS`, `OG`, `OPR`, `OLM`). Every sprite is SVG
// markup drawn at the origin with its base at (0, 0); MiniSvg paints it.
// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, prefer_interpolation_to_compose_strings, avoid_dynamic_calls, unnecessary_string_interpolations
part of 'orchard_kit.dart';

class OS {
  static String round([dynamic pal, dynamic fruit, dynamic ph]) {
    final pp = (OPAL[pal ?? 'green'] ?? OPAL['green']!);
    final d = pp[0], m = pp[1], l = pp[2];
    var f = '';
    if (t(fruit)) {
      for (var k = 0; k < 5; k++) {
        final a = k * 1.3 + (ph ?? 0);
        f +=
            '''<ellipse cx="${(math.cos(a) * 14 * (0.5 + 0.5 * ((k * 7) % 3) / 2)).toStringAsFixed(1)}" cy="${(-34 + math.sin(a) * 12).toStringAsFixed(1)}" rx="3.6" ry="4.4" fill="${fruit}" stroke="rgba(0,0,0,0.14)" stroke-width="0.6"/>''';
      }
    }
    return '''${osh(4, 2, 22, 7)}<rect x="-3.5" y="-16" width="7" height="17" rx="3" fill="#8A5A34"/><g class="sway"><circle cx="-11" cy="-28" r="15" fill="${d}"/><circle cx="12" cy="-27" r="14" fill="${d}"/><circle cx="0" cy="-40" r="17" fill="${m}"/><circle cx="-5" cy="-45" r="9" fill="${l}" opacity="0.75"/>${f}</g>''';
  }

  static String fir([dynamic snow]) =>
      '''${osh(3, 2, 18, 6)}<rect x="-3" y="-10" width="6" height="11" rx="2" fill="#7A4E2B"/><g class="sway"><path d="M-19 -8 L0 -36 L19 -8 Z" fill="${t(snow) ? '#3E7F74' : '#1F6E55'}"/><path d="M-15 -24 L0 -50 L15 -24 Z" fill="${t(snow) ? '#4E948A' : '#2A8466'}"/><path d="M-10 -40 L0 -62 L10 -40 Z" fill="${t(snow) ? '#62A89E' : '#3A9C78'}"/>${t(snow) ? '<path d="M-7 -47 L0 -62 L7 -47 q-3.5 3 -7 0 q-3.5 3 -7 0 z M-11 -30 L-4 -42 q4 6 8 0 L11 -30 q-5 4 -11 0 q-6 4 -11 0 z M-15 -13 L-8 -25 q8 7 16 0 L15 -13 q-7 5 -15 0 q-8 5 -15 0 z" fill="#fff"/>' : '<path d="M-4 -46 L0 -58 l2 6 z" fill="#7FD0A8" opacity="0.7"/>'}</g>''';
  static String birch([dynamic pal]) {
    final pp = (OPAL[pal ?? 'green'] ?? OPAL['green']!);
    final d = pp[0], m = pp[1], l = pp[2];
    return '''${osh(3, 2, 15, 5)}<path d="M0 0 q-2 -22 0 -46" stroke="#F4F1E8" stroke-width="6.5" stroke-linecap="round" fill="none"/><path d="M-3 -9 h4.5 M-1 -20 h4 M-3.4 -31 h4.5 M-1 -40 h3.6" stroke="#4A4A4A" stroke-width="1.5" stroke-linecap="round"/><g class="sway"><ellipse cx="-9" cy="-46" rx="11" ry="13" fill="${d}"/><ellipse cx="9" cy="-44" rx="11" ry="13" fill="${d}"/><ellipse cx="0" cy="-58" rx="12" ry="14" fill="${m}"/><ellipse cx="-3" cy="-62" rx="6" ry="7" fill="${l}" opacity="0.8"/></g>''';
  }

  static String willow() =>
      '''${osh(4, 2, 26, 7)}<path d="M-5 0 q3 -18 -1 -36 h12 q-3 18 2 36 z" fill="#7A4E2B"/><g class="sway"><circle cx="0" cy="-46" r="24" fill="#6FAE5A"/><path d="M-24 -46 q-5 24 -2 42 M-15 -38 q-3 24 -1 38 M-6 -32 q-1 16 0 28 M24 -46 q5 24 2 42 M15 -38 q3 24 1 38 M6 -32 q1 16 0 28" stroke="#8CC870" stroke-width="5.5" stroke-linecap="round" fill="none"/><circle cx="-6" cy="-54" r="10" fill="#A9DC8E" opacity="0.8"/></g>''';
  static String cypress() =>
      '''${osh(2, 2, 11, 4)}<rect x="-2.5" y="-8" width="5" height="9" rx="2" fill="#7A4E2B"/><g class="sway"><ellipse cx="0" cy="-36" rx="9.5" ry="30" fill="#2F7D55"/><ellipse cx="-2.5" cy="-42" rx="4" ry="19" fill="#57A877" opacity="0.75"/></g>''';
  static String bush([dynamic pal, dynamic berry]) {
    final pp = (OPAL[pal ?? 'green'] ?? OPAL['green']!);
    final d = pp[0], m = pp[1], l = pp[2];
    return '''${osh(2, 1, 17, 5)}<circle cx="-8" cy="-8" r="9" fill="${d}"/><circle cx="8" cy="-8" r="9" fill="${d}"/><circle cx="0" cy="-13" r="10.5" fill="${m}"/><circle cx="-3" cy="-16" r="5" fill="${l}" opacity="0.7"/>${t(berry) ? '''<g fill="${berry}" stroke="rgba(0,0,0,0.18)" stroke-width="0.5"><circle cx="-9" cy="-7" r="2.4"/><circle cx="-2" cy="-10" r="2.4"/><circle cx="6" cy="-6" r="2.4"/><circle cx="3" cy="-15" r="2.2"/><circle cx="10" cy="-11" r="2.2"/></g>''' : ''}''';
  }

  static String sunflower() =>
      '''<path d="M0 0 v-30" stroke="#3F9B57" stroke-width="3" stroke-linecap="round"/><path d="M0 -11 q-9 -2 -11 -9 q9 0 11 9 M0 -17 q9 -2 11 -9 q-9 0 -11 9" fill="#57B866"/><circle cy="-35" r="9" fill="none" stroke="#FFC531" stroke-width="7" stroke-dasharray="4.2 2.87"/><circle cy="-35" r="6.2" fill="#7A4E2B"/><circle cx="-1.5" cy="-36.5" r="2.2" fill="#9A6B3F"/>''';
  static String vine([dynamic c]) =>
      '''<path d="M-13 0 v-27 M13 0 v-27" stroke="#A9773F" stroke-width="3" stroke-linecap="round"/><path d="M-15 -25 h30" stroke="#C9A36B" stroke-width="2"/><ellipse cx="0" cy="-25" rx="16" ry="8.5" fill="#57B866"/><ellipse cx="-6" cy="-28" rx="7" ry="4" fill="#8BD98A"/>${t(c) ? '''<g fill="${c}" stroke="rgba(0,0,0,0.18)" stroke-width="0.5"><circle cx="-6" cy="-16" r="2.7"/><circle cx="-3" cy="-13" r="2.7"/><circle cx="-8.5" cy="-12" r="2.7"/><circle cx="-5.5" cy="-8.5" r="2.5"/><circle cx="7" cy="-16" r="2.7"/><circle cx="5" cy="-12.5" r="2.7"/><circle cx="8.5" cy="-11.5" r="2.5"/></g>''' : ''}''';
  static String lav() =>
      '''<ellipse cx="0" cy="-5" rx="13" ry="6.5" fill="#6FA868"/><g stroke="#5E9A5A" stroke-width="1.5" stroke-linecap="round"><path d="M-8 -7 l-3 -9 M-3 -8 l-1 -11 M3 -8 l1 -11 M8 -7 l3 -9"/></g><g fill="#9B7FE0"><ellipse cx="-11.5" cy="-18" rx="2.3" ry="4.6" transform="rotate(-16 -11.5 -18)"/><ellipse cx="-4.2" cy="-21" rx="2.3" ry="5"/><ellipse cx="4.2" cy="-21" rx="2.3" ry="5"/><ellipse cx="11.5" cy="-18" rx="2.3" ry="4.6" transform="rotate(16 11.5 -18)"/></g>''';
  static String gmush([dynamic c]) =>
      '''${osh(2, 2, 20, 6)}<path d="M-6 0 q3 -16 -2 -28 h16 q-5 12 -2 28 z" fill="#FFF3DA" stroke="#D9C9A0" stroke-width="1.2"/><path d="M-27 -25 q27 -42 54 0 q-27 9 -54 0 z" fill="${c}" stroke="rgba(15,42,115,0.45)" stroke-width="1.6"/><g fill="#fff"><circle cx="-12" cy="-32" r="3.4"/><circle cx="4" cy="-40" r="4"/><circle cx="15" cy="-29" r="2.8"/><circle cx="-2" cy="-27" r="2"/></g>''';
  static String bamboo() =>
      '''${osh(1, 1, 12, 4)}<path d="M-7 0 v-52 M0 0 v-62 M7 0 v-47" stroke="#6DBE5A" stroke-width="4.4" stroke-linecap="round"/><path d="M-9.4 -17 h4.8 M-9.4 -35 h4.8 M-2.4 -21 h4.8 M-2.4 -42 h4.8 M4.6 -15 h4.8 M4.6 -31 h4.8" stroke="#3F9B57" stroke-width="1.6"/><g fill="#8BD98A" class="sway"><ellipse cx="-13" cy="-50" rx="7" ry="2.6" transform="rotate(-24 -13 -50)"/><ellipse cx="8" cy="-60" rx="7.5" ry="2.6" transform="rotate(20 8 -60)"/><ellipse cx="14" cy="-45" rx="7" ry="2.6" transform="rotate(26 14 -45)"/><ellipse cx="-7" cy="-62" rx="7" ry="2.6" transform="rotate(-30 -7 -62)"/></g>''';
  static String rock([dynamic snow]) =>
      '''${osh(2, 3, 11, 4)}<path d="M-10 2 q-1 -11 8 -12 q11 -1 12 9 q0 5 -9 5 z" fill="#C9CFD9"/><path d="M-6 -5 q5 -5 10 -2" stroke="${t(snow) ? '#fff' : '#EEF1F6'}" stroke-width="${t(snow) ? 4 : 2}" fill="none" stroke-linecap="round"/>''';
  static String menhir() =>
      '''${osh(3, 2, 13, 4.5)}<path d="M-9 0 q-3 -30 6 -36 q12 2 12 36 z" fill="#B9C1CE" stroke="#8892A4" stroke-width="1.4"/><path d="M-4 -28 q4 -4 8 0" stroke="#E4E9F1" stroke-width="2.4" fill="none" stroke-linecap="round"/><path d="M-5 -12 h7" stroke="#8892A4" stroke-width="1.2"/>''';
  static String young([dynamic v]) {
    final mound =
            '''<ellipse cx="0" cy="1" rx="11" ry="4" fill="#A9773F"/><ellipse cx="0" cy="0" rx="8" ry="2.6" fill="#C08B52"/>''',
        stake =
            '''<line x1="6" y1="0" x2="6" y2="-27" stroke="#D7B27A" stroke-width="2.4" stroke-linecap="round"/><path d="M0 -15 h6" stroke="#2F6BFF" stroke-width="1.6"/>''',
        trunk =
            '''<path d="M0 0 q-1.5 -13 0 -23" stroke="#8A5A34" stroke-width="3" fill="none" stroke-linecap="round"/>''';
    if (v == 0) {
      return '''${mound}${stake}${trunk}<circle cx="-5" cy="-27" r="8" fill="#57B866"/><circle cx="5" cy="-29" r="8" fill="#6CC978"/><circle cx="0" cy="-35" r="8" fill="#8BD98A"/>''';
    }
    if (v == 1) {
      return '''${mound}${trunk}<path d="M-10 -14 L0 -34 L10 -14 Z" fill="#2A8466"/><path d="M-7 -26 L0 -43 L7 -26 Z" fill="#3A9C78"/>''';
    }
    if (v == 2) {
      return '''${mound}${stake}${trunk}<circle cx="0" cy="-30" r="11" fill="#7CCB7C"/><circle cx="-5" cy="-33" r="6" fill="#A4E08A"/><g fill="#fff"><circle cx="-6" cy="-27" r="2"/><circle cx="5" cy="-33" r="2"/><circle cx="1" cy="-38" r="1.8"/><circle cx="7" cy="-25" r="1.6"/></g>''';
    }
    return '''${mound}<rect x="-4.5" y="-18" width="9" height="18" rx="3" fill="#DFF3FF" stroke="#7FA7C9" stroke-width="1.4" opacity="0.92"/><path d="M0 -17 v-6 M0 -21 q-6 -1 -7 -7 q6 0 7 7 M0 -21 q6 -1 7 -7 q-6 0 -7 7" fill="#6CC978" stroke="#3F9B57" stroke-width="1.2" stroke-linejoin="round"/>''';
  }

  static String sprout([dynamic x, dynamic y]) =>
      '''<path d="M${x} ${y} v-7 M${x} ${y - 6} q-7 -1 -8 -8 q7 0 8 8 M${x} ${y - 6} q7 -1 8 -8 q-7 0 -8 8" fill="#6CC978" stroke="#3F9B57" stroke-width="1.4" stroke-linejoin="round"/>''';
}

// small ground pieces, drawn at x,y
class OG {
  static String tuft([dynamic x, dynamic y]) =>
      '''<path d="M${x - 4} ${y} l-2 -7 M${x} ${y} v-9 M${x + 4} ${y} l2 -7" stroke="rgba(30,110,60,0.45)" stroke-width="1.8" stroke-linecap="round" fill="none"/>''';
  static String tuftw([dynamic x, dynamic y]) =>
      '''<path d="M${x - 4} ${y} l-2 -7 M${x} ${y} v-9 M${x + 4} ${y} l2 -7" stroke="rgba(90,130,160,0.5)" stroke-width="1.8" stroke-linecap="round" fill="none"/>''';
  static String fl([dynamic x, dynamic y, dynamic c]) =>
      '''<g><circle cx="${x - 3}" cy="${y}" r="2.6" fill="${c}"/><circle cx="${x + 3}" cy="${y}" r="2.6" fill="${c}"/><circle cx="${x}" cy="${y - 3}" r="2.6" fill="${c}"/><circle cx="${x}" cy="${y + 3}" r="2.6" fill="${c}"/><circle cx="${x}" cy="${y}" r="1.8" fill="#FFC531"/></g>''';
  static String wheat([dynamic x, dynamic y]) =>
      '''<g stroke="#B08A1E" stroke-width="1.8" stroke-linecap="round" fill="none"><path d="M${x - 5} ${y} q-2 -9 -5 -15 M${x} ${y} v-19 M${x + 5} ${y} q2 -9 5 -15"/></g><g fill="#E5B93A"><ellipse cx="${x - 10}" cy="${y - 17}" rx="2.2" ry="4.5" transform="rotate(-20 ${x - 10} ${y - 17})"/><ellipse cx="${x}" cy="${y - 21}" rx="2.2" ry="4.8"/><ellipse cx="${x + 10}" cy="${y - 17}" rx="2.2" ry="4.5" transform="rotate(20 ${x + 10} ${y - 17})"/></g>''';
  static String lav([dynamic x, dynamic y]) =>
      '''<g stroke="#5E9A5A" stroke-width="1.6" stroke-linecap="round"><path d="M${x - 5} ${y} l-3 -12 M${x} ${y} v-15 M${x + 5} ${y} l3 -12"/></g><g fill="#9B7FE0"><ellipse cx="${x - 8.5}" cy="${y - 14}" rx="2.4" ry="5" transform="rotate(-14 ${x - 8.5} ${y - 14})"/><ellipse cx="${x}" cy="${y - 18}" rx="2.4" ry="5.4"/><ellipse cx="${x + 8.5}" cy="${y - 14}" rx="2.4" ry="5" transform="rotate(14 ${x + 8.5} ${y - 14})"/></g>''';
  static String mush([dynamic x, dynamic y]) =>
      '''<g><rect x="${x - 2}" y="${y - 7}" width="4" height="8" rx="2" fill="#FFF7E2"/><path d="M${x - 8} ${y - 6} q8 -11 16 0 z" fill="#D9A766" stroke="#9A6B3F" stroke-width="1"/><circle cx="${x - 3}" cy="${y - 9}" r="1.2" fill="#FFF7E2"/><circle cx="${x + 3}" cy="${y - 8}" r="1" fill="#FFF7E2"/></g>''';
  static String peb([dynamic x, dynamic y]) =>
      '''<g fill="#D8DEE8" stroke="#AEB8C8" stroke-width="0.8"><ellipse cx="${x}" cy="${y}" rx="5" ry="3.2"/><ellipse cx="${x + 9}" cy="${y + 3}" rx="3.4" ry="2.4"/><ellipse cx="${x - 7}" cy="${y + 4}" rx="2.6" ry="1.9"/></g>''';
  static String leaf([dynamic x, dynamic y, dynamic c]) =>
      '''<path d="M${x - 5} ${y} q5 -7 10 0 q-5 5 -10 0 z M${x + 5} ${y} l3 1" fill="${c}" stroke="rgba(120,60,10,0.5)" stroke-width="0.8" transform="rotate(${(x * 7) % 90 - 45} ${x} ${y})"/>''';
  static String fern([dynamic x, dynamic y]) =>
      '''<g stroke="#2F8750" stroke-width="2" stroke-linecap="round" fill="none"><path d="M${x} ${y} q-9 -6 -13 -15 M${x} ${y} q0 -10 1 -18 M${x} ${y} q9 -6 13 -14"/></g><g stroke="#57B866" stroke-width="1.6" stroke-linecap="round"><path d="M${x - 6} ${y - 6} l-5 1 M${x - 9} ${y - 10} l-5 0 M${x + 1} ${y - 8} l-4 -2 M${x + 1} ${y - 13} l4 -2 M${x + 7} ${y - 6} l5 2 M${x + 10} ${y - 10} l4 0"/></g>''';
  static String petal([dynamic x, dynamic y]) =>
      '''<g fill="#FFD0E0"><ellipse cx="${x}" cy="${y}" rx="3" ry="1.8" transform="rotate(${(x * 11) % 180} ${x} ${y})"/><ellipse cx="${x + 7}" cy="${y + 3}" rx="2.6" ry="1.6" transform="rotate(${(x * 5) % 180} ${x + 7} ${y + 3})"/><ellipse cx="${x - 5}" cy="${y + 4}" rx="2.4" ry="1.5" fill="#fff"/></g>''';
  static String snowl([dynamic x, dynamic y]) =>
      '''<ellipse cx="${x}" cy="${y}" rx="11" ry="4.5" fill="#fff"/><ellipse cx="${x - 2}" cy="${y + 3}" rx="11" ry="3" fill="#CFE2F1" opacity="0.55"/>''';
  static String bell([dynamic x, dynamic y]) =>
      '''<path d="M${x} ${y} q-1 -9 4 -13" stroke="#3F9B57" stroke-width="1.6" fill="none" stroke-linecap="round"/><g fill="#6C8CFF"><ellipse cx="${x + 5}" cy="${y - 11}" rx="2.6" ry="3.4"/><ellipse cx="${x + 1}" cy="${y - 7}" rx="2.3" ry="3"/></g>''';
  static String reed([dynamic x, dynamic y]) =>
      '''<g stroke="#2F8750" stroke-width="2.2" stroke-linecap="round" fill="none"><path d="M${x} ${y} q-2 -12 -6 -18 M${x + 3} ${y} v-22 M${x + 6} ${y} q2 -10 7 -15"/></g><ellipse cx="${x + 3}" cy="${y - 24}" rx="2.6" ry="6" fill="#8A5A34"/>''';
}

// props: w is half the width, h the height, used so that nothing overlaps
final Map<String, OK> OPR = {
  'barrow': OK(
    26,
    30,
    false,
    ([dynamic _]) =>
        '''${osh(2, 3, 26, 6)}<path d="M-18 -22 h30 l-5 16 h-20 z" fill="#5B8CFF" stroke="#0F2A73" stroke-width="2" stroke-linejoin="round"/><path d="M-16 -22 q13 -12 26 0 z" fill="#8A5E36"/><path d="M12 -20 l16 -6 M9 -8 l12 4" stroke="#0F2A73" stroke-width="2.5" stroke-linecap="round"/><circle cx="-10" cy="-2" r="6" fill="#fff" stroke="#0F2A73" stroke-width="2.5"/>''',
  ),
  'can': OK(
    20,
    26,
    false,
    ([dynamic _]) =>
        '''${osh(2, 3, 22, 6)}<path d="M-14 -22 h24 l3 24 h-30 z" fill="#FFC531" stroke="#0F2A73" stroke-width="2"/><path d="M10 -14 l16 -10 l3 4 l-16 14" fill="#FFC531" stroke="#0F2A73" stroke-width="2" stroke-linejoin="round"/><path d="M-12 -22 q12 -16 22 0" fill="none" stroke="#0F2A73" stroke-width="2.5"/>''',
  ),
  'pots': OK(
    30,
    24,
    false,
    ([dynamic _]) =>
        '''${osh(0, 3, 32, 6)}${[-20, 0, 20].map((d) => '''<path d="M${d - 8} -14 h16 l-3 15 h-10 z" fill="#D98A52" stroke="#9A5A2E" stroke-width="1.5"/><rect x="${d - 9}" y="-17" width="18" height="5" rx="2" fill="#E59C64" stroke="#9A5A2E" stroke-width="1.5"/>${OS.sprout(d, -17)}''').join('')}''',
  ),
  'pumpkins': OK(
    24,
    18,
    false,
    ([dynamic _]) =>
        '''${osh(0, 3, 28, 6)}<path d="M-26 -3 q10 -12 22 -4 q10 6 24 -2" fill="none" stroke="#3F9B57" stroke-width="2.4" stroke-linecap="round"/><g stroke="#B96F1A" stroke-width="1.4"><ellipse cx="-12" cy="-7" rx="10" ry="8" fill="#F2A23A"/><path d="M-12 -15 v16 M-17 -13 q-3 6 0 13 M-7 -13 q3 6 0 13" fill="none"/><ellipse cx="10" cy="-5" rx="8" ry="6.5" fill="#F7B655"/><path d="M10 -11.5 v13" fill="none"/></g><path d="M-12 -15 q0 -5 4 -5 M10 -11 q0 -4 3 -4" stroke="#3F9B57" stroke-width="2.4" fill="none" stroke-linecap="round"/>''',
  ),
  'crate': OK(
    18,
    22,
    false,
    ([dynamic _]) =>
        '''${osh(0, 3, 22, 6)}<rect x="-16" y="-14" width="32" height="15" rx="2" fill="#C58B52" stroke="#6E4525" stroke-width="1.6"/><path d="M-16 -7 h32 M-6 -14 v15 M6 -14 v15" stroke="#6E4525" stroke-width="1.2"/>${[-10, 0, 10].map((d) => OS.sprout(d, -13)).join('')}''',
  ),
  'barrel': OK(
    14,
    30,
    false,
    ([dynamic _]) =>
        '''${osh(2, 3, 16, 5)}<rect x="-11" y="-26" width="22" height="27" rx="5" fill="#5B8CFF" stroke="#0F2A73" stroke-width="2"/><path d="M-11 -18 h22 M-11 -7 h22" stroke="#0F2A73" stroke-width="1.6"/><ellipse cx="0" cy="-26" rx="11" ry="3.5" fill="#8FD2FF" stroke="#0F2A73" stroke-width="2"/>''',
  ),
  'spade': OK(
    10,
    32,
    false,
    ([dynamic _]) =>
        '''<ellipse cx="0" cy="1" rx="12" ry="4" fill="#A9773F"/><path d="M0 -4 v-22" stroke="#8A5A34" stroke-width="3" stroke-linecap="round"/><path d="M-5 -30 h10" stroke="#8A5A34" stroke-width="3" stroke-linecap="round"/><path d="M-5 -4 h10 v6 q-5 5 -10 0 z" fill="#C9CFD9" stroke="#7E8798" stroke-width="1.4"/>''',
  ),
  'basket': OK(
    14,
    20,
    false,
    ([dynamic c]) =>
        '''${osh(0, 3, 16, 5)}<g fill="${t(c) ? c : '#FFD84A'}" stroke="rgba(0,0,0,0.15)" stroke-width="0.6"><ellipse cx="-5" cy="-13" rx="4.5" ry="3.6"/><ellipse cx="4" cy="-14" rx="4.5" ry="3.6"/><ellipse cx="0" cy="-17" rx="4.5" ry="3.6"/></g><path d="M-12 -12 h24 l-3 13 h-18 z" fill="#C99B5A" stroke="#8A5E36" stroke-width="1.5"/><path d="M-11 -7 h22 M-10 -2 h20" stroke="#8A5E36" stroke-width="1"/>''',
  ),
  'hive': OK(
    16,
    34,
    false,
    ([dynamic _]) =>
        '''${osh(2, 3, 18, 5)}<path d="M-9 0 v-6 M9 0 v-6" stroke="#8A5E36" stroke-width="3"/><rect x="-12" y="-17" width="24" height="12" rx="2" fill="#fff" stroke="#9AA4B5" stroke-width="1.5"/><rect x="-12" y="-28" width="24" height="12" rx="2" fill="#FFE38A" stroke="#C99B2A" stroke-width="1.5"/><path d="M-15 -28 h30 l-3 -5 h-24 z" fill="#C58B52" stroke="#6E4525" stroke-width="1.5"/><rect x="-4" y="-10" width="8" height="3" rx="1.5" fill="#6E4525"/><g class="bees"><circle cx="-18" cy="-30" r="1.8" fill="#FFC531" stroke="#3B2800" stroke-width="0.8"/><circle cx="16" cy="-38" r="1.8" fill="#FFC531" stroke="#3B2800" stroke-width="0.8"/><circle cx="4" cy="-44" r="1.8" fill="#FFC531" stroke="#3B2800" stroke-width="0.8"/></g>''',
  ),
  'scope': OK(
    40,
    30,
    false,
    ([dynamic _]) =>
        '''${osh(0, 3, 30, 6)}<path d="M-32 -4 v6 M12 -4 v6 M-28 -18 v14 M8 -18 v14" stroke="#6E4525" stroke-width="3" stroke-linecap="round"/><rect x="-35" y="-8" width="50" height="6" rx="2" fill="#C58B52" stroke="#6E4525" stroke-width="1.4"/><rect x="-35" y="-20" width="50" height="6" rx="2" fill="#D29A60" stroke="#6E4525" stroke-width="1.4"/><g transform="translate(28 0)"><path d="M0 -20 l-7 20 M0 -20 l7 20 M0 -20 v19" stroke="#0F2A73" stroke-width="2" stroke-linecap="round"/><g transform="rotate(-28 0 -22)"><rect x="-13" y="-26" width="24" height="8" rx="3" fill="#5B8CFF" stroke="#0F2A73" stroke-width="1.8"/><rect x="9" y="-27.5" width="6" height="11" rx="2" fill="#FFC531" stroke="#0F2A73" stroke-width="1.8"/></g></g>''',
  ),
  'menhirs': OK(
    30,
    42,
    false,
    ([dynamic _]) =>
        '''<g transform="translate(-18 -8) scale(1.1)">${OS.menhir()}</g><g transform="translate(4 -14) scale(1.25)">${OS.menhir()}</g><g transform="translate(20 0) scale(0.95)">${OS.menhir()}</g>''',
  ),
  'kite': OK(
    16,
    96,
    false,
    ([dynamic _]) =>
        '''<g class="kite" style="transform-origin:0px 0px"><path d="M0 0 q-14 -30 4 -62" fill="none" stroke="#fff" stroke-width="1.4"/><path d="M4 -92 l14 16 l-14 22 l-14 -22 z" fill="#2F6BFF" stroke="#0F2A73" stroke-width="2" stroke-linejoin="round"/><path d="M4 -92 v38 M-10 -76 h28" stroke="#0F2A73" stroke-width="1.4"/><path d="M4 -92 l14 16 l-14 0 z" fill="#FFC531" stroke="#0F2A73" stroke-width="1.4" stroke-linejoin="round"/><path d="M4 -54 q8 8 0 16 q-8 8 0 16" fill="none" stroke="#FFC531" stroke-width="2.4" stroke-linecap="round"/></g><path d="M-3 0 h6 v5 h-6 z" fill="#8A5A34"/>''',
  ),
  'log': OK(
    24,
    16,
    false,
    ([dynamic _]) =>
        '''${osh(0, 3, 24, 5)}<rect x="-20" y="-12" width="40" height="13" rx="6.5" fill="#9A6B3F" stroke="#6E4525" stroke-width="1.5"/><ellipse cx="20" cy="-5.5" rx="4" ry="6.5" fill="#E2B987" stroke="#6E4525" stroke-width="1.5"/><ellipse cx="20" cy="-5.5" rx="1.6" ry="2.8" fill="none" stroke="#B58150"/><path d="M-12 -12 q2 -6 6 -6" stroke="#57B866" stroke-width="2.4" fill="none" stroke-linecap="round"/>''',
  ),
  'stump': OK(
    14,
    16,
    false,
    ([dynamic _]) =>
        '''${osh(0, 2, 13, 4)}<path d="M-10 0 q2 -6 0 -12 h20 q-2 6 0 12 z" fill="#9A6B3F" stroke="#6E4525" stroke-width="1.5"/><ellipse cx="0" cy="-12" rx="10" ry="4" fill="#E2B987" stroke="#6E4525" stroke-width="1.5"/><ellipse cx="0" cy="-12" rx="5" ry="2" fill="none" stroke="#B58150"/>''',
  ),
  'lantern': OK(
    12,
    36,
    false,
    ([dynamic _]) =>
        '''${osh(0, 2, 8, 3)}<path d="M0 0 v-30" stroke="#0F2A73" stroke-width="3" stroke-linecap="round"/><path d="M0 -30 q8 -2 9 4" fill="none" stroke="#0F2A73" stroke-width="2.4"/><rect x="5" y="-27" width="9" height="12" rx="2" fill="#FFE38A" stroke="#0F2A73" stroke-width="1.8"/><circle class="twinkle" cx="9.5" cy="-21" r="2.4" fill="#fff"/>''',
  ),
  'hay': OK(
    20,
    22,
    false,
    ([dynamic _]) =>
        '''${osh(0, 3, 20, 5)}<rect x="-17" y="-20" width="34" height="21" rx="6" fill="#E9C45A" stroke="#B08A1E" stroke-width="1.6"/><path d="M-6 -20 v21 M6 -20 v21" stroke="#B08A1E" stroke-width="1.6"/><path d="M-14 -13 h5 M-2 -8 h5 M9 -14 h5" stroke="#F7E08A" stroke-width="1.6" stroke-linecap="round"/>''',
  ),
  'bath': OK(
    16,
    32,
    false,
    ([dynamic _]) =>
        '''${osh(0, 2, 12, 4)}<path d="M-3 0 q2 -10 0 -18 h6 q-2 8 0 18 z" fill="#D8DEE8" stroke="#8892A4" stroke-width="1.4"/><path d="M-14 -22 q14 10 28 0 z" fill="#D8DEE8" stroke="#8892A4" stroke-width="1.4"/><ellipse cx="0" cy="-22" rx="14" ry="3.5" fill="#8FD2FF" stroke="#8892A4" stroke-width="1.4"/><g transform="translate(8 -27)"><ellipse rx="5" ry="4" fill="#5B8CFF"/><circle cx="4" cy="-3" r="3" fill="#5B8CFF"/><path d="M7 -3 l4 1 l-4 1.5 z" fill="#F2A23A"/><circle cx="5" cy="-3.6" r="0.8" fill="#0F2A73"/></g>''',
  ),
  'sled': OK(
    22,
    14,
    false,
    ([dynamic _]) =>
        '''${osh(0, 2, 20, 4)}<path d="M-18 -2 h30 q6 0 6 -6" fill="none" stroke="#0F2A73" stroke-width="2.4" stroke-linecap="round"/><rect x="-16" y="-10" width="26" height="5" rx="2" fill="#E5484D" stroke="#0F2A73" stroke-width="1.6"/><path d="M-10 -5 v3 M4 -5 v3" stroke="#0F2A73" stroke-width="2"/>''',
  ),
  'toad': OK(
    18,
    16,
    false,
    ([dynamic _]) =>
        '''<rect x="-2" y="-9" width="5" height="10" rx="2.5" fill="#FFF7E2"/><path d="M-10 -8 q10 -14 21 0 z" fill="#E5484D" stroke="#9E2B2F" stroke-width="1.2"/><circle cx="-3" cy="-12" r="1.6" fill="#fff"/><circle cx="4" cy="-11" r="1.3" fill="#fff"/><rect x="10" y="-5" width="3.4" height="6" rx="1.7" fill="#FFF7E2"/><path d="M6 -4 q5.5 -8 11 0 z" fill="#E5484D" stroke="#9E2B2F" stroke-width="1.2"/>''',
  ),
  'picnic': OK(
    26,
    22,
    false,
    ([dynamic _]) =>
        '''<path d="M-22 -6 l34 -6 l12 12 l-34 7 z" fill="#fff" stroke="#E5484D" stroke-width="2" stroke-linejoin="round"/><path d="M-10 -8.5 l12 12.5 M2 -10.5 l12 12 M-16 0 l34 -6.5" stroke="#E5484D" stroke-width="1.6"/><path d="M-4 -16 h14 l-2 9 h-10 z" fill="#C99B5A" stroke="#8A5E36" stroke-width="1.4"/><path d="M-3 -16 q6 -9 12 0" fill="none" stroke="#8A5E36" stroke-width="1.6"/>''',
  ),
  'snowman': OK(
    16,
    48,
    false,
    ([dynamic _]) =>
        '''${osh(0, 2, 14, 4)}<g fill="#fff" stroke="#C9D8E8" stroke-width="1.4"><circle cy="-9" r="10"/><circle cy="-24" r="7.5"/><circle cy="-35" r="5.5"/></g><path d="M0 -35 l8 2 l-8 1.5 z" fill="#F2A23A"/><circle cx="-2" cy="-37" r="0.9" fill="#0F2A73"/><circle cx="2.5" cy="-37" r="0.9" fill="#0F2A73"/><path d="M-6 -29.5 q6 4 12 0" stroke="#E5484D" stroke-width="3" fill="none" stroke-linecap="round"/><path d="M-7 -40 h14 M-4.5 -40 v-7 h9 v7 z" stroke="#0F2A73" stroke-width="2" fill="#0F2A73" stroke-linejoin="round"/><path d="M-7 -24 l-9 -6 M7 -24 l9 -6" stroke="#8A5A34" stroke-width="1.8" stroke-linecap="round"/>''',
  ),
  'scare': OK(
    18,
    54,
    false,
    ([dynamic _]) =>
        '''${osh(0, 2, 12, 4)}<path d="M0 0 v-40 M-16 -28 h32" stroke="#8A5A34" stroke-width="3.4" stroke-linecap="round"/><path d="M-12 -30 h24 l-3 16 h-18 z" fill="#5B8CFF" stroke="#0F2A73" stroke-width="1.6" stroke-linejoin="round"/><circle cy="-38" r="7" fill="#F7DC9A" stroke="#B08A1E" stroke-width="1.4"/><path d="M-10 -43 h20 l-4 -3 l-3 -8 h-6 l-3 8 z" fill="#C58B52" stroke="#6E4525" stroke-width="1.4" stroke-linejoin="round"/><circle cx="-2.5" cy="-38" r="1" fill="#3B2410"/><circle cx="2.5" cy="-38" r="1" fill="#3B2410"/><path d="M-2.5 -35 q2.5 2 5 0" stroke="#3B2410" stroke-width="1" fill="none"/><path d="M-16 -28 l-3 4 M-16 -28 l-4 0 M16 -28 l3 4 M16 -28 l4 0" stroke="#E5B93A" stroke-width="1.6" stroke-linecap="round"/>''',
  ),
  'bunny': OK(
    12,
    22,
    false,
    ([dynamic _]) =>
        '''${osh(0, 2, 9, 3)}<g class="bob"><ellipse cx="0" cy="-6" rx="8" ry="6.5" fill="#fff" stroke="#C9D2E0" stroke-width="1.2"/><path d="M4 -16 q-2 -9 1 -10 q3 1 1 10 M8 -16 q1 -9 4 -9 q2 2 -1 10" fill="#fff" stroke="#C9D2E0" stroke-width="1.2"/><circle cx="6" cy="-12" r="5" fill="#fff" stroke="#C9D2E0" stroke-width="1.2"/><circle cx="8" cy="-12.5" r="1" fill="#0F2A73"/><circle cx="-8" cy="-5" r="2.6" fill="#fff" stroke="#C9D2E0" stroke-width="1"/></g>''',
  ),
  'hog': OK(
    14,
    14,
    false,
    ([dynamic _]) =>
        '''${osh(0, 2, 10, 3)}<path d="M-10 0 q-2 -12 8 -13 q10 0 11 8 l5 3 q-1 3 -6 2 z" fill="#9A6B3F" stroke="#6E4525" stroke-width="1.2" stroke-linejoin="round"/><path d="M-7 -8 l-3 -4 M-3 -11 l-2 -5 M2 -12 l0 -5 M6 -10 l3 -4" stroke="#6E4525" stroke-width="1.6" stroke-linecap="round"/><circle cx="10" cy="-4" r="1" fill="#0F2A73"/><circle cx="14.5" cy="-2" r="1.2" fill="#3B2410"/>''',
  ),
  'robin': OK(
    10,
    32,
    false,
    ([dynamic _]) =>
        '''<path d="M0 0 v-20" stroke="#8A5A34" stroke-width="4" stroke-linecap="round"/><g class="bob"><g transform="translate(0 -25)"><ellipse rx="6.5" ry="5.5" fill="#8A6A4A"/><ellipse cx="2" cy="1.5" rx="4" ry="3.6" fill="#F26B3A"/><circle cx="5" cy="-4" r="3.6" fill="#8A6A4A"/><path d="M8 -4 l4 1 l-4 1.6 z" fill="#F2A23A"/><circle cx="6" cy="-4.6" r="0.9" fill="#0F2A73"/></g></g>''',
  ),
};
// landmarks: one big thing per land. w half width, h height (before scaling to fit its spot)
final Map<String, OK> OLM = {
  'oak': OK(
    62,
    150,
    false,
    ([dynamic _]) =>
        '''${osh(6, 4, 64, 16)}<path d="M-16 4 q8 -20 4 -52 h24 q-4 32 6 52 q-8 -6 -14 -2 q-6 -5 -20 2 z" fill="#7A4E2B"/><path d="M-4 -10 q3 -18 0 -36" stroke="#9A6B3F" stroke-width="4" fill="none" stroke-linecap="round"/><ellipse cx="2" cy="-26" rx="4" ry="5.5" fill="#4E2F17"/><g class="swing" style="transform-origin:40px -64px"><path d="M33 -64 v46 M47 -64 v46" stroke="#E9DDAE" stroke-width="1.8"/><rect x="30" y="-20" width="20" height="5" rx="2" fill="#C58B52" stroke="#6E4525" stroke-width="1.2"/></g><g class="sway"><circle cx="-36" cy="-62" r="30" fill="#2F8750"/><circle cx="38" cy="-60" r="30" fill="#2F8750"/><circle cx="0" cy="-52" r="30" fill="#3A9658"/><circle cx="-18" cy="-92" r="32" fill="#46A85F"/><circle cx="22" cy="-94" r="30" fill="#46A85F"/><circle cx="0" cy="-112" r="26" fill="#62BD6F"/><circle cx="-12" cy="-118" r="12" fill="#8BD98A" opacity="0.8"/></g>''',
  ),
  'twisty': OK(
    60,
    170,
    false,
    ([dynamic _]) =>
        '''<ellipse cx="6" cy="5" rx="58" ry="15" fill="rgba(60,80,20,0.25)"/><path d="M-12 4 c20 -22 -26 -38 -2 -62 c22 -22 -16 -36 6 -62" stroke="#7A4E2B" stroke-width="20" fill="none" stroke-linecap="round"/><path d="M-12 2 c20 -22 -26 -38 -2 -62 c22 -22 -16 -36 6 -60" stroke="#A9713F" stroke-width="6" fill="none" stroke-linecap="round" stroke-dasharray="16 12"/><path d="M-10 -66 q-26 -10 -40 -34 M-2 -96 q26 -8 40 -30" stroke="#7A4E2B" stroke-width="9" fill="none" stroke-linecap="round"/><g class="sway"><circle cx="-52" cy="-104" r="24" fill="#8FAE3E"/><circle cx="42" cy="-130" r="26" fill="#8FAE3E"/><circle cx="-6" cy="-140" r="32" fill="#B5CC52"/><circle cx="-34" cy="-126" r="20" fill="#B5CC52"/><circle cx="18" cy="-152" r="20" fill="#DDE88A"/><circle cx="-14" cy="-156" r="10" fill="#F4F7B8" opacity="0.9"/></g>''',
  ),
  'glasshouse': OK(
    42,
    68,
    false,
    ([dynamic _]) =>
        '''${osh(4, 3, 44, 10)}<rect x="-34" y="-36" width="68" height="36" fill="#DFF3FF" stroke="#7FA7C9" stroke-width="2.5"/><path d="M-40 -36 L0 -66 L40 -36 Z" fill="#EEFAFF" stroke="#7FA7C9" stroke-width="2.5" stroke-linejoin="round"/><path d="M-17 -36 v36 M17 -36 v36 M-34 -18 h68 M-20 -51 h40 M0 -66 v30" stroke="#7FA7C9" stroke-width="1.6"/><g fill="#57B866"><circle cx="-25" cy="-8" r="6"/><circle cx="25" cy="-9" r="7"/><circle cx="-26" cy="-26" r="4"/><circle cx="26" cy="-27" r="4"/></g><rect x="-9" y="-26" width="18" height="26" rx="2" fill="#BFE6FA" stroke="#7FA7C9" stroke-width="2"/><circle cx="5" cy="-12" r="1.6" fill="#0F2A73"/>''',
  ),
  'windmill': OK(
    46,
    140,
    false,
    ([dynamic _]) =>
        '''${osh(4, 4, 40, 10)}<path d="M-22 0 l8 -88 h28 l8 88 z" fill="#FFF3DA" stroke="#0F2A73" stroke-width="2.5" stroke-linejoin="round"/><path d="M-17 -88 q17 -24 34 0 z" fill="#E5484D" stroke="#0F2A73" stroke-width="2.5" stroke-linejoin="round"/><rect x="-8" y="-22" width="16" height="22" rx="8" fill="#8A5A34" stroke="#0F2A73" stroke-width="2"/><rect x="-6" y="-60" width="12" height="14" rx="3" fill="#8FD2FF" stroke="#0F2A73" stroke-width="2"/><g class="spin" style="transform-origin:0px -94px">${[0, 90, 180, 270].map((a) => '''<g transform="rotate(${a} 0 -94)"><path d="M0 -94 v-46" stroke="#6E4525" stroke-width="3" stroke-linecap="round"/><rect x="1" y="-140" width="13" height="34" rx="2" fill="#fff" stroke="#0F2A73" stroke-width="1.8"/><path d="M1 -129 h13 M1 -118 h13" stroke="#0F2A73" stroke-width="1"/></g>''').join('')}<circle cy="-94" r="5" fill="#FFC531" stroke="#0F2A73" stroke-width="2"/></g>''',
  ),
  'cottage': OK(
    46,
    84,
    false,
    ([dynamic _]) =>
        '''${osh(4, 4, 50, 11)}<rect x="15" y="-74" width="12" height="24" fill="#C9CFD9" stroke="#0F2A73" stroke-width="2"/><rect x="-34" y="-40" width="68" height="40" rx="3" fill="#FFF3DA" stroke="#0F2A73" stroke-width="2.5"/><path d="M-44 -38 L0 -76 L44 -38 Z" fill="#E5484D" stroke="#0F2A73" stroke-width="2.5" stroke-linejoin="round"/><rect x="-8" y="-24" width="16" height="24" rx="8" fill="#5B8CFF" stroke="#0F2A73" stroke-width="2"/><circle cx="4" cy="-11" r="1.5" fill="#FFC531"/><rect x="-27" y="-29" width="13" height="13" rx="2" fill="#8FD2FF" stroke="#0F2A73" stroke-width="2"/><rect x="14" y="-29" width="13" height="13" rx="2" fill="#8FD2FF" stroke="#0F2A73" stroke-width="2"/><path d="M-29 -14 h17 M12 -14 h17" stroke="#57B866" stroke-width="4" stroke-linecap="round"/><g fill="#FFB3D1"><circle cx="-25" cy="-16" r="2"/><circle cx="-17" cy="-16" r="2"/><circle cx="17" cy="-16" r="2"/><circle cx="25" cy="-16" r="2"/></g><g class="bob" fill="#fff"><circle cx="22" cy="-82" r="4" opacity="0.75"/><circle cx="27" cy="-92" r="5.5" opacity="0.5"/></g>''',
  ),
  'cabin': OK(
    46,
    68,
    false,
    ([dynamic snow]) =>
        '''${osh(4, 4, 50, 11)}<rect x="-36" y="-36" width="72" height="36" rx="3" fill="#B07A45" stroke="#6E4525" stroke-width="2.5"/><path d="M-36 -27 h72 M-36 -18 h72 M-36 -9 h72" stroke="#6E4525" stroke-width="1.6"/><path d="M-44 -34 L0 -66 L44 -34 Z" fill="${t(snow) ? '#fff' : '#3A9C78'}" stroke="#0F2A73" stroke-width="2.5" stroke-linejoin="round"/><rect x="-8" y="-24" width="16" height="24" rx="2" fill="#6E4525" stroke="#3B2410" stroke-width="2"/><circle cx="4" cy="-11" r="1.5" fill="#FFC531"/><rect x="14" y="-27" width="14" height="13" rx="2" fill="#FFE38A" stroke="#3B2410" stroke-width="2"/><path d="M21 -27 v13 M14 -20.5 h14" stroke="#3B2410" stroke-width="1.2"/><g fill="#E2B987" stroke="#6E4525" stroke-width="1.3"><circle cx="-29" cy="-5" r="5"/><circle cx="-20" cy="-5" r="5"/><circle cx="-24.5" cy="-13" r="5"/></g>''',
  ),
  'well': OK(
    24,
    54,
    false,
    ([dynamic _]) =>
        '''${osh(2, 3, 24, 6)}<path d="M-18 0 v-16 h36 v16 z" fill="#C9CFD9" stroke="#8892A4" stroke-width="2" stroke-linejoin="round"/><path d="M-18 -8 h36 M-6 -16 v8 M8 -8 v8 M-12 -8 v8" stroke="#8892A4" stroke-width="1.2"/><path d="M-14 -16 v-24 M14 -16 v-24" stroke="#8A5A34" stroke-width="3.4"/><path d="M-22 -38 L0 -52 L22 -38 Z" fill="#E5484D" stroke="#0F2A73" stroke-width="2.2" stroke-linejoin="round"/><path d="M0 -40 v14" stroke="#6E4525" stroke-width="1.4"/><path d="M-5 -26 h10 l-1.5 8 h-7 z" fill="#C58B52" stroke="#6E4525" stroke-width="1.4"/>''',
  ),
  'treehouse': OK(
    62,
    150,
    false,
    ([dynamic _]) =>
        '''${osh(6, 4, 58, 14)}<path d="M-13 4 q7 -30 2 -80 h22 q-4 48 6 80 q-9 -5 -15 -2 q-7 -4 -15 2 z" fill="#7A4E2B"/><path d="M-24 0 l10 -60 M-12 0 l10 -60" stroke="#C58B52" stroke-width="2.6" stroke-linecap="round"/><path d="M-21 -12 h11 M-19 -24 h11 M-17 -36 h11 M-15 -48 h11" stroke="#A9713F" stroke-width="2.4"/><g class="sway"><circle cx="-36" cy="-96" r="28" fill="#2F8750"/><circle cx="38" cy="-94" r="28" fill="#2F8750"/><circle cx="0" cy="-118" r="34" fill="#46A85F"/><circle cx="-14" cy="-130" r="13" fill="#8BD98A" opacity="0.8"/></g><rect x="-22" y="-86" width="44" height="26" rx="2" fill="#F3D9AE" stroke="#0F2A73" stroke-width="2.2"/><path d="M-28 -84 L0 -106 L28 -84 Z" fill="#E5484D" stroke="#0F2A73" stroke-width="2.2" stroke-linejoin="round"/><rect x="-5.5" y="-79" width="11" height="12" rx="5.5" fill="#FFE38A" stroke="#0F2A73" stroke-width="2"/><path d="M-27 -60 h54" stroke="#6E4525" stroke-width="4" stroke-linecap="round"/>''',
  ),
  'gazebo': OK(
    42,
    84,
    false,
    ([dynamic _]) =>
        '''${osh(0, 4, 44, 10)}<path d="M-36 0 h72 l-6 -8 h-60 z" fill="#E9DDAE" stroke="#0F2A73" stroke-width="2" stroke-linejoin="round"/><path d="M-28 -8 v-40 M28 -8 v-40 M-10 -8 v-40 M10 -8 v-40" stroke="#0F2A73" stroke-width="7.5" stroke-linecap="round"/><path d="M-28 -8 v-40 M28 -8 v-40 M-10 -8 v-40 M10 -8 v-40" stroke="#fff" stroke-width="4.5" stroke-linecap="round"/><path d="M-28 -22 h56" stroke="#fff" stroke-width="3"/><path d="M-42 -46 Q0 -94 42 -46 Z" fill="#5B8CFF" stroke="#0F2A73" stroke-width="2.5" stroke-linejoin="round"/><path d="M-14 -62 Q0 -76 14 -62" fill="none" stroke="#8FB0FF" stroke-width="3" stroke-linecap="round"/><circle cy="-75" r="4.5" fill="#FFC531" stroke="#0F2A73" stroke-width="2"/>''',
  ),
  'balloon': OK(
    32,
    120,
    false,
    ([dynamic _]) =>
        '''${osh(0, 3, 16, 4)}<path d="M-8 -14 l-10 -42 M8 -14 l10 -42 M0 -14 v-40" stroke="#6E4525" stroke-width="1.2"/><rect x="-9" y="-14" width="18" height="14" rx="3" fill="#C99B5A" stroke="#6E4525" stroke-width="1.8"/><path d="M-9 -8 h18" stroke="#6E4525" stroke-width="1.2"/><path d="M-30 -86 a30 32 0 1 1 60 0 q-6 22 -18 32 h-24 q-12 -10 -18 -32 z" fill="#E5484D" stroke="#0F2A73" stroke-width="2.5" stroke-linejoin="round"/><path d="M-13 -114 q-9 30 1 60 M13 -114 q9 30 -1 60" fill="none" stroke="#FFC531" stroke-width="7"/><path d="M0 -117 v63" stroke="#fff" stroke-width="7"/><path d="M-30 -86 a30 32 0 1 1 60 0 q-6 22 -18 32 h-24 q-12 -10 -18 -32 z" fill="none" stroke="#0F2A73" stroke-width="2.5" stroke-linejoin="round"/>''',
  ),
  'pond': OK(
    62,
    46,
    true,
    ([dynamic _]) =>
        '''<ellipse cx="0" cy="-20" rx="60" ry="24" fill="#E9DDAE"/><ellipse cx="0" cy="-20" rx="54" ry="20" fill="#5FB4F0"/><ellipse cx="-4" cy="-22" rx="40" ry="13" fill="#8FD2FF"/><path class="shimmer" d="M-34 -24 h60" stroke="#fff" stroke-width="2.4" stroke-dasharray="10 30" stroke-linecap="round" opacity="0.8"/><g transform="translate(-24 -16)"><path d="M0 0 L8 -3 A8.5 6 0 1 0 8 3 Z" fill="#4FAE6A" stroke="#2F8750" stroke-width="1"/><g transform="translate(-1 -3)"><ellipse rx="5.5" ry="3.6" fill="#7CD67C" stroke="#2F8750" stroke-width="0.9"/><circle cx="-2.6" cy="-3.4" r="2" fill="#7CD67C" stroke="#2F8750" stroke-width="0.8"/><circle cx="2.6" cy="-3.4" r="2" fill="#7CD67C" stroke="#2F8750" stroke-width="0.8"/><circle cx="-2.6" cy="-3.6" r="0.8" fill="#0F2A73"/><circle cx="2.6" cy="-3.6" r="0.8" fill="#0F2A73"/></g></g><g transform="translate(6 -30)"><path d="M0 0 L7 -2.5 A7.5 5 0 1 0 7 2.5 Z" fill="#4FAE6A" stroke="#2F8750" stroke-width="1"/><circle cx="-2" cy="-1" r="2.4" fill="#fff"/><circle cx="-2" cy="-1" r="1" fill="#FFC531"/></g><rect x="22" y="-14" width="30" height="9" rx="2" fill="#C58B52" stroke="#6E4525" stroke-width="1.4"/><path d="M31 -14 v9 M41 -14 v9 M26 -5 v6 M48 -5 v6" stroke="#6E4525" stroke-width="1.4"/>''',
  ),
  'cart': OK(
    40,
    64,
    false,
    ([dynamic c]) =>
        '''${osh(2, 3, 40, 8)}<path d="M-30 -30 v-22 M24 -30 v-22" stroke="#6E4525" stroke-width="2.4"/><path d="M-36 -52 h66 l-4 -10 h-58 z" fill="#fff" stroke="#0F2A73" stroke-width="2" stroke-linejoin="round"/><path d="M-24 -61 l-3 8 M-10 -61 l-1 8 M4 -61 l1 8 M18 -61 l3 8" stroke="#E5484D" stroke-width="6"/><g fill="${t(c) ? c : '#FFD84A'}" stroke="rgba(0,0,0,0.16)" stroke-width="0.6">${[-22, -11, 0, 11].map((d) => '''<circle cx="${d}" cy="-33" r="5.5"/>''').join('')}<circle cx="-16" cy="-40" r="5.5"/><circle cx="-5" cy="-40" r="5.5"/><circle cx="6" cy="-40" r="5.5"/></g><path d="M-30 -30 h54 l-4 18 h-46 z" fill="#C58B52" stroke="#6E4525" stroke-width="2" stroke-linejoin="round"/><path d="M24 -24 l16 -8 M20 -14 l10 14" stroke="#6E4525" stroke-width="2.6" stroke-linecap="round"/><circle cx="-14" cy="-8" r="9" fill="#fff" stroke="#0F2A73" stroke-width="2.5"/><circle cx="-14" cy="-8" r="2" fill="#0F2A73"/>''',
  ),
  'camp': OK(
    46,
    44,
    false,
    ([dynamic _]) =>
        '''${osh(0, 3, 46, 9)}<path d="M-40 0 L-14 -42 L12 0 Z" fill="#FFC531" stroke="#0F2A73" stroke-width="2.5" stroke-linejoin="round"/><path d="M-14 -42 L-19 0 L-6 0 Z" fill="#0F2A73"/><path d="M-14 -42 l-4 -6 M-14 -42 l4 -6" stroke="#0F2A73" stroke-width="2" stroke-linecap="round"/><path d="M22 -2 l16 -5 M22 -7 l16 5" stroke="#8A5A34" stroke-width="3.4" stroke-linecap="round"/><path class="twinkle" d="M30 -6 q-8 -9 0 -20 q2 6 5 8 q3 6 -5 12 z" fill="#F7941D"/><path d="M30 -7 q-3 -5 0 -9 q3 4 0 9 z" fill="#FFE38A"/>''',
  ),
  'fountain': OK(
    34,
    50,
    false,
    ([dynamic _]) =>
        '''${osh(0, 3, 36, 8)}<ellipse cx="0" cy="-4" rx="32" ry="10" fill="#C9CFD9" stroke="#8892A4" stroke-width="2"/><ellipse cx="0" cy="-6" rx="26" ry="7" fill="#8FD2FF"/><path d="M-4 -6 q2 -14 0 -26 h8 q-2 12 0 26 z" fill="#D8DEE8" stroke="#8892A4" stroke-width="1.6"/><ellipse cx="0" cy="-32" rx="14" ry="4" fill="#C9CFD9" stroke="#8892A4" stroke-width="1.6"/><path class="shimmer" d="M0 -34 v-12 M0 -46 q-10 2 -12 14 M0 -46 q10 2 12 14" stroke="#DFF3FF" stroke-width="2.4" fill="none" stroke-linecap="round" stroke-dasharray="4 4"/>''',
  ),
  'ring': OK(
    50,
    76,
    false,
    ([dynamic _]) =>
        ([
              [-36, -8, 1.1],
              [-20, -32, 1.3],
              [12, -36, 1.2],
              [38, -12, 1],
              [26, 10, 0.9],
              [-24, 14, 1],
            ]..sort((a, b) => a[1].compareTo(b[1])))
            .map(
              (e) =>
                  '''<g transform="translate(${e[0]} ${e[1] - 12}) scale(${e[2]})">${OS.menhir()}</g>''',
            )
            .join(''),
  ),
  'igloo': OK(
    38,
    34,
    false,
    ([dynamic _]) =>
        '''${osh(0, 3, 40, 8)}<path d="M-34 0 a34 30 0 0 1 68 0 z" fill="#fff" stroke="#9CC3E0" stroke-width="2.2" stroke-linejoin="round"/><path d="M-30 -14 h60 M-20 -25 h40 M-12 0 v-14 M12 0 v-14 M0 -14 v-11 M-22 -14 v14 M22 -14 v14" stroke="#B9D8EE" stroke-width="1.4"/><path d="M-9 0 a9 11 0 0 1 18 0 z" fill="#0F2A73"/>''',
  ),
  'barn': OK(
    44,
    64,
    false,
    ([dynamic _]) =>
        '''${osh(4, 4, 50, 11)}<path d="M-36 0 v-40 l14 -18 h44 l14 18 v40 z" fill="#D9453F" stroke="#0F2A73" stroke-width="2.5" stroke-linejoin="round"/><path d="M-39 -39 l16 -21 h46 l16 21" fill="none" stroke="#fff" stroke-width="4" stroke-linejoin="round" stroke-linecap="round"/><rect x="-12" y="-26" width="24" height="26" fill="#fff" stroke="#0F2A73" stroke-width="2"/><path d="M-12 -26 l24 26 M12 -26 l-24 26" stroke="#D9453F" stroke-width="2"/><circle cy="-44" r="5" fill="#0F2A73"/>''',
  ),
  'scarebarn': OK(44, 64, false, ([dynamic _]) => OLM['barn']!.f()),
  'bigwillow': OK(28, 72, false, ([dynamic _]) => OS.willow()),
};
