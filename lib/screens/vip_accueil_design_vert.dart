import 'package:flutter/material.dart';

// ══════════════════════════════════════════════════════════════════════════════
// DESIGN 1 — ÉMERAUDE IMPÉRIAL
// Palette : vert émeraude + or antique sur fond forêt noire
// Remplace le contenu de _buildAccueilVip() dans home.dart
// ══════════════════════════════════════════════════════════════════════════════

const Color _bg = Color(0xFF050E08); // forêt noire
const Color _card = Color(0xFF0A1E10); // jade profond
const Color _em = Color(0xFF00D87E); // émeraude brillant
const Color _emDim = Color(0xFF3FA86A); // émeraude atténué
const Color _gold = Color(0xFFC8A227); // or antique
const Color _border = Color(0xFF134827); // bordure jade
const Color _white = Colors.white;

const List<Map<String, String>> _kRoutes = [
  {'depart': 'Ferké', 'destination': 'Abidjan'},
  {'depart': 'Ferké', 'destination': 'Bouaké'},
  {'depart': 'Bouaké', 'destination': 'Ferké'},
  {'depart': 'Bouaké', 'destination': 'Abidjan'},
  {'depart': 'Abidjan', 'destination': 'Ferké'},
  {'depart': 'Abidjan', 'destination': 'Bouaké'},
];

Map<String, List<String>> _group(List<Map<String, String>> routes) {
  final Map<String, List<String>> g = {};
  for (final r in routes) {
    g.putIfAbsent(r['depart']!, () => []).add(r['destination']!);
  }
  return g;
}

// ── Widget principal (drop-in pour l'onglet VIP) ──────────────────────────────
class VipAccueilVert extends StatelessWidget {
  /// [onReserver] est appelé avec (depart, destination) quand on tape "Réserver"
  const VipAccueilVert({super.key, this.onReserver});
  final void Function(String depart, String destination)? onReserver;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final grouped = _group(_kRoutes);

    return Container(
      //color: _bg,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _HeroBand(w: w),
          _SectionHeader(w: w),
          ...grouped.entries.map(
            (e) => _OriginGroup(
              depart: e.key,
              destinations: e.value,
              onReserver: onReserver,
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Hero ──────────────────────────────────────────────────────────────────────
class _HeroBand extends StatelessWidget {
  final double w;
  const _HeroBand({required this.w});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(22, 30, 22, w * 0.07),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF091A0E), Color(0xFF0F2E18), Color(0xFF061009)],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: _em.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: _em.withValues(alpha: 0.30),
                width: 0.9,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.airline_seat_recline_extra,
                  color: _em,
                  size: 13,
                ),
                const SizedBox(width: 7),
                Text(
                  'MVST VIP — Voyage Premium',
                  style: TextStyle(
                    color: _em,
                    fontWeight: FontWeight.w700,
                    fontSize: w * 0.029,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: w * 0.025),

          // Titre
          Text(
            'Voyagez en\npremière classe',
            style: TextStyle(
              color: _white,
              fontWeight: FontWeight.w900,
              fontSize: w * 0.057,
              height: 1.15,
              letterSpacing: -0.8,
            ),
          ),
          SizedBox(height: w * 0.02),

          // Ligne or décorative
          Row(
            children: [
              Container(
                width: 32,
                height: 2,
                decoration: BoxDecoration(
                  color: _gold,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 10,
                height: 2,
                decoration: BoxDecoration(
                  color: _gold.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ],
          ),
          SizedBox(height: w * 0.04),

          // Pills
          Row(
            children: [
              Wrap(
                spacing: 2,
                // runSpacing: 6,
                children: [
                  '★ Grand confort',
                  '🌿 Éco Premium',
                  '🎫 QR instantané',
                ].map((label) => _Pill(label: label)).toList(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  const _Pill({required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Color.fromARGB(255, 1, 154, 90).withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: _em.withValues(alpha: 0.28), width: 0.8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: _em,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ── Titre section ─────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final double w;
  const _SectionHeader({required this.w});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 20,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_em, _gold],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Lignes Classe VIP',
                style: TextStyle(
                  // color: _white,
                  fontWeight: FontWeight.w800,
                  fontSize: w * 0.044,
                  letterSpacing: -0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.only(left: 13),
            child: Text(
              'Sièges spacieux · Confort absolu · Départ garanti',
              style: TextStyle(
                color: Colors.grey[800],
                //color: _emDim.withValues(alpha: 0.75),
                fontSize: w * 0.030,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Groupe par ville de départ ────────────────────────────────────────────────
class _OriginGroup extends StatelessWidget {
  final String depart;
  final List<String> destinations;
  final void Function(String, String)? onReserver;

  const _OriginGroup({
    required this.depart,
    required this.destinations,
    this.onReserver,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label ville
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: _em,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  depart == 'Abidjan'
                      ? "A partir d'${depart.toUpperCase()}"
                      : "A partir de ${depart.toUpperCase()}",
                  style: const TextStyle(
                    color: Color.fromARGB(255, 1, 154, 90),
                    fontWeight: FontWeight.w800,
                    fontSize: 10.5,
                    letterSpacing: 1.8,
                  ),
                ),
              ],
            ),
          ),

          // Carte regroupant les lignes
          Container(
            decoration: BoxDecoration(
              //color: _card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Color.fromARGB(255, 1, 154, 90),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Column(
                children: List.generate(destinations.length, (i) {
                  final isLast = i == destinations.length - 1;
                  return Column(
                    children: [
                      _RouteRow(
                        depart: depart,
                        destination: destinations[i],
                        onTap: () => onReserver?.call(depart, destinations[i]),
                      ),
                      if (!isLast)
                        Divider(
                          height: 0.7,
                          thickness: 1,
                          color: Color.fromARGB(255, 1, 191, 112),
                          indent: 60,
                          endIndent: 16,
                        ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Ligne de route ────────────────────────────────────────────────────────────
class _RouteRow extends StatelessWidget {
  final String depart;
  final String destination;
  final VoidCallback? onTap;

  const _RouteRow({
    required this.depart,
    required this.destination,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            // Icône
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _em.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.airline_seat_recline_extra,
                color: Color.fromARGB(255, 1, 154, 90),
                size: 19,
              ),
            ),
            const SizedBox(width: 14),

            // Texte trajet
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$depart → $destination',
                    style: const TextStyle(
                      // color: _white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Ligne $depart $destination',
                    style: TextStyle(
                      color: _white.withValues(alpha: 0.30),
                      fontStyle: FontStyle.italic,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),

            // Bouton Réserver — émeraude avec halo
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00D87E), Color(0xFF00A85F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Text(
                'Réserver',
                style: TextStyle(
                  color: _white,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
