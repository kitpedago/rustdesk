# GD Remote — fork RustDesk auto-hébergé : suivi

Serveur : `/opt/rustdesk-server` (compose). Fork client : `/opt/rustdesk`, branche `gd-remote` basée sur le tag upstream `1.5.0` ; `master` reste le miroir upstream (rebase de `gd-remote` à chaque montée de version).

## Décisions (interview 2026-10-16)

| Sujet | Décision |
|---|---|
| VPS | Cette machine : `vps-dcd1cc14`, OVH, 51.75.141.221 / 2001:41d0:305:2100::8994 |
| Sous-domaine | `relay.gd.solutions` — DNS chez Gandi, configuré par gducos (A + AAAA) |
| iOS contrôlé | Impossible (Apple), accepté. iOS contrôlant = client RustDesk officiel App Store, serveur saisi à la main. Aucun build iOS. |
| Marque | « GD Remote », icône générée |
| Licence / distribution | Installé chez des tiers = distribution GPLv3 : dépôt public GitHub + miroir `git.gd.solutions/in-set/rustdesk` |
| Code-signing Windows | Certum Code Signing in the Cloud (SimplySign), CN SARL IN SET, 3 ans — signature locale, voir Phase 4 |
| Apple Developer | Non |
| Dimensionnement | < 50 machines, < 10 sessions simultanées |
| Durcissement | Clé publique embarquée + 2FA client. Pas de whitelist d'ID (bloquerait les tiers du mode surveillé). WireGuard `wg0` déjà présent sur le VPS. |
| Emplacements | Serveur : `/opt/rustdesk-server`. Fork client : `/opt/rustdesk` (clone), builds en CI uniquement (disque VPS à 89 %). |

## Serveur

- Image : `rustdesk/rustdesk-server:latest` = **1.1.16** (`sha256:8ecdab65deb7…`)
- `network_mode: host` : ufw filtre réellement (le mode bridge contournerait ufw).
- hbbs lancé sans `-r` : relais vide ⇒ le client utilise l'hôte du serveur d'ID. Pas de dépendance DNS côté serveur.
- Ports : 21115–21119/tcp + 21116/udp ouverts dans ufw (v4 + v6). 21114 non utilisé (console Pro).
- fail2ban + unattended-upgrades : déjà actifs sur l'hôte avant ce chantier.

### Clé publique (data/id_ed25519.pub)

```
VwyJr+48t6JAThdLabq62oOcdRYivz0m4bPC9JFVZio=
```

Clé privée : `/opt/rustdesk-server/data/id_ed25519` (root). À sauvegarder : perdre la clé = re-déployer tous les clients.

## Fork (Phase 3)

Principe : **zéro modification du sous-module `libs/hbb_common`** (reste pointé sur upstream). Toute la personnalisation est dans le crate principal + ressources.

