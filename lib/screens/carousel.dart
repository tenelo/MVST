import 'dart:convert';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mvst/config/config.dart';
import 'package:mvst/models/models.dart';
import 'package:mvst/screens/detailsImages.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class PromoStripWidget extends StatefulWidget {
  const PromoStripWidget({super.key});

  @override
  State<PromoStripWidget> createState() => _PromoStripWidgetState();
}

class _PromoStripWidgetState extends State<PromoStripWidget> {
  List<ImageModel> _images = [];
  bool _loading = true;
  int _current = 0;
  io.Socket? _socket;
  static const String _base = '$kBaseUrl/';

  @override
  void initState() {
    super.initState();
    _charger();
    _connectSocket();
  }

  @override
  void dispose() {
    _socket?.off('connect');
    _socket?.off('images_modifiees');
    _socket?.off('disconnect');
    _socket?.offAny();
    _socket?.disconnect();
    _socket?.dispose();
    super.dispose();
  }

  void _connectSocket() {
    try {
      _socket = io.io(
        kBaseUrl,
        io.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .build(),
      );
      _socket!.connect();
      _socket!.on('connect', (_) => _charger());
      _socket!.on('images_modifiees', (_) => _charger());
      _socket!.on('disconnect', (_) {
        Future.delayed(const Duration(seconds: 3), _connectSocket);
      });
    } catch (_) {}
  }

  Future<void> _charger() async {
    try {
      final res = await http
          .get(Uri.parse('$kBaseUrl/getImages.php'))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['success'] == true && mounted) {
          setState(() {
            _images = List<ImageModel>.from(
              data['images'].map((i) => ImageModel.fromJson(i)),
            ).where((i) => i.statut.toLowerCase() == 'actif').toList();
          });
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _images.isEmpty) return const SizedBox.shrink();

    final c = Config.colors;
    final Color accent = c.homeButtonPrimary;
    final Color dotInactive = c.homeButtonPrimary.withValues(alpha: 0.20);
    final double screenHeight = MediaQuery.of(context).size.height;
    final double carouselHeight =
        screenHeight *
        0.16; // hauteur du carousel à 16% de la hauteur de l'écran
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
            child: Row(
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  'ACTUALITÉS & OFFRES',
                  style: TextStyle(
                    color: accent.withValues(alpha: 0.65),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.3,
                  ),
                ),
              ],
            ),
          ),
          Stack(
            alignment: Alignment.bottomCenter,
            children: [
              CarouselSlider.builder(
                itemCount: _images.length,
                itemBuilder: (ctx, i, _) {
                  final url = _base + _images[i].lien_image;
                  return TweenAnimationBuilder(
                    tween: Tween<double>(begin: 0.8, end: 1.0),
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutCubic,
                    builder: (context, double scale, child) {
                      return Transform.scale(scale: scale, child: child);
                    },
                    child: GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DetailsImages(
                            imageUrl: url,
                            titre: _images[i].titre,
                            description: _images[i].description,
                          ),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.network(
                          url,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (context, error, stack) => Container(
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.07),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              Icons.image_outlined,
                              color: accent.withValues(alpha: 0.3),
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
                options: CarouselOptions(
                  height: carouselHeight,
                  viewportFraction: 0.80,
                  autoPlay: _images.isNotEmpty,
                  autoPlayInterval: const Duration(seconds: 4),
                  autoPlayAnimationDuration: const Duration(milliseconds: 700),
                  autoPlayCurve: Curves.easeInOutCubic,
                  enlargeCenterPage: true,
                  enlargeFactor: 0.20,
                  padEnds: true,
                  onPageChanged: (i, _) => setState(() => _current = i),
                ),
              ),
              if (_images.length > 1)
                Positioned(
                  bottom: 8,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_images.length, (i) {
                      final bool active = i == _current;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeInOut,
                        margin: const EdgeInsets.symmetric(horizontal: 2.5),
                        width: active ? 10 : 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: active ? accent : dotInactive,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
