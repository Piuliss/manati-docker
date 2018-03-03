FROM ubuntu:14.04
MAINTAINER Raúl Benítez Netto <raulbeni@gmail.com> 

# OR, if you’re using a directory for your requirements, copy everything (comment out the above and uncomment this if so):
# ADD requirements /requirements


RUN apt-get update 
RUN apt-get upgrade -y
RUN apt-get install -y python python-pip python-dev libpq-dev postgresql postgresql-contrib
RUN apt-get install -y \
    python-setuptools \
    nginx \
    supervisor \
    sqlite3 && \
    pip install -U pip setuptools && \
    rm -rf /var/lib/apt/lists/*

RUN \
  sed -i 's/# \(.*multiverse$\)/\1/g' /etc/apt/sources.list && \
  apt-get update && \
  apt-get -y upgrade && \
  apt-get install -y build-essential && \
  apt-get install -y software-properties-common && \
  apt-get install -y byobu curl git htop man unzip vim wget && \
  rm -rf /var/lib/apt/lists/*




# Install Redis.
RUN \
  cd /tmp && \
  wget http://download.redis.io/redis-stable.tar.gz && \
  tar xvzf redis-stable.tar.gz && \
  cd redis-stable && \
  make && \
  make install && \
  cp -f src/redis-sentinel /usr/local/bin && \
  mkdir -p /etc/redis && \
  cp -f *.conf /etc/redis && \
  rm -rf /tmp/redis-stable* && \
  sed -i 's/^\(bind .*\)$/# \1/' /etc/redis/redis.conf && \
  sed -i 's/^\(daemonize .*\)$/# \1/' /etc/redis/redis.conf && \
  sed -i 's/^\(dir .*\)$/# \1\ndir \/data/' /etc/redis/redis.conf && \
  sed -i 's/^\(logfile .*\)$/# \1/' /etc/redis/redis.conf

# Define mountable directories.
VOLUME ["/data"]

# Define default command.
#CMD ["redis-server", "/etc/redis/redis.conf"]

RUN pip install -U pip
RUN pip install virtualenv
RUN virtualenv /venv
RUN mkdir /code/
## Copy your application code to the container (make sure you create a .dockerignore file if any large files or directories should be excluded)
WORKDIR /code/

RUN git clone https://github.com/stratosphereips/Manati.git .

## Copy in your requirements file
# Install build deps, then run `pip install`, then remove unneeded build deps all in a single step. Correct the path to your production requirements file, if needed.
RUN /venv/bin/pip install --no-cache-dir -r ./requirements/local.txt

WORKDIR /
## setup all the configfiles
RUN echo "daemon off;" >> /etc/nginx/nginx.conf
COPY manati_nginx.conf /etc/nginx/sites-available/default
COPY supervisor-manati-docker.conf /etc/supervisor/conf.d/
RUN update-rc.d supervisor defaults


ADD . /code/
USER root
RUN sed -e '90d' -i /etc/postgresql/9.3/main/pg_hba.conf && \
	sed -e '91d' -i /etc/postgresql/9.3/main/pg_hba.conf && \
	echo "host all all 0.0.0.0/0 trust" >> '/etc/postgresql/9.3/main/pg_hba.conf' && \
	echo "local all all trust" >> '/etc/postgresql/9.3/main/pg_hba.conf' && \
	sed -e "s/[#]\?listen_addresses = .*/listen_addresses = '*'/g" -i '/etc/postgresql/9.3/main/postgresql.conf'

RUN mkdir -p /var/run/postgresql && chown -R postgres /var/run/postgresql
VOLUME  ["/etc/postgresql", "/var/log/postgresql", "/var/lib/postgresql", "/var/lib/postgresql/data"]
WORKDIR /code/
VOLUME ["/code"]
# uWSGI will listen on this port
EXPOSE 8888
## Start supervisor, it will start nginx and uWSGI
CMD ["supervisord", "-n"]
ENTRYPOINT ["/code/docker-entrypoint.sh"]
# CMD ["bash"]