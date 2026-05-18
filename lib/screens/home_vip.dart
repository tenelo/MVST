import 'package:flutter/material.dart';

const Color _em = Color(0xFF00D87E);
const Color _emDark = Color(0xFF019A5A);
const Color _gold = Color(0xFFC8A227);
const Color _white = Colors.white;

Map<String, List<String>> _group(List<Map<String, String>> routes) {
  final Map<String, List<String>> g = {};
  for (final r in routes) {
    g.putIfAbsent(r['depart']!, () => []).add(r['destination']!);
  }
  return g;
}

// ── Widget principal ──────────────────────────────────────────────────────────
class HomeVip extends StatelessWidget {
  const HomeVip({super.key, this.onReserver, required this.routes});
  final Future<void> Function(String depart, String destination)? onReserver;
  final List<Map<String, String>> routes;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final grouped = _group(routes);

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _HeroBand(w: w),
        _SectionHeader(w: w),
        if (routes.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text(
                'Aucune ligne VIP disponible',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF00D87E).withValues(alpha: 0.5),
                  fontSize: w * 0.038,
                ),
              ),
            ),
          )
        else
          ...grouped.entries.map(
            (e) => _OriginGroup(
              depart: e.key,
              destinations: e.value,
              w: w,
              onReserver: onReserver,
            ),
          ),
        SizedBox(height: w * 0.08),
      ],
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
      padding: EdgeInsets.fromLTRB(w * 0.055, w * 0.075, w * 0.055, w * 0.07),
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
            padding: EdgeInsets.symmetric(
              horizontal: w * 0.030,
              vertical: w * 0.012,
            ),
            decoration: BoxDecoration(
              color: _em.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(w * 0.075),
              border: Border.all(
                color: _em.withValues(alpha: 0.30),
                width: 0.9,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.airline_seat_recline_extra,
                  color: _em,
                  size: w * 0.033,
                ),
                SizedBox(width: w * 0.018),
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
                width: w * 0.08,
                height: 2,
                decoration: BoxDecoration(
                  color: _gold,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
              SizedBox(width: w * 0.015),
              Container(
                width: w * 0.025,
                height: 2,
                decoration: BoxDecoration(
                  color: _gold.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ],
          ),
          SizedBox(height: w * 0.04),

          // Pills — Wrap directement sans Row autour
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Wrap(
                  spacing: w * 0.010,
                  runSpacing: w * 0.010,
                  children: [
                    '★ Grand confort',
                    '🌿 Éco Premium',
                    '🎫 QR instantané',
                  ].map((label) => _Pill(label: label, w: w)).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Pill ──────────────────────────────────────────────────────────────────────
class _Pill extends StatelessWidget {
  final String label;
  final double w;
  const _Pill({required this.label, required this.w});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: w * 0.030, vertical: w * 0.016),
      decoration: BoxDecoration(
        color: _emDark.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(w * 0.075),
        border: Border.all(color: _em.withValues(alpha: 0.28), width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: _em,
          fontSize: w * 0.028,
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
      padding: EdgeInsets.fromLTRB(w * 0.05, w * 0.055, w * 0.05, w * 0.015),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: w * 0.008,
                height: w * 0.050,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_em, _gold],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(width: w * 0.025),
              Text(
                'Lignes Classe VIP',
                style: TextStyle(
                  color: const Color.fromARGB(255, 5, 111, 1),
                  fontWeight: FontWeight.w800,
                  fontSize: w * 0.044,
                  letterSpacing: -0.4,
                ),
              ),
            ],
          ),
          SizedBox(height: w * 0.012),
          Padding(
            padding: EdgeInsets.only(left: w * 0.033),
            child: Text(
              'Sièges spacieux · Confort absolu · Départ garanti',
              style: TextStyle(
                color: const Color.fromARGB(255, 3, 51, 1),
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
  final double w;
  final Future<void> Function(String, String)? onReserver;

  const _OriginGroup({
    required this.depart,
    required this.destinations,
    required this.w,
    this.onReserver,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(w * 0.04, w * 0.01, w * 0.04, w * 0.035),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: w * 0.01, bottom: w * 0.02),
            child: Row(
              children: [
                Container(
                  width: w * 0.02,
                  height: w * 0.02,
                  decoration: const BoxDecoration(
                    color: _em,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: w * 0.02),
                Text(
                  depart == 'Abidjan'
                      ? "A partir d'${depart.toUpperCase()}"
                      : "A partir de ${depart.toUpperCase()}",
                  style: TextStyle(
                    color: _emDark,
                    fontWeight: FontWeight.w800,
                    fontSize: w * 0.026,
                    letterSpacing: 1.8,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(w * 0.04),
              border: Border.all(color: _emDark, width: 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(w * 0.04),
              child: Column(
                children: List.generate(destinations.length, (i) {
                  final isLast = i == destinations.length - 1;
                  return Column(
                    children: [
                      _RouteRow(
                        depart: depart,
                        destination: destinations[i],
                        w: w,
                        onTap: onReserver == null
                            ? null
                            : () => onReserver!.call(depart, destinations[i]),
                      ),
                      if (!isLast)
                        Divider(
                          height: 0.7,
                          thickness: 1,
                          color: _em.withValues(alpha: 0.4),
                          indent: w * 0.15,
                          endIndent: w * 0.04,
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
class _RouteRow extends StatefulWidget {
  final String depart;
  final String destination;
  final double w;
  final Future<void> Function()? onTap;

  const _RouteRow({
    required this.depart,
    required this.destination,
    required this.w,
    this.onTap,
  });

  @override
  State<_RouteRow> createState() => _RouteRowState();
}

class _RouteRowState extends State<_RouteRow> {
  bool _loading = false;

  Future<void> _handleTap() async {
    if (_loading || widget.onTap == null) return;
    setState(() => _loading = true);
    try {
      await widget.onTap!();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.w;
    return InkWell(
      onTap: _loading ? null : _handleTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: w * 0.04,
          vertical: w * 0.033,
        ),
        child: Row(
          children: [
            Container(
              width: w * 0.095,
              height: w * 0.095,
              decoration: BoxDecoration(
                color: _em.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(w * 0.028),
              ),
              child: Icon(
                Icons.airline_seat_recline_extra,
                color: _emDark,
                size: w * 0.048,
              ),
            ),
            SizedBox(width: w * 0.035),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.depart} → ${widget.destination}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: w * 0.037,
                      letterSpacing: -0.2,
                    ),
                  ),
                  SizedBox(height: w * 0.005),
                  Text(
                    'Ligne ${widget.depart} ${widget.destination}',
                    style: TextStyle(
                      color: _white.withValues(alpha: 0.30),
                      fontStyle: FontStyle.italic,
                      fontSize: w * 0.025,
                    ),
                  ),
                ],
              ),
            ),
            if (_loading)
              SizedBox(
                width: w * 0.055,
                height: w * 0.055,
                child: const CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: _em,
                ),
              )
            else
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: w * 0.030,
                  vertical: w * 0.018,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00D87E), Color(0xFF00A85F)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(w * 0.055),
                ),
                child: Text(
                  'Réserver',
                  style: TextStyle(
                    color: _white,
                    fontWeight: FontWeight.w800,
                    fontSize: w * 0.027,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
