FROM alpine:3.23.2

# Define redis and smtp-cli details
ARG REDIS_VERSION="7.4.1"
ARG REDIS_URL="http://download.redis.io/releases/redis-${REDIS_VERSION}.tar.gz"
ARG SMTP_CLI_VERSION="v3.10"
ARG SMTP_CLI_URL="https://github.com/mludvig/smtp-cli/archive/refs/tags/${SMTP_CLI_VERSION}.tar.gz"
ARG PERL_MODULES="IO::Socket::SSL Net::SSLeay IO::Socket::INET6 Socket6 Digest::HMAC Term::ReadKey MIME::Lite File::LibMagic Digest::HMAC_MD5 Net::DNS"

# Create a non-root user with specific UID (1001)
RUN addgroup -S appgroup && adduser -S -u 1001 -G appgroup appuser

# Install build and runtime dependencies
RUN apk add --no-cache \
    gcc \
    make \
    linux-headers \
    musl-dev \
    tar \
    openssl-dev \
    pkgconfig \
    perl-dev \
    file-dev \
    zlib-dev \
    bind-tools \
    curl \
    mysql-client \
    nmap-ncat \
    iptables \
    perl \
    tcpdump \
    traceroute \
    wget \
    libmagic \
    openssl

# Install cpanminus for installing Perl modules
RUN curl -L https://cpanmin.us | perl - App::cpanminus

# Install Perl modules
RUN cpanm --notest ${PERL_MODULES}

# Install redis-cli
RUN wget -O redis.tar.gz "${REDIS_URL}" \
  && mkdir -p /usr/src/redis \
  && tar -xzf redis.tar.gz -C /usr/src/redis --strip-components=1 \
  && cd /usr/src/redis/src \
  && make BUILD_TLS=yes MALLOC=libc redis-cli \
  && cp redis-cli /usr/local/bin/ \
  && chmod +x /usr/local/bin/redis-cli \
  && rm -rf /usr/src/redis

# Install smtp-cli
RUN wget -O smtp-cli.tar.gz "${SMTP_CLI_URL}" \
  && mkdir -p /usr/src/smtp-cli \
  && tar -xzf smtp-cli.tar.gz -C /usr/src/smtp-cli --strip-components=1 \
  && cd /usr/src/smtp-cli/ \
  && cp smtp-cli /usr/local/bin/ \
  && chmod +x /usr/local/bin/smtp-cli \
  && rm -rf /usr/src/smtp-cli

# Change ownership of binaries to the non-root user
RUN chown appuser:appgroup /usr/local/bin/redis-cli /usr/local/bin/smtp-cli

# Clean up
RUN apk del \
    gcc \
    make \
    linux-headers \
    musl-dev \
    openssl-dev \
    pkgconfig \
    perl-dev \
    file-dev \
    zlib-dev \
  && rm -rf /root/.cpanm /var/cache/apk/*

# Switch to the non-root user
USER 1001
