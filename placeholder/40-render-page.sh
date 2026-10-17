#!/bin/sh
# Builds the placeholder page from APP_ENV and APP_VERSION when the
# container starts. Runs automatically via nginx's /docker-entrypoint.d/.
set -eu

HTML_DIR="${HTML_DIR:-/usr/share/nginx/html}"
APP_ENV="${APP_ENV:-unset}"
APP_VERSION="${APP_VERSION:-unknown}"
SHORT_SHA=$(printf '%s' "$APP_VERSION" | cut -c1-7)
STARTED_AT=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Keep the value safe for HTML/JSON (environment names are simple words).
case "$APP_ENV" in
  *[!A-Za-z0-9_-]*) APP_ENV="invalid" ;;
esac
case "$APP_VERSION" in
  *[!A-Za-z0-9._-]*) APP_VERSION="invalid"; SHORT_SHA="invalid" ;;
esac

# One colour per environment, so the four pages are easy to tell apart.
case "$APP_ENV" in
  development) COLOUR="#2563eb" ;;
  testing)     COLOUR="#9333ea" ;;
  staging)     COLOUR="#d97706" ;;
  production)  COLOUR="#16a34a" ;;
  *)           COLOUR="#6b7280" ;;
esac

cat > "$HTML_DIR/index.html" <<EOF
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>TechTriage - ${APP_ENV}</title>
  <style>
    body { font-family: system-ui, sans-serif; margin: 0; background: #f8fafc; color: #0f172a; }
    header { background: ${COLOUR}; color: #fff; padding: 24px 16px; }
    header h1 { margin: 0; font-size: 1.6rem; }
    main { max-width: 640px; margin: 24px auto; padding: 0 16px; }
    table { border-collapse: collapse; width: 100%; background: #fff; }
    td { border: 1px solid #e2e8f0; padding: 10px; }
    td:first-child { font-weight: 600; width: 40%; }
    code { word-break: break-all; }
  </style>
</head>
<body>
  <header>
    <h1>TechTriage &mdash; ${APP_ENV}</h1>
    <p>Level 1 pipeline placeholder</p>
  </header>
  <main>
    <table>
      <tr><td>Environment</td><td>${APP_ENV}</td></tr>
      <tr><td>Commit (short)</td><td><code>${SHORT_SHA}</code></td></tr>
      <tr><td>Commit (full)</td><td><code>${APP_VERSION}</code></td></tr>
      <tr><td>Container started (UTC)</td><td>${STARTED_AT}</td></tr>
    </table>
    <p>Pipeline: GitHub &rarr; GitHub Actions &rarr; GHCR &rarr; EC2</p>
  </main>
</body>
</html>
EOF

cat > "$HTML_DIR/version.json" <<EOF
{"app":"techtriage","environment":"${APP_ENV}","version":"${APP_VERSION}","started_at":"${STARTED_AT}"}
EOF

echo "techtriage placeholder: env=${APP_ENV} version=${APP_VERSION}"
