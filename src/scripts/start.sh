#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
set -o xtrace

# python manage.py migrate
python manage.py compilemessages
python manage.py collectstatic --noinput --verbosity 0

python manage.py runserver 0.0.0.0:80
# gunicorn --timeout=1200 --workers=2 --bind :8000 dashboard.wsgi:application
