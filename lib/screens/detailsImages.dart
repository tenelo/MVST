import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mvst/config/config.dart';

class DetailsImages extends StatefulWidget {
  const DetailsImages({
    super.key,
    required this.imageUrl,
    required this.titre,
    required this.description,
  });

  final String imageUrl;
  final String titre;
  final String description;

  @override
  State<DetailsImages> createState() => _DetailsImagesState();
}

class _DetailsImagesState extends State<DetailsImages> {
  final DraggableScrollableController _sheetCtrl =
      DraggableScrollableController();

  @override
  void dispose() {
    _sheetCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = Config.colors;
    final double sw = MediaQuery.of(context).size.width;
    final double bottomPad = MediaQuery.of(context).padding.bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // ── Image plein écran avec zoom pinch ──────────────────────────
            Positioned.fill(
              child: InteractiveViewer(
                minScale: 1.0,
                maxScale: 5.0,
                child: Image.network(
                  widget.imageUrl,
                  fit: BoxFit.contain,
                  alignment: const Alignment(0, -0.4),
                  width: double.infinity,
                  height: double.infinity,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      color: Colors.black,
                      child: Center(
                        child: CircularProgressIndicator(
                          value: progress.expectedTotalBytes != null
                              ? progress.cumulativeBytesLoaded /
                                    progress.expectedTotalBytes!
                              : null,
                          color: c.homeButtonPrimary,
                          strokeWidth: 2,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stack) => Container(
                    color: Colors.black,
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image_outlined,
                          color: Colors.white24,
                          size: 56,
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Image non disponible',
                          style: TextStyle(color: Colors.white38, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── Gradient bas ──────────────────────────────────────────────
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 200,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.75),
                    ],
                  ),
                ),
              ),
            ),

            // ── Panneau glissable ─────────────────────────────────────────
            DraggableScrollableSheet(
              controller: _sheetCtrl,
              initialChildSize: 0.35,
              minChildSize: 0.18,
              maxChildSize: 0.62,
              snap: true,
              snapSizes: const [0.18, 0.62],
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: c.homeCardBackground,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 20,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: ListView(
                    controller: scrollController,
                    padding: EdgeInsets.zero,
                    children: [
                      // Handle
                      Center(
                        child: Container(
                          margin: const EdgeInsets.only(top: 12, bottom: 16),
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: c.homeTextPrimary.withValues(alpha: 0.20),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),

                      // Titre
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: sw * 0.06),
                        child: Text(
                          widget.titre,
                          style: TextStyle(
                            fontFamily: 'Lobster',
                            fontSize: sw * 0.060,
                            color: c.homeButtonPrimary,
                            height: 1.2,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      Divider(
                        height: 1,
                        thickness: 0.8,
                        indent: sw * 0.06,
                        endIndent: sw * 0.06,
                        color: c.homeTextPrimary.withValues(alpha: 0.10),
                      ),

                      const SizedBox(height: 16),

                      // Description
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          sw * 0.06,
                          0,
                          sw * 0.06,
                          bottomPad + 32,
                        ),
                        child: Text(
                          widget.description,
                          textAlign: TextAlign.justify,
                          style: TextStyle(
                            fontFamily: 'PlayfairDisplay',
                            fontSize: sw * 0.040,
                            height: 1.65,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // ── Bouton retour flottant ────────────────────────────────────
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.20),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: c.homeAccent,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
