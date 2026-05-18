import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mvst/config/config.dart';
import 'package:mvst/screens/home.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccepterTermesDutilisations extends StatefulWidget {
  const AccepterTermesDutilisations({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _AccepterTermesDutilisationsPageState createState() =>
      _AccepterTermesDutilisationsPageState();
}

class _AccepterTermesDutilisationsPageState
    extends State<AccepterTermesDutilisations> {
  bool? _termsAccepte;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _accepterTermes() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('termesAccepté', true);
    setState(() {
      _termsAccepte = true;
    });
    // Après avoir accepté les termes, naviguez vers l'application principale
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (context) => const Home()));
  }

  Future<void> _refuserTermes() async {
    // Ferme toute l'application
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = Config.colors;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Termes et Conditions",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        backgroundColor: c.authButtonDisabled,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: RichText(
                  text: const TextSpan(
                    style: TextStyle(color: Colors.black, fontSize: 15),
                    children: [
                      TextSpan(
                        text:
                            "\nCONDITIONS GENERALES D'UTILISATION DE L'APPLICATION\n\n\n\n",
                        style: TextStyle(
                          color: Color.fromARGB(255, 150, 146, 146),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text: "Article 1 : Objet",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: "\n\n...."),
                      //                       TextSpan(
                      //                         text: """
                      // \n\nLa prestation fournie dans le cadre de l’application « Tickets MVST» s’adresse aux personnes souhaitant effectuer un déplacement urbain en véhicule motorisé ; elle consiste précisément à mettre à leur disposition une application de réservation et paiement de titre de transport valides pour les compagnies ivoirienne MVST et AHT.
                      // Les présentes conditions générales ont pour objet de définir les conditions d’utilisation de l’application et les conditions de réalisation de la prestation, acceptées par le client et les prestataires MVST et AHT.""",
                      //                       ),
                      TextSpan(
                        text: "\n\nArticle 2 : Définitions",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: "\n\n...."),
                      //                       TextSpan(
                      //                         text: """
                      // \n\n« Application » désigne l’application mobile «Tickets MVST», éditée par la société ivoirienne NEKS-TECHNOLOGY pour le compte des compagnies de transport MVST et AHT et installée sur le téléphone mobile du client, à l’initiative de ce dernier.
                      // « Chauffeur » désigne le conducteur du véhicule réalisant effectivement le trajet commandé par le Client.

                      // « Client » désigne toute personne utilisant l’application afin de réserver et payer un titre de transport valide pour les compagnies MVST et AHT pour un trajet déterminé.

                      // « Client Entreprises » désigne tout client qui a souscrit à l’offre MVST Ticket Mobile Entreprises.

                      // « Commande » désigne toute réservation et paiement de ticket effectuée et validée par le Client à partir de l’application mobile selon les conditions définies à l’Article 7. Une commande pouvant être soit une commande immédiate, soit une commande à l’avance.

                      // « Commande Immédiate » désigne toute réservation et paiement de ticket effectuée et validée par le client à partir de l’application selon les conditions définies à l’Article 7 pour un voyage devant être éffectué le jour même du paiement.

                      // « Commande à l’avance» désigne toute réservation et paiement de ticket effectuée et validée par le Client à partir du Site, de l’Application ; pour un voyage prévu à une date ultérieur à cette du paiement .

                      // « Conditions Générales » désigne les conditions d’utilisation de l’application et de réalisation de la prestation qui doivent obligatoirement être acceptées par le client avant toute reservation de ticket.

                      // « Prestataire » désigne les compagnies de transport, opérant sous le nom commercial de "MVST" et "AHT" dont le siège social se situe à Abidjan (Commune de Marcory), immeuble ITRAP-CI , représentée par son Président dûment habilité

                      // « Prestation » désigne la prestation de services fournie par le Prestataire et consistant à transporter le client depuis la gare de départ spécifiée lors de la réservation jusqu'à la gare de destination dans la ville indiquée par le client lors de la réservation de ticket pour le trajet.

                      // « Service » désigne l’ensemble des prestations fournies par le Prestataire.""",
                      //                       ),
                      TextSpan(
                        text: "\n\nArticle 3 : Création du compte client",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: "\n\n...."),
                      //                       TextSpan(
                      //                         text: """
                      // \n\nLa Commande de la Prestation requiert la création préalable d’un compte client, consécutive à l’installation gratuite de l’Application sur le téléphone mobile du Client, ou sur le Site. Lors de son inscription, le Client choisit un identifiant de connexion et un mot de passe, lesquels sont personnels, confidentiels et non cessibles à des tiers. Après en avoir préalablement averti l'abonné, le Prestataire pourra, pour les besoins de l'exploitation du service, modifier, changer, radier un identifiant ou un mot de passe et ce, à tout moment.
                      // Le Client enregistre ses informations personnelles (nom et prénom, adresse électronique, numéro de téléphone, code postal du lieu de résidence).
                      // Le Client garantit la véracité et l’exactitude des informations qu’il communique au Prestataire par l’intermédiaire de l’Application.
                      // Le Prestataire pourra demander au Client de présenter une pièce d'identité, ou le moyen de paiement enregistré (carte bancaire). Si le Client est dans l'impossibilité de fournir ces pièces, le Chauffeur ne pourra effectuer le Transfert journalier convenu.
                      // La création du compte client ne pourra être validée qu’à la suite de l’acceptation expresse des présentes Conditions Générales par le Client, qui reconnaîtra par là-même en avoir pris connaissance.""",
                      //                       ),
                      TextSpan(
                        text: "\n\nArticle 4 : Utilisation de l’Application",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: "\n\n...."),
                      //                       TextSpan(
                      //                         text: """
                      // \n\nPour utiliser l’Application, le Client doit être capable juridiquement de contracter et utiliser l’Application conformément aux présentes Conditions Générales.
                      // Pour accéder à l’Application, le Client doit s’identifier par un identifiant et un mot de passe. Toute Commande par l’intermédiaire de l’identifiant et du mot de passe du Client est réputée faite par lui. En conséquence, le prix de toute Commande émanant de son compte client sera facturé ou débité du compte correspondant.
                      // Le Client s’engage à utiliser l’Application à la manière d’un bon père de famille.
                      // En cas de problème technique relatif au fonctionnement de l’Application, le Client peut solliciter l’assistance technique par voie électronique (à l’adresse électronique suivante : serviceclient@MVSTci.net).""",
                      //                       ),
                      TextSpan(
                        text: "\n\nArticle 5 : Résiliation de l’inscription",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: "\n\n...."),
                      //                       TextSpan(
                      //                         text: """
                      // \n\nLe Client peut résilier à tout moment son compte client et supprimer l’Application de son téléphone mobile, sur simple demande à l’adresse électronique suivante : serviceclient@MVSTci.net).
                      // Le Prestataire peut résilier l’inscription du Client sans préavis en cas de non-respect par le Client de ses obligations, en cas de compte bancaire non provisionné et en sus, dès lors que le Client aura annulé sa Commande à trois reprises dans la même semaine.""",
                      //                       ),
                      TextSpan(
                        text:
                            "\n\nArticle 6 : Confidentialité – Protection des données à caractère personnel",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: "\n\n...."),
                      //                       TextSpan(
                      //                         text: """
                      // \n\nLes présentes Conditions Générales sont soumises aux dispositions de la loi relative à l’informatique, aux fichiers et aux libertés.
                      // Le Client dispose d’un droit d’accès, de rectification et de suppression des données à caractère personnel le concernant sur simple demande adressée au Prestataire.
                      // Le Prestataire informe le Client sur l’utilisation qui est faite des données à caractère personnel le concernant collectées dans le cadre de l’utilisation de l’Application.
                      // Le Prestataire peut communiquer à des tiers les coordonnées du Client pour les besoins de l’utilisation de l’Application et notamment au Chauffeur. Le Client dispose bien entendu d'un droit d'opposition (par tout moyen et notamment courrier simple adressé au Prestataire) à la cession à des tiers à des fins de prospection commerciale des informations nominatives détenues sur sa personne.
                      // Le Client accepte que le Prestataire se réserve la possibilité d’enregistrer et de conserver, à des fins de preuve, l’ensemble des informations relatives aux connexions effectuées, telles que les données relatives au trajet et les coordonnées personnelles du Client.""",
                      //                       ),
                      TextSpan(
                        text: "\n\nArticle 7 : La Commande",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: "\n\n...."),
                      TextSpan(
                        text: "\n\n7.1 Condition préalable",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: "\n\n...."),
                      //                       TextSpan(
                      //                         text: """
                      // \n\nLa Commande de prestations via l’application mobile est soumise à l’acceptation préalable par le client des présentes conditions générales.""",
                      //                       ),
                      TextSpan(
                        text: "\n\n7.2 Descriptif des étapes de la commande",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: "\n\n...."),
                      //                       TextSpan(
                      //                         text: """
                      // \n\nPour commander, le Client se connecte à l’Application en saisissant son identifiant et son mot de passe.
                      // Il renseigne les différents champs relatifs au Trajet souhaité (Ville de départ, Gare de départ, Ville de destination et la date de départ).
                      // A défaut du renseignement de l'une de ces informations de départ, le processus de commande ne pourra pas aboutir.
                      // Il lance la recherche de départs prévus correspondant aux critères spécifiés.
                      // La liste des départs correspondants aux critères spécifiés par le client s'affiche avec leurs prix respectifs.
                      // Le Client est libre d’accepter ou non l’offre proposée par le Prestataire ; s’il l’accepte, il doit s’être préalablement assuré que toutes les informations affichées sont conformes au trajet souhaité.
                      // S'il accepte, le client indique le nombre de tickets désirés pour le trajet et le valide.
                      // Il indique alors les informations d'identification (Nom, Prenom, Sexe) des bénéficiaires de chacun des tickets commandés.
                      // Il Sélectionne un mode de paiement (par Compte Prépayé ou Mobile Money) et procède au paiement.""",
                      //                       ),
                      TextSpan(
                        text: "\n\n7.3 Obligations du Client",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: "\n\n...."),
                      //                       TextSpan(
                      //                         text: """
                      // \n\nAprès validation de la Commande, le Client doit se présenter au lieu convenu au moins 30 minutes avant l'heure effective de départ.
                      // Conformément à l'article 3, le Chauffeur ou le contrôleur de gare pourra demander au Client de présenter sa pièce d'identité le ticket electronique ou la preuve de paiement de son titre de transport.
                      // En cas de non-présentation du Client, le Chauffeur est réputé libre de partir après une période d’attente de 10 minutes. Des frais d’annulation, dont le montant est déterminé à l’article 9.2, lui seront automatiquement facturés.""",
                      //                       ),
                      TextSpan(
                        text: "\n\n7.4 Obligations du Prestataire",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: "\n\n...."),
                      //                       TextSpan(
                      //                         text: """
                      // \n\nA la réception de la demande du Client, en cas de disponibilité d'un départ correspondant au critère de la demande, le Prestataire s’engage à proposer une offre indiquant le prix du trajet.
                      // Si le Client accepte l’offre, le Prestataire s’engage à à transporter le client vers la destination souhaitée.
                      // Le temps d’arrivée fourni par le Prestataire est indicatif et basé sur des temps standards qui ne sauraient engager sa responsabilité.
                      // Sur demande du Client, le Prestataire transmet les informations relatives à la Commande conservées dans la base de données du Prestataire.""",
                      //                       ),
                    ],
                  ),
                ),
              ),
            ),
            RadioGroup<bool>(
              groupValue: _termsAccepte,
              onChanged: (value) => setState(() => _termsAccepte = value),
              child: Column(
                children: [
                  RadioListTile(
                    title: const Text('J\'accepte les termes d\'utilisation'),
                    value: true,
                  ),
                  RadioListTile(
                    title: const Text(
                      'Je n\'accepte pas les termes d\'utilisation',
                    ),
                    value: false,
                  ),
                ],
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _termsAccepte != null && _termsAccepte!
                    ? _accepterTermes
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: c.authButtonDisabled,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    side: BorderSide(color: c.homeButtonPrimary),
                  ),
                ),
                child: const Text(
                  'Continuer',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    _termsAccepte ==
                        false // Seulement activé si "Je n'accepte pas les termes d'utilisation" est sélectionné
                    ? _refuserTermes // Fonction à exécuter lorsque le bouton "Annuler" est pressé
                    : null, // Désactiver le bouton si l'autre option est sélectionnée
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrangeAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    side: const BorderSide(
                      color: Color.fromARGB(236, 243, 142, 33),
                    ),
                  ),
                ),
                child: const Text(
                  'Annuler',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
