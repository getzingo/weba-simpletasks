FROM debian:bookworm-slim

ENV PORT=3000

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl \
    ca-certificates procps python3 build-essential \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd -r simpleuser && useradd -r -g simpleuser -m -s /bin/bash simpleuser

WORKDIR /app

COPY --chown=simpleuser:simpleuser . .

RUN chown -R simpleuser:simpleuser /app

USER simpleuser

RUN curl https://install.meteor.com/ | sh

RUN /home/simpleuser/.meteor/meteor npm install --server-only



EXPOSE 3000

CMD ["/home/simpleuser/.meteor/meteor"]

