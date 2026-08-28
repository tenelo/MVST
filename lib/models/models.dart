import 'package:flutter/material.dart';

// ── porte ──────────────────────────────────────────────────────────────────────
Widget porte() {
  return Row(
    children: [
      Container(
        decoration: BoxDecoration(
          color: Colors.grey[300],
          border: Border.all(
            color: const Color.fromARGB(255, 89, 87, 87),
            width: 1,
          ),
        ),
        height: 23,
        width: 8,
      ),
      Container(
        decoration: BoxDecoration(
          color: Colors.grey[300],
          border: Border.all(
            color: const Color.fromARGB(255, 89, 87, 87),
            width: 1,
          ),
        ),
        height: 24,
        width: 10,
      ),
      Container(
        decoration: BoxDecoration(
          color: Colors.grey[300],
          border: Border.all(
            color: const Color.fromARGB(255, 89, 87, 87),
            width: 1,
          ),
        ),
        height: 25,
        width: 12,
      ),
    ],
  );
}

// ── Modèles ────────────────────────────────────────────────────────────────────
Map<String, int> prixDesBillets = {};

class ImageModel {
  final int id;
  final String titre;
  final String description;
  final String statut;
  final String lien_image;

  bool get hasImage => lien_image.isNotEmpty;

  ImageModel({
    required this.id,
    required this.titre,
    required this.description,
    required this.statut,
    required this.lien_image,
  });

  factory ImageModel.fromJson(Map<String, dynamic> json) {
    return ImageModel(
      id: json['id'],
      titre: json['titre'],
      description: json['description'],
      statut: json['statut'],
      lien_image: json['lien_image'] ?? '',
    );
  }
}

class InfosTarifs {
  final String depart;
  final String destination;
  final int prix;

  InfosTarifs(this.depart, this.destination, this.prix);

  factory InfosTarifs.fromJson(Map<String, dynamic> json) {
    return InfosTarifs(json['depart'], json['destination'], json['prix']);
  }
}
