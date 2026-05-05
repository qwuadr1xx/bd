FROM postgres:16-bookworm

RUN apt-get update && apt-get install -y --no-install-recommends \
    postgresql-plpython3-16 \
    postgresql-plperl-16 \
    postgresql-server-dev-16 \
    gcc \
    make \
    && rm -rf /var/lib/apt/lists/*
