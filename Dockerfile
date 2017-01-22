#
# Starting Scala Environment
# 54chi
# https://github.com/54chi/discodock
#

# Java 8, Scala, sbt (for play), Git, Postgres Postgres/postgres, Redis

# Pull base image (includes bzip, unzip, xz-utils, java debian 8u111-b14, sets $JAVA_HOME)
FROM  openjdk:8

ENV SCALA_VERSION 2.12.1
ENV SBT_VERSION 0.13.13
ENV GOSU_VERSION 1.7
ENV PG_MAJOR 9.6
ENV PG_VERSION 9.6.1-2.pgdg80+1

# Install gosu for easy step-down from root
RUN set -x \
	&& apt-get update && apt-get install -y --no-install-recommends ca-certificates wget && rm -rf /var/lib/apt/lists/* \
	&& wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture)" \
	&& wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture).asc" \
	&& export GNUPGHOME="$(mktemp -d)" \
	&& gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
	&& gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
	&& rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc \
	&& chmod +x /usr/local/bin/gosu \
	&& gosu nobody true

# Install POSTGRES
# The apt-get method is still at 9.4...may be a reason for that
  RUN groupadd -r postgres --gid=999 && useradd -r -g postgres --uid=999 postgres

  RUN apt-get update && apt-get install -y locales && rm -rf /var/lib/apt/lists/* \
  	&& localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
  ENV LANG en_US.utf8

  RUN set -ex; \
  # pub   4096R/ACCC4CF8 2011-10-13 [expires: 2019-07-02]
  #       Key fingerprint = B97B 0AFC AA1A 47F0 44F2  44A0 7FCC 7D46 ACCC 4CF8
  # uid                  PostgreSQL Debian Repository
  	key='B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8'; \
  	export GNUPGHOME="$(mktemp -d)"; \
  	gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key"; \
  	gpg --export "$key" > /etc/apt/trusted.gpg.d/postgres.gpg; \
  	rm -r "$GNUPGHOME"; \
  	apt-key list

  RUN echo 'deb http://apt.postgresql.org/pub/repos/apt/ jessie-pgdg main' $PG_MAJOR > /etc/apt/sources.list.d/pgdg.list

  RUN apt-get update \
  	&& apt-get install -y postgresql-common \
  	&& sed -ri 's/#(create_main_cluster) .*$/\1 = false/' /etc/postgresql-common/createcluster.conf \
  	&& apt-get install -y \
  		postgresql-$PG_MAJOR=$PG_VERSION \
  		postgresql-contrib-$PG_MAJOR=$PG_VERSION \
  	&& rm -rf /var/lib/apt/lists/*

  # make the sample config easier to munge (and "correct by default")
  RUN mv -v /usr/share/postgresql/$PG_MAJOR/postgresql.conf.sample /usr/share/postgresql/ \
  	&& ln -sv ../postgresql.conf.sample /usr/share/postgresql/$PG_MAJOR/ \
  	&& sed -ri "s!^#?(listen_addresses)\s*=\s*\S+.*!\1 = '*'!" /usr/share/postgresql/postgresql.conf.sample

  RUN mkdir -p /var/run/postgresql && chown -R postgres:postgres /var/run/postgresql && chmod g+s /var/run/postgresql

  ENV PATH /usr/lib/postgresql/$PG_MAJOR/bin:$PATH
  ENV PGDATA /var/lib/postgresql/data
  RUN mkdir -p "$PGDATA" && chown -R postgres:postgres "$PGDATA" && chmod 777 "$PGDATA" # this 777 will be replaced by 700 at runtime (allows semi-arbitrary "--user" values)
  VOLUME /var/lib/postgresql/data

# Install GIT
  RUN apt-get update && apt-get -y install git

# Install REDIS Stable
  RUN apt-get update && apt-get install -y redis-server

# Install SCALA
# Alternative method: https://gist.github.com/osipov/c2a34884a647c29765ed
  RUN touch /usr/lib/jvm/java-8-openjdk-amd64/release
  RUN \
    curl -fsL http://downloads.lightbend.com/scala/$SCALA_VERSION/scala-$SCALA_VERSION.tgz | tar xfz - -C /root/ && \
    echo >> /root/.bashrc && \
    echo 'export PATH=~/scala-$SCALA_VERSION/bin:$PATH' >> /root/.bashrc

# Install SBT
  RUN \
    curl -L -o sbt-$SBT_VERSION.deb http://dl.bintray.com/sbt/debian/sbt-$SBT_VERSION.deb && \
    dpkg -i sbt-$SBT_VERSION.deb && \
    rm sbt-$SBT_VERSION.deb && \
    apt-get update && \
    apt-get install sbt && \
    sbt sbtVersion && \
    apt-get purge -y --auto-remove ca-certificates wget

# Finishing Configuration
  # Define mountable directories.
  VOLUME ["/data"]

  # Define working directory
  WORKDIR /root

  ENTRYPOINT  ["/usr/bin/redis-server"]

  # Define default command.
  CMD ["redis-server", "/etc/redis/redis.conf"]

  # Expose ports (6379 redis, 5432 postgres).
  EXPOSE 6379 5432
  CMD ["postgres"]
