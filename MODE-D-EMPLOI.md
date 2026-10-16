# GD Remote — mode d'emploi

GD Remote est un client RustDesk (GPLv3) rebrandé par SARL IN SET. Il ne parle qu'à notre serveur `relay.gd.solutions` : le serveur et la clé sont figés dans l'application (Paramètres › Réseau grisé). Aucun service tiers, aucun compte à créer.

Téléchargements : https://github.com/kitpedago/rustdesk/releases (prendre la dernière release, fichiers `GD-Remote-<version>-x86_64.exe` pour Windows et `GD-Remote-<version>-aarch64-signed.apk` pour Android).

Deux usages :

| Usage | Côté machine distante | Côté intervenant |
|---|---|---|
| **Parc** (non surveillé) | GD Remote **installé**, mot de passe permanent, personne devant l'écran | ID + mot de passe permanent (+ code 2FA si activé) |
| **Support ponctuel** (surveillé) | GD Remote **lancé sans installer** par la personne aidée, qui accepte la prise de main | ID donné par la personne, puis elle clique « Accepter » (ou donne son mot de passe à usage unique) |

---

## 1. Installer GD Remote sur une machine du parc (Windows)

1. Télécharger l'exe, l'exécuter. Si SmartScreen s'affiche (exe non signé) : « Informations complémentaires » › « Exécuter quand même ». L'exe signé par SARL IN SET ne déclenche pas cet écran.
2. Cliquer **Installer** (bouton en bas de la fenêtre), accepter l'élévation. Le service `GD-Remote` démarre avec Windows ; l'application est dans `C:\Program Files\GD-Remote\`.
3. Poser le mot de passe permanent, au choix :
   - **Script (recommandé)** : PowerShell en administrateur, `powershell -ExecutionPolicy Bypass -File gd-remote-set-password.ps1` (fichier `res/gd-remote-set-password.ps1` du dépôt). Il génère 16 caractères, l'applique, affiche **l'ID et le mot de passe une seule fois**.
   - **Interface** : fenêtre principale, crayon à côté de « Mot de passe à usage unique » › « Définir un mot de passe permanent ». Règle : 12 caractères minimum, avec chiffre, majuscule et minuscule.
4. Noter ID + mot de passe dans le gestionnaire de mots de passe. Rien d'autre ne les conserve.
5. Recommandé : Paramètres › Sécurité › **Activer 2FA**, scanner le QR avec l'authentificateur de l'intervenant, cocher « Appareils de confiance » pour ne pas ressaisir le code depuis les postes habituels.
6. Vérifier : Paramètres › Réseau affiche `relay.gd.solutions` grisé ; l'indicateur en bas de la fenêtre est vert « Prêt ».

Installation silencieuse (déploiement par script, en administrateur) :

```bat
GD-Remote-1.5.0-x86_64.exe --silent-install
timeout /t 10
"C:\Program Files\GD-Remote\GD-Remote.exe" --password "MotDePasse12car"
"C:\Program Files\GD-Remote\GD-Remote.exe" --get-id
```

Désinstaller : Paramètres Windows › Applications › GD Remote, ou `"C:\Program Files\GD-Remote\GD-Remote.exe" --uninstall`.

## 2. Prendre la main sur une machine du parc

Depuis Windows ou Android avec GD Remote, ou depuis iPhone/iPad (voir §4) :

1. Saisir l'ID de la machine, **Connecter**.
2. Mot de passe permanent (cocher « Mémoriser » si le poste est de confiance), puis code 2FA si activé.
3. Barre d'outils en haut de la session : affichage, presse-papier, transfert de fichiers, chat, redémarrage, « Ctrl+Alt+Suppr », verrouillage à la fermeture.
4. Fermer l'onglet termine la session. Le presse-papier est partagé dans les deux sens pendant la session (texte, images, fichiers copiés).

Les machines connues apparaissent dans « Sessions récentes » ; clic droit › « Ajouter aux favoris » / renommer. Le carnet d'adresses est local au poste de l'intervenant.

## 3. Aider ponctuellement un tiers (mode surveillé)

Côté personne aidée (Windows) :

1. Télécharger l'exe (lui envoyer le lien de la release), **double-cliquer, ne pas installer**. La fenêtre affiche « Votre bureau », un **ID** et un **mot de passe à usage unique**. Rien n'est installé, rien ne reste après fermeture.
2. Communiquer l'ID à l'intervenant (téléphone, mail).
3. À la demande de connexion : fenêtre « Accepter » / « Rejeter » (le mot de passe à usage unique permet à l'intervenant d'entrer sans ce clic si la personne préfère le dicter). « Accepter et élever les privilèges » si une action administrateur est prévue.
4. Pendant la session, un panneau liste la connexion : la personne peut couper à tout moment. Fermer GD Remote met fin à tout.

Côté intervenant : saisir l'ID, **Connecter**, attendre l'acceptation (ou saisir le mot de passe à usage unique).

La version portable ne connaît aussi que `relay.gd.solutions` : un tiers ne peut pas être joint par un autre serveur, et un client RustDesk « officiel » sans notre clé est refusé par le serveur.

## 4. Mobiles

**Android (GD Remote, APK)**
- Installer l'APK : autoriser l'installation depuis cette source, puis « Installer ».
- Contrôler : onglet « Connexion », saisir l'ID. Les gestes sont expliqués au premier lancement (un doigt = souris, deux doigts = défilement, long appui = clic droit).
- Être contrôlé : onglet « Partager l'écran » › « Démarrer le service », accepter la capture d'écran Android (MediaProjection). Pour le contrôle tactile à distance, activer le service d'accessibilité **GD Remote Input** quand l'app le propose. Un mot de passe permanent peut être posé comme sur Windows (crayon à côté du mot de passe).
- Ne pas tuer l'app pour garder le service actif ; désactiver l'optimisation de batterie pour GD Remote si Android coupe le service.

**iPhone / iPad (contrôler seulement)**
- Installer **RustDesk** officiel depuis l'App Store (Apple interdit d'être contrôlé, et notre fork n'est pas publié sur l'App Store).
- Paramètres › Serveur ID/Relais : *ID server* `relay.gd.solutions`, *Relay server* vide, *Key* :

  ```
  VwyJr+48t6JAThdLabq62oOcdRYivz0m4bPC9JFVZio=
  ```
- Ensuite même usage que §2.

## 5. Entretien du parc

| Quoi | Comment |
|---|---|
| Changer le mot de passe d'une machine | `gd-remote-set-password.ps1` en administrateur sur la machine (affiche le nouveau), ou interface. À faire au départ d'un intervenant, sinon une fois par an. |
| Mettre à jour le client | Télécharger la nouvelle release, exécuter l'exe, **Installer** par-dessus : la configuration (ID, mot de passe, 2FA) est conservée. Pas de mise à jour automatique. Android : installer le nouvel APK par-dessus. |
| Retirer une machine | Désinstaller (§1). Son ID disparaît du serveur après inactivité. |
| Journal des connexions côté machine | Paramètres › À propos › « Ouvrir le dossier des journaux » (fichiers texte, un par jour). |

## 6. Serveur (VPS OVH, `/opt/rustdesk-server`)

```bash
cd /opt/rustdesk-server
docker ps --format '{{.Names}}\t{{.Status}}' | grep hbb   # hbbs = annuaire, hbbr = relais
docker logs hbbr --since 24h                               # sessions relayées (ID, IP des deux côtés)
docker compose restart                                     # coupe les sessions en cours quelques secondes
docker compose pull && docker compose up -d                # mise à jour de l'image serveur
```

- Ports ouverts (ufw) : 21115–21119/tcp, 21116/udp. DNS `relay.gd.solutions` chez Gandi (enregistrement A).
- `hbbs -k _` / `hbbr -k _` : seuls les clients porteurs de notre clé sont acceptés.
- **Clé du serveur** : `data/id_ed25519` (privée) et `data/id_ed25519.pub`. La perdre = tous les clients à reconstruire et redéployer. À sauvegarder hors VPS, avec `/opt/rustdesk-secrets/` (keystore Android, mots de passe, script des secrets GitHub).
- Pas de console web : la liste des machines n'existe que dans le gestionnaire de mots de passe et les favoris des postes intervenants.

## 7. Publier une nouvelle version du client

1. Dans `/opt/rustdesk` (branche `gd-remote`) : faire les modifications, bumper si besoin la version (`VERSION` dans `.github/workflows/flutter-build.yml`, `Cargo.toml`, `flutter/pubspec.yaml`, `libs/portable/Cargo.toml`), commit.
2. `git push github gd-remote && git push forgejo gd-remote`.
3. Build : `gh workflow run gd-remote.yml -R kitpedago/rustdesk --ref gd-remote -f upload-tag=dev` (test) ou tag `gd-x.y.z` poussé sur GitHub (release). ~25 min ; les fichiers arrivent dans la prerelease du tag.
4. **Signer l'exe** sur un PC Windows avec SimplySign Desktop connecté et `gh` connecté : `powershell -ExecutionPolicy Bypass -File res\gd-remote-sign.ps1 -Tag gd-x.y.z`. Le script télécharge, signe (Certum, SARL IN SET), vérifie et remplace le fichier de la release.
5. Sur GitHub, décocher « pre-release » pour en faire la version courante. Diffuser le lien.

Montée de version RustDesk amont : `git fetch` du dépôt upstream, rebase de `gd-remote` sur le nouveau tag, relire `src/common.rs::apply_fork_defaults`, `Runner.rc`, `libs/portable/Cargo.toml`, les workflows, puis build de test.

## 8. Dépannage

| Symptôme | Cause probable | Action |
|---|---|---|
| Fenêtre « Non prêt » / point rouge en bas | Pas de réseau vers `relay.gd.solutions:21116`, ou DNS | Tester `nc -vz relay.gd.solutions 21116` ; vérifier le pare-feu local/entreprise (TCP 21115–21119, UDP 21116 sortants) |
| « Clé incompatible » / échec de poignée de main | Client RustDesk officiel sans notre clé, ou mauvaise clé saisie (iOS) | Utiliser GD Remote, ou corriger la clé (§4) |
| ID introuvable / hors ligne | Machine éteinte, service arrêté, ou désinstallée | Sur la machine : `services.msc` › service GD-Remote démarré ; ou relancer l'app |
| Mot de passe refusé | Mot de passe changé, ou 2FA attendu | Vérifier le gestionnaire de mots de passe ; code TOTP |
| Session lente, « relais » dans la barre | P2P impossible (NAT stricts), tout passe par le VPS | Normal ; qualité réglable dans la barre d'outils (Affichage › qualité / codec) |
| SmartScreen bloque l'exe | Fichier non signé (build `dev`) ou signature absente | Utiliser la release signée ; sinon « Exécuter quand même » |
| Android : écran noir côté contrôleur | Capture d'écran refusée | Relancer « Partager l'écran » et accepter la capture |
| Android : la souris ne bouge pas | Service d'accessibilité « GD Remote Input » inactif | Paramètres Android › Accessibilité › GD Remote Input › activer |
| Côté serveur, rien ne répond | Conteneurs arrêtés | `docker compose up -d` dans `/opt/rustdesk-server`, puis `docker logs hbbs` |
