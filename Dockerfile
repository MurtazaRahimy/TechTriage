# ---------------------------------------------------------------------------
# TechTriage - Level 1 PLACEHOLDER image
#
# This tiny nginx image stands in for the real Flask app until Level 3.
# It shows:
#   /          - a page with the environment name and the commit ID
#   /version   - the same info as JSON (the real app will keep this endpoint)
#   /health    - returns "ok" with HTTP 200 (the real app will keep this too)
#
# The commit ID is baked in at build time (GIT_SHA build argument), so the
# image is the same in every environment. The environment name (APP_ENV) is
# supplied at run time by each server, as planned in the Project Brief.
#
# Level 3 replaces this whole file with the Flask + Gunicorn Dockerfile.
# ---------------------------------------------------------------------------
FROM nginx:1.27-alpine

ARG GIT_SHA=unknown
ENV APP_VERSION=${GIT_SHA} \
    APP_ENV=unset

# Scripts in /docker-entrypoint.d/ run automatically before nginx starts.
COPY placeholder/40-render-page.sh /docker-entrypoint.d/40-render-page.sh
COPY placeholder/default.conf /etc/nginx/conf.d/default.conf
RUN chmod +x /docker-entrypoint.d/40-render-page.sh

EXPOSE 80
