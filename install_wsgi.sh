#!/bin/bash
CWD="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $CWD/base.sh

set -e

#echo "Installing git and pip"
#apt-get install -y git python-pip

AMCAT_REPO=$AMCAT_ROOT/amcat
if [ ! -d "$AMCAT_REPO" ]; then
    echo "Cloning repository into $AMCAT_REPO"
    su $AMCAT_USER -c "git clone https://github.com/amcat/amcat.git  $AMCAT_REPO"
fi

echo "Installing amcat dependencies"
cat $AMCAT_REPO/apt_requirements.txt | tr '\n' ' ' | xargs apt-get install -y
pip --default-timeout=100 install -r $AMCAT_REPO/pip_requirements.txt --use-mirrors 

if [ "$AMCAT_DB_HOST" = "localhost" ]; then
    echo "Setting up database"
    apt-get install -y postgresql postgresql-contrib-9.1
    su postgres <<EOF
      set +e
      echo Create database $AMCAT_DB_NAME.
      createdb $AMCAT_DB_NAME
      echo Create  $AMCAT_DB_USER with password $AMCAT_DB_PASSWORD.
      psql $AMCAT_DB_NAME -c "create user $AMCAT_DB_USER password '$AMCAT_DB_PASSWORD';" 
      set -e
      psql -c 'CREATE EXTENSION IF NOT EXISTS "uuid-ossp";' amcat
EOF

    cd $AMCAT_REPO
    PYTHONPATH=. DJANGO_DB_HOST=localhost DJANGO_DB_NAME=$AMCAT_DB_NAME \
	DJANGO_DB_USER=$AMCAT_DB_USER DJANGO_DB_PASSWORD=$AMCAT_DB_PASSWORD \
	DJANGO_SETTINGS_MODULE=settings ./manage.py syncdb --noinput 
    PYTHONPATH=. DJANGO_DB_HOST=localhost DJANGO_DB_NAME=$AMCAT_DB_NAME \
	DJANGO_DB_USER=$AMCAT_DB_USER DJANGO_DB_PASSWORD=$AMCAT_DB_PASSWORD \
	DJANGO_SETTINGS_MODULE=settings ./manage.py collectstatic --noinput

fi

echo "Installing uwsgi"
pip install uwsgi

set +e
stop amcat_wsgi
set -e

SRC=$CWD/amcat_wsgi.conf-dist
TRG=/etc/init/amcat_wsgi.conf
echo "Checking upstart script at $TRG"
if [ ! -e $TRG ]; then
    echo "Creating upstart script $TRG from $SRC"
    sed -e "s#__AMCAT_ROOT__#$AMCAT_REPO#" \
	-e "s#__AMCAT_USER__#$AMCAT_USER#" \
	-e "s#__AMCAT_DB_HOST__#$AMCAT_DB_HOST#" \
	-e "s#__AMCAT_DB_USER__#$AMCAT_DB_USER#" \
	-e "s#__AMCAT_DB_NAME__#$AMCAT_DB_NAME#" \
	-e "s#__AMCAT_DB_PASSWORD__#$AMCAT_DB_PASSWORD#" \
	-e "s#__UWSGI_SOCKET__#$UWSGI_SOCKET#"  < $SRC > $TRG
    chmod 600 $TRG
fi
set +e
start amcat_wsgi
set -e

echo "Installing nginx"
apt-get install -y nginx

SRC=$CWD/nginx-amcat.conf-dist
TRG=/etc/nginx/sites-available/amcat.conf
echo "Checking nginx site at $TRG"
if [ ! -e $TRG ]; then
    echo "Creating upstart script $TRG from $SRC"
    sed -e "s#__SERVER_NAME__#$SERVER_NAME#" \
        -e "s#__AMCAT_REPO__#$AMCAT_REPO#" \
        -e "s#__NGINX_UWSGI_SOCKET__#$NGINX_UWSGI_SOCKET#"  < $SRC > $TRG
fi
LN=/etc/nginx/sites-enabled/amcat.conf
if [ ! -e $LN ]; then
    echo "Linking $LN -> $TRG"
    ln -s $TRG $LN
fi

set +e
/etc/init.d/nginx restart
set -e


echo "Configuring and starting celery workers"
set +e
stop amcat_celery
set -e

SRC=$CWD/amcat_celery.conf-dist
TRG=/etc/init/amcat_celery.conf
echo "Checking upstart script at $TRG"
if [ ! -e $TRG ]; then
    echo "Creating upstart script $TRG from $SRC"
    sed -e "s#__AMCAT_ROOT__#$AMCAT_REPO#" \
        -e "s#__AMCAT_USER__#$AMCAT_USER#" \
        -e "s#__AMCAT_DB_HOST__#$AMCAT_DB_HOST#" \
        -e "s#__AMCAT_DB_USER__#$AMCAT_DB_USER#" \
        -e "s#__AMCAT_DB_NAME__#$AMCAT_DB_NAME#" \
        -e "s#__AMCAT_DB_PASSWORD__#$AMCAT_DB_PASSWORD#" < $SRC > $TRG
    chmod 600 $TRG
fi
set +e
start amcat_celery
set -e