| Point | Choix |
|---|---|
| Nom interne `APP_NAME` | `GD-Remote` (upstream n'accepte que alphanumérique + tiret : `lang.rs`). Sert pour le dossier `%APPDATA%\GD-Remote`, le service Windows, `GD-Remote.exe` après installation, le schéma URI `gd-remote://`. |
| Nom affiché | « GD Remote » (label Android, ProductName Windows). Les chaînes UI « RustDesk … » sont réécrites à la volée par `src/lang.rs` dès que `APP_NAME` ≠ RustDesk. |
| Serveur + clé | `src/common.rs::apply_fork_defaults()` appelé en tête de `load_custom_client()` : `APP_NAME`, puis `OVERWRITE_SETTINGS` pour serveur, relais, api-server et clé (verrouillés depuis la Phase 5 ; en Phase 3 c'était `DEFAULT_SETTINGS`, modifiable). Même levier que le `custom.txt` des clients Pro (dont la signature exige la clé privée de RustDesk, d'où le hardcode). |
| Effet « custom client » | `is_custom_client()` devient vrai : plus de vérification de mise à jour upstream, mention « Powered by RustDesk » conservée (attribution GPL), compte à rebours anti-arnaque désactivé. |
| Android | `applicationId solutions.gd.remote` (coexiste avec RustDesk officiel), labels, `android:scheme="gd-remote"`, strings.xml, notifications (`MainService.kt`, `BootReceiver.kt`), couleur de fond d'icône adaptative. Namespace Kotlin `com.carriez.flutter_hbb` inchangé. |
| Windows | `Runner.rc` : ProductName, FileDescription, InternalName, OriginalFilename, CompanyName « GD Solutions », copyright avec attribution RustDesk. L'exe est encore produit comme `rustdesk.exe` par le build, renommé `GD-Remote.exe` à l'installation par le code upstream. |
| Icônes | Monogramme « GD » blanc sur `#1F4E79`, généré par `res/gen_gd_remote_icons.sh` (ImageMagick) : res/*.png, res/icon.ico, tray-icon.ico, app_icon.ico Windows, mipmaps Android (launcher, round, foreground adaptatif, ic_stat), `flutter/assets/icon.svg`. SVG Linux (`res/scalable.svg`, `logo.svg`) non refaits : Linux hors cible. |
| Modes | Aucune modification : défauts upstream = mot de passe **ou** clic d'acceptation. Parc = définir un mot de passe permanent fort à l'installation (`--password` en silencieux) → non surveillé. Tiers = lance l'app, donne son ID, accepte le clic → surveillé. |

Dépôts distants (2026-10-16) :
- GitHub (public, CI) : https://github.com/kitpedago/rustdesk — fork de rustdesk/rustdesk, branche par défaut `gd-remote`, remote `github`.
- Forgejo (miroir) : https://git.gd.solutions/in-set/rustdesk — privé, branche par défaut `gd-remote`, remote `forgejo`.
- Après chaque commit : `git push github gd-remote && git push forgejo gd-remote`.

## CI / builds (Phase 4)

GitHub Actions sur le fork (dépôt public = runners Windows/Linux gratuits). Rien ne se construit sur le VPS.

| Point | Choix |
|---|---|
| Déclencheur | `.github/workflows/gd-remote.yml` : `workflow_dispatch` (tag `dev` par défaut) ou push d'un tag `gd-x.y.z`. Publie une prerelease GitHub sur ce tag. |
| Workflow réutilisable | `flutter-build.yml` upstream réduit (2635 → 641 lignes) : `generate-bridge`, `TopMostWindow` x64, `build-for-windows-flutter` x64, `build-rustdesk-android` arm64. Jobs iOS/Linux/macOS/web/sciter/sbom/MSI supprimés. Autres workflows upstream (ci, nightly, tag, fdroid…) supprimés sur `gd-remote`. |
| Windows | Installeur auto-extractible `GD-Remote-<ver>-x86_64.exe` (`libs/portable`). Signature `signtool` (SHA-256 + horodatage) des exe/dll puis de l'installeur, seulement si `WINDOWS_PFX_BASE64` est défini. MSI retiré : `res/msi/preprocess.py` suppose « RustDesk », à reprendre si déploiement GPO. |
| Android | `GD-Remote-<ver>-aarch64.apk`, signé par `r0adkll/sign-android-release` avec le keystore ci-dessous. armv7/x86_64 retirés. |
| Secrets GitHub | `ANDROID_SIGNING_KEY` (jks base64), `ANDROID_ALIAS`, `ANDROID_KEY_STORE_PASSWORD`, `ANDROID_KEY_PASSWORD`, `WINDOWS_PFX_BASE64`, `WINDOWS_PFX_PASSWORD`. Poussés par `/opt/rustdesk-secrets/set-github-secrets.sh kitpedago/rustdesk` (fait le 2026-10-16, secrets Android). |
| Keystore Android | `/opt/rustdesk-secrets/gd-remote-android.jks` (PKCS12, alias `gd-remote`, RSA 4096, 10 000 j), mots de passe dans `android-keystore.env` (dossier 700, fichiers 600). **À sauvegarder hors VPS** : perdu = impossible de mettre à jour l'APK. |
| Certificat Windows | **Certum Code Signing in the Cloud** (SimplySign), CN « SARL IN SET », 3 ans. Clé non exportable : pas de .pfx, pas de signature en CI. Flux : la CI publie `GD-Remote-<ver>-x86_64.exe` non signé → sur un PC Windows avec SimplySign Desktop connecté, `res/gd-remote-sign.ps1 -Tag <tag> -Repo kitpedago/rustdesk` télécharge, signe (`signtool /n "SARL IN SET"`, horodatage `time.certum.pl`), vérifie et ré-uploade. Seul l'installeur est signé (suffit pour SmartScreen) ; les exe/dll internes restent non signés — amélioration possible : signer le dossier `rustdesk-unsigned-windows-x86_64` puis reconstruire le packer en local. Les étapes `.pfx` du workflow restent pour un éventuel autre certificat. |

gh connecté sur le VPS (compte `kitpedago`, device flow), Actions activées, secrets Android poussés, premier `workflow_dispatch` lancé le 2026-10-16 (tag `dev`).

## Durcissement (Phase 5)

| Mesure | État |
|---|---|
| Clients sans clé refusés | **Fait** : `hbbs -k _` et `hbbr -k _` (compose, 2026-10-16). Un client qui n'a pas la clé publique ne peut ni s'enregistrer ni relayer : le relais public ne sert qu'à nos clients. |
| Clé embarquée = serveur | Par construction : le client vérifie la signature de hbbs avec la clé embarquée (`apply_fork_defaults`), un hbbs usurpé est rejeté. |
| Chiffrement de bout en bout | Inchangé (upstream) : NaCl entre pairs, le relais ne voit que du chiffré ; l'échange des clés de pairs passe par hbbs, authentifié par la clé ci-dessus. |
| Mot de passe permanent fort | **Fait** : règle client portée de 8 à 12 caractères minimum (+ chiffre, majuscule, minuscule, upstream). Dialogue commun desktop/mobile. |
| Rotation | `res/gd-remote-set-password.ps1` (admin, sur la machine du parc) : génère 16 caractères, applique via `GD-Remote.exe --password`, affiche ID + mot de passe une fois. Fréquence conseillée : à chaque départ d'un intervenant, sinon annuelle. |
| 2FA | Pas pré-configurable (secret TOTP par machine). Procédure : sur chaque machine du parc, Paramètres › Sécurité › « Activer 2FA », scanner le QR avec l'authentificateur de l'admin ; cocher « Appareils de confiance » pour ne pas ressaisir depuis les postes connus. |
| Whitelist d'ID, VPN devant le relais | Non retenus (décision interview) : bloqueraient le mode surveillé avec des tiers. `wg0` reste disponible si un jour le parc seul doit être joignable. |
| Journalisation | **Fait** : logs Docker json-file 5 × 20 Mo. `docker logs hbbr` trace chaque session relayée (ID de session, IP des deux pairs, fermeture). hbbs ne journalise pas les sessions P2P au niveau INFO ; chaque client Windows garde son propre journal de connexions (Paramètres › À propos › Journaux). Audit centralisé = console Pro, hors périmètre. |
| Verrouiller serveur/clé dans le client | **Fait** (décision 2026-10-16) : `apply_fork_defaults` utilise `OVERWRITE_SETTINGS` pour `custom-rendezvous-server`, `relay-server` (vide = fourni par hbbs), `api-server` (vide) et `key`. Paramètres › Réseau grisés. Changer de serveur = nouvelle version. |
| Mises à jour | Client : plus de vérification upstream (custom client) ; publier une release GitHub `gd-x.y.z` et redéployer. Serveur : `cd /opt/rustdesk-server && docker compose pull && docker compose up -d`. OS : unattended-upgrades actif. |
| Sauvegardes | `/opt/rustdesk-server/data/id_ed25519*` (clé serveur) et `/opt/rustdesk-secrets/` (keystore Android) : à copier hors VPS, aucune sauvegarde automatique en place. |

## Avancement

- [x] Phase 0 — ufw ouvert, Docker/Compose présents. **Reste :** DNS `relay.gd.solutions` (Gandi, gducos) ; vérifier dans le manager OVH que le pare-feu réseau (Edge) est désactivé ou ouvre les mêmes ports.
- [x] Phase 1 — hbbs + hbbr up (1.1.16), clé notée, nc OK sur les 5 ports TCP + UDP depuis l'hôte.
- [x] Phase 2 — baseline validée 2026-10-16 avec les clients officiels : les 8 tests de la matrice passent.
- [x] Phase 3 — fork + rebranding + serveur préconfiguré (voir section Fork). Non compilé localement : vérification = build CI en Phase 4.
- [x] Phase 4 — CI verte le 2026-10-16 (run 38956935021, ~48 min à froid) : prerelease `dev` sur GitHub avec `GD-Remote-1.5.0-x86_64.exe` (25,8 Mo, non signé, à signer via `res/gd-remote-sign.ps1`) et `GD-Remote-1.5.0-aarch64-signed.apk` (28,7 Mo, signé CN=GD Remote, package `solutions.gd.remote`). Défaut corrigé ensuite : les propriétés de fichier de l'installeur venaient de `libs/portable/Cargo.toml` (winres) et disaient encore « RustDesk » → remplacées (build 2 relancé). **À valider par gducos** : installation Windows (nom, icône, serveur/clé préremplis, connexion au parc), APK Android (installation, nom, connexion).
- [x] Phase 5 — serveur `-k _` + logs, mot de passe 12 car., script de rotation, verrou serveur/clé. Build 3 vert (run 38967136200, commit 3ae214afb) publié sur `dev` le 2026-10-16 21:46 UTC. **À valider par gducos** : Paramètres › Réseau grisés avec relay.gd.solutions + clé, refus d'un mot de passe permanent < 12 caractères, connexion parc OK, puis signature SimplySign de l'exe.

## Restes (hors périmètre livré)

- Signer aussi les exe/dll internes (aujourd'hui seul l'installeur est signé) : signer le dossier `rustdesk-unsigned-windows-x86_64` puis rebuild du packer en local.
- MSI pour déploiement GPO : `res/msi/preprocess.py` suppose « RustDesk », à adapter.
- Android armv7 / x86_64 si un terminal ancien l'exige (matrice CI).
- Montée de version upstream : `git fetch` upstream, rebase de `gd-remote` sur le nouveau tag, vérifier `apply_fork_defaults`, `Runner.rc`, `libs/portable/Cargo.toml`, workflows ; tag `gd-x.y.z` pour une release.
- Sauvegarde hors VPS de `/opt/rustdesk-server/data/id_ed25519*` et `/opt/rustdesk-secrets/` : toujours à faire.

## Phase 2 — matrice de test (clients officiels, Paramètres › Réseau)

ID Server = `relay.gd.solutions` · Relay Server = vide · Key = clé ci-dessus.

| # | Test | Résultat |
|---|---|---|
| 1 | `nc -vz relay.gd.solutions 21115..21119` depuis l'extérieur | |
| 2 | Windows A → Windows B, mot de passe permanent, sans clic sur B | |
| 3 | Surveillé : écran d'acceptation sur B, refus puis accept | |
| 4 | Presse-papier A→B et B→A | |
| 5 | Android → Windows | |
| 6 | Windows → Android (MediaProjection) | |
| 7 | iOS → Windows (client officiel) | |
| 8 | Relais forcé (deux NAT stricts, ou « toujours relayer » côté client) | |
