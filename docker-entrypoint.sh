#!/bin/sh

set -e
/etc/init.d/postgresql restart
pg_isready -h localhost -p 5432
export PGPASSWORD=postgres;

cd /code
file=/code/.env
if [ ! -e "$file" ]; then
    echo ".env does not exits"
    cp /code/.env.example /code/.env
    sed -i 's/config.settings.local/config.settings.test/g' /code/.env
    sed -i 's/DJANGO_DEBUG=True/DJANGO_DEBUG=False/g' /code/.env
    sed -i 's/DJANGO_ALLOWED_HOSTS=.manatiproject.com/DJANGO_ALLOWED_HOSTS=*/g' /code/.env
fi

export $(cat /code/.env | grep -v ^# | xargs);
echo $DJANGO_SETTINGS_MODULE
# updating DB
if [ "$( psql -U postgres -h localhost  -tAc "SELECT 1 FROM pg_roles WHERE rolname='manati_db_user'" )" = '1' ]
then
	/venv/bin/python ./manage.py makemigrations guardian  --noinput
	/venv/bin/python ./manage.py migrate  --noinput
	/venv/bin/python ./manage.py check_external_modules
	/venv/bin/python ./manage.py collectstatic --noinput

else
    psql -U postgres -h localhost -c "create user manati_db_user with password 'password';"
	psql -U postgres -h localhost -c "create database manati_db;"
	psql -U postgres -h localhost -d manati_db -c "grant all privileges on database manati_db to manati_db_user; alter role manati_db_user createrole createdb"
	/venv/bin/python ./manage.py makemigrations guardian  --noinput
	/venv/bin/python ./manage.py migrate  --noinput
	/venv/bin/python ./manage.py createsuperuser2 --username admin --password Password123 --noinput --email 'admin@manatiproject.com'
	/venv/bin/python ./manage.py check_external_modules
#	echo "from django.contrib.auth.models import User; User.objects.create_superuser('admin', 'admin@manati.com', 'password')" | /venv/bin/python manage.py shell
	/venv/bin/python ./manage.py collectstatic --noinput
fi

supervisord


exec "$@"