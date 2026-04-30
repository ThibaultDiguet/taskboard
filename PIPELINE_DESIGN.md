# Pipeline Design — Taskboard CI

## Plateforme choisie : GitHub Actions

Choix retenu car le code est déjà hébergé sur GitHub, ce qui donne accès gratuitement aux runners et à GHCR sans friction supplémentaire.

## Registry Docker : GitHub Container Registry (GHCR)

Choix retenu car :
- Intégré à GitHub, authentification via `GITHUB_TOKEN` (secret automatique, aucune configuration manuelle)
- Gratuit pour les dépôts publics
- Images liées au repo GitHub (visibilité, accès, suppression automatique possible)

Alternatives écartées :
- Docker Hub : nécessite un compte et un secret supplémentaire, quota de pulls en tier gratuit
- ECR/GCP : nécessite un compte cloud payant

## Déclencheurs

| Événement       | Jobs déclenchés        |
|-----------------|------------------------|
| `push` (toutes branches) | lint, test       |
| `push` sur `main`        | lint, test, build |
| `pull_request`           | lint, test       |

## Stages et jobs

```
lint ──► test ──► build (main seulement)
```

### Job `lint`
- Runner : `ubuntu-latest`
- Étapes : checkout, setup Node 20, cache npm, install, `npm run lint`
- Comportement : échoue et bloque la suite si ESLint détecte des violations

### Job `test`
- Runner : `ubuntu-latest`
- Dépend de : `lint`
- Étapes : checkout, setup Node 20, cache npm, install, `npm run test:coverage`
- Artefact publié : dossier `coverage/` (rapport de couverture)
- Services : aucun (les tests unitaires existants ne requièrent pas de base de données)

### Job `build`
- Runner : `ubuntu-latest`
- Dépend de : `test`
- Condition : `github.ref == 'refs/heads/main'`
- Étapes : checkout, login GHCR, setup BuildKit, cache Docker layers, build & push
- Image : `ghcr.io/thibaultdiguet/taskboard`
- Tags : `latest` + SHA court du commit (`sha-<7 chars>`)

## Cache

- **npm** : `actions/cache` sur `~/.npm` avec clé basée sur `package-lock.json`
- **Docker layers** : `cache-from` / `cache-to` via `type=gha` (GitHub Actions cache)

## Secrets nécessaires

| Secret | Valeur | Usage |
|--------|--------|-------|
| `GITHUB_TOKEN` | automatique | login GHCR + push image |

Aucun secret manuel à configurer pour cette étape.
