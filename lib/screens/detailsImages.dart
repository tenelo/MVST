import 'package:flutter/material.dart';
import 'package:mvst/config/config.dart';

class DetailsImages extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final c = Config.colors;
    final double screenH = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: c.authBorder,
      appBar: AppBar(
        iconTheme: IconThemeData(color: c.homeAccent),
        backgroundColor: c.authButtonDisabled,
        title: Text(
          titre,
          style: TextStyle(
            color: c.homeBandeauBorder,
            fontFamily: 'Lobster',
            //fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // ── Image de fond (plein écran en haut) ─────────────────────────────
          // Container(
          //   width: double.infinity,
          //   height: screenH * 0.55,
          //   decoration: BoxDecoration(
          //     image: DecorationImage(
          //       image: NetworkImage(imageUrl),
          //       fit: BoxFit.cover, // Cover pour remplir l'espace
          //     ),
          //   ),
          // ),
          Container(
            width: double.infinity,
            height: screenH * 0.6,
            color: c.homeCardBackground,
            child: Image.network(
              imageUrl,
              // contain = l'image entière est visible, sans coupure
              fit: BoxFit.contain,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: progress.expectedTotalBytes != null
                        ? progress.cumulativeBytesLoaded /
                              progress.expectedTotalBytes!
                        : null,
                    color: c.homeButtonPrimary,
                    strokeWidth: 2,
                  ),
                );
              },
              errorBuilder: (context, error, stack) => Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.broken_image_outlined,
                    color: c.homeButtonPrimary.withValues(alpha: 0.35),
                    size: 48,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Image non disponible',
                    style: TextStyle(
                      color: c.homeTextPrimary.withValues(alpha: 0.45),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // ── Conteneur blanc arrondi en bas ──────────────────────────────────
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height:
                  screenH * 0.35, // Légèrement plus haut pour plus de contenu
              width: double.infinity,

              decoration: BoxDecoration(
                color: c.homeCardBackground, // Utilise la couleur du thème
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                // border: Border(
                //   top: BorderSide(
                //     color: Colors.blue,
                //     width: 3,
                //   ),
                // ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Titre ──────────────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              textAlign: TextAlign.center,
                              titre,
                              style: TextStyle(
                                fontFamily: 'Lobster',
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: c
                                    .homeButtonPrimary, // Utilise la couleur primaire du thème
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Séparateur ────────────────────────────────────────────
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: c.homeTextPrimary.withValues(alpha: 0.08),
                    ),

                    // ── Description (scrollable) ──────────────────────────────
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: SingleChildScrollView(
                          child: Text(
                            textAlign: TextAlign.justify,
                            description,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.6,
                              color: c.homeTextPrimary.withValues(alpha: 0.75),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
