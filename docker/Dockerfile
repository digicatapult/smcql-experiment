FROM --platform=linux/amd64 postgres:12-bookworm

# Install basic tools
RUN apt update && apt -y upgrade
RUN apt -y install vim git-core make gnupg locales sudo wget tcpdump iproute2 net-tools iputils-ping sshpass postgresql postgresql-contrib curl netcat-openbsd

 # Set the locale
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=en_GB.utf8
ENV LCALL=en_GB.utf8
ENV LANGUAGE=en_GB.utf8
RUN sed -i 's/\# en_GB.UTF-8/en_GB.UTF-8/g' /etc/locale.gen
RUN echo "en_GB.UTF-8 UTF-8" >> /etc/default/locale
RUN locale-gen

# Add a dev user
RUN adduser --quiet --disabled-password --shell /bin/bash --home /home/smcql --gecos "SMCQL" smcql
RUN echo 'smcql ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers
RUN echo "smcql:smcql" | chpasswd

# Create the smcql user and give superuser permissions
RUN echo "CREATE USER smcql LOGIN PASSWORD 'smcql'; ALTER USER smcql WITH SUPERUSER;" > /srv/create_user.sql
RUN sudo pg_createcluster 16 main && sudo service postgresql start && sudo runuser - postgres -c "psql -f /srv/create_user.sql"

# Make sure the container listens on the appropriate IP addresses
RUN echo "host    all             all             0.0.0.0/0            scram-sha-256" | sudo tee -a /etc/postgresql/16/main/pg_hba.conf
RUN sed -i "60 i listen_addresses = '*'" /etc/postgresql/16/main/postgresql.conf

# Install Java
RUN mkdir -p /etc/apt/keyrings && \
    wget -O - https://packages.adoptium.net/artifactory/api/gpg/key/public | tee /etc/apt/keyrings/adoptium.asc && \
    echo "deb [signed-by=/etc/apt/keyrings/adoptium.asc] https://packages.adoptium.net/artifactory/deb bookworm main" | tee /etc/apt/sources.list.d/adoptium.list && \
    apt update && apt -y install temurin-8-jdk
RUN apt -y install maven
RUN apt -y remove openjdk-11-jre-headless

# Set up SMCQL
USER smcql

# Generate a weak SSH key for use in the SMCQL query execution
RUN ssh-keygen -m pem -t rsa -b 1024 -q -f "/home/smcql/.ssh/id_rsa" -N ""

# Allow any hosts to be accepted without verification
RUN bash -c 'echo -e "Host *\n    StrictHostKeyChecking accept-new\n\nLogLevel ERROR"' > /home/smcql/.ssh/config

# Copy the SMCQL repo into the container
COPY --chown=smcql:smcql ../dependencies/smcql /home/smcql/smcql

WORKDIR /home/smcql/smcql

RUN sudo service postgresql start && /home/smcql/smcql/setup.sh
