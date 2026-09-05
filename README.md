# Pronostics Ligue des Champions — Arena

Système de pronostics match par match, pensé pour faire revenir les gens
physiquement à l'Arena chaque soirée de Ligue des Champions : QR code
affiché uniquement le soir même, classement de la soirée (petit lot,
ex: une bière) + classement cumulé de la saison (lot final).

## Les fichiers

- `public/admin.html` — page **staff uniquement**. Créer une soirée,
  importer les matchs, générer le QR code à afficher, saisir/actualiser les
  résultats.
- `public/pronostics.html` — page **joueurs**. C'est elle que le QR code
  cible.
- `public/classement.html` — écran à projeter dans l'Arena (classement du
  soir + classement saison), s'actualise tout seul toutes les 20 secondes.
- `public/config.js` — **généré automatiquement par Vercel** à chaque
  déploiement (voir `build-config.js`) à partir des variables d'environnement
  ci-dessous. Ne pas l'éditer ni le committer (il est dans `.gitignore`).
- `config.example.js` — juste une référence pour voir à quoi ressemble le
  fichier généré, ne sert à rien en pratique.

## Mise en place (une seule fois)

### 1. Créer le projet Supabase

1. Va sur [supabase.com](https://supabase.com), crée un compte si besoin.
2. Crée un **nouveau projet** (gratuit).
3. Une fois créé, va dans l'onglet **SQL Editor** (menu de gauche).
4. Ouvre le fichier `supabase/schema.sql` de ce dossier, copie tout son
   contenu, colle-le dans l'éditeur SQL, puis clique **Run**.
5. Va dans **Project Settings > API**. Note :
   - le **Project URL**
   - la clé **anon public / publishable**

### 2. Créer une clé football-data.org (résultats automatiques)

1. Va sur [football-data.org](https://www.football-data.org/client/register),
   crée un compte gratuit.
2. Une fois connecté, récupère ta clé API (**X-Auth-Token**) dans ton espace
   client.
3. Le plan gratuit couvre la Ligue des Champions et suffit largement pour cet
   usage (limite ~10 requêtes/minute).

### 3. Déployer sur Vercel

1. Va sur [vercel.com](https://vercel.com), connecte-toi avec ton compte
   GitHub.
2. **Add New... > Project**, choisis le dépôt `LDC-Prono`.
3. Vercel détecte automatiquement `vercel.json` (build + dossier `public/`).
   Avant de cliquer Deploy, ouvre la section **Environment Variables** et
   ajoute ces 5 lignes (nom exact à gauche, ta valeur à droite) :

   | Nom | Valeur |
   |---|---|
   | `SUPABASE_URL` | `https://xxxxx.supabase.co` |
   | `SUPABASE_ANON_KEY` | ta clé anon/publishable Supabase |
   | `FOOTBALL_DATA_API_KEY` | ta clé football-data.org |
   | `COMPETITION_CODE` | `CL` |
   | `SITE_BASE_URL` | laisse temporairement `https://a-completer.vercel.app/` |

4. Clique **Deploy**. Une fois le déploiement terminé, Vercel t'attribue une
   adresse du style `https://ldc-prono.vercel.app`.
5. Retourne dans **Project Settings > Environment Variables**, corrige
   `SITE_BASE_URL` avec cette vraie adresse (avec un `/` à la fin), puis
   relance un déploiement (**Deployments > ⋯ > Redeploy**).

C'est tout : à chaque fois que je pousserai une modification sur la branche,
Vercel redéploiera automatiquement.

## Utilisation le soir d'un match

1. Ouvre `admin.html`, choisis la date de la soirée, clique **Créer la
   soirée et importer les matchs** (les matchs de la Ligue des Champions de
   ce jour sont importés automatiquement).
2. Le QR code apparaît sous la soirée créée. Affiche-le sur l'écran de
   l'Arena (capture d'écran ou vidéoprojection de la page).
3. Les clients scannent le QR, entrent pseudo + téléphone, pronostiquent les
   scores. Un pronostic se ferme automatiquement dès le coup d'envoi du
   match concerné.
4. Affiche `classement.html` sur un écran (ou en alternance) pour créer de
   l'émulation pendant la soirée.
5. Après les matchs, retourne sur `admin.html` et clique **Actualiser les
   résultats depuis l'API** : les scores finaux sont récupérés, les points
   sont calculés automatiquement. Tu peux aussi saisir un score à la main si
   l'API n'a pas encore mis à jour un match.
6. Annonce le gagnant de la soirée depuis `classement.html`. Le classement
   saison continue de cumuler d'une soirée à l'autre (identifié par numéro
   de téléphone).

## Barème de points (modifiable dans `supabase/schema.sql`)

- Score exact : **5 points**
- Bonne différence de buts (mais pas le score exact) : **3 points**
- Bon vainqueur ou bon match nul (mais pas la différence) : **1 point**
- Faux pronostic : **0 point**

## Limites connues (choix assumés pour une V1 simple)

- **Pas de vrai compte / mot de passe** pour les joueurs : n'importe qui
  avec le lien exact peut jouer. Le fait que le QR ne soit affiché qu'à
  l'Arena, et remplacé à chaque soirée, suffit à dissuader le jeu à
  distance pour cette V1.
- **`admin.html` n'a pas de mot de passe non plus** : traite son lien comme
  une info interne, ne le partage pas publiquement.
- La clé `FOOTBALL_DATA_API_KEY` reste visible dans `public/config.js` une
  fois le site déployé (nécessaire pour appeler l'API directement depuis le
  navigateur) — elle n'est juste plus stockée dans l'historique GitHub grâce
  aux variables d'environnement Vercel. C'est sans risque réel ici (clé
  gratuite, pas de données sensibles) tant que le lien admin reste privé.

Si un jour tu veux muscler la sécurité (vrai login, clé API cachée
côté serveur), on pourra faire évoluer ça avec des fonctions Supabase — mais
pas nécessaire pour démarrer.
