FROM ubuntu:18.04 as builder

# Allows us to auto-discover the latest release from the repo
ARG REPO=Sudosups/NBX
ENV REPO=${REPO}

# BUILD_DATE and VCS_REF are immaterial, since this is a 2-stage build, but our build
# hook won't work unless we specify the args
ARG BUILD_DATE
ARG VCS_REF

# install build dependencies
# checkout the latest tag
# build and install
RUN apt-get update && \
    apt-get install -y \
      build-essential \
      curl \
      python-dev \
      gcc-8 \
      g++-8 \
      git \
      cmake \
      libboost-all-dev

RUN mkdir -p /home/sups/Development
RUN TAG=$(curl -L --silent "https://api.github.com/repos/$REPO/releases/latest" | grep -Po '"tag_name": "\K.*?(?=")') && \
    git clone --branch $TAG --single-branch https://github.com/$REPO /home/sups/Development/NBX && \
    cd /home/sups/Development/NBX && \
    mkdir build && \
    cd build && \
    cmake .. 

RUN  cd /home/sups/Development/NBX && make -j$(nproc)

FROM keymetrics/pm2:latest-stretch 

# 17120
# 17122

# Now we DO need these, for the auto-labeling of the image
ARG BUILD_DATE
ARG VCS_REF

# Good docker practice, plus we get microbadger badges
LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.vcs-url="https://github.com/funkypenguin/nibble-classic.git" \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.schema-version="2.2-r1"

RUN git clone https://github.com/turtlecoin/turtlecoind-ha.git /usr/local/turtlecoin-ha

COPY --from=builder /home/sups/Development/NBX/src/* /usr/local/turtlecoin-ha/

RUN mkdir -p /var/lib/turtlecoind && npm install \
	nonce \
	shelljs \
	node-pty \
	sha256 \
	socket.io \
	turtlecoin-rpc

WORKDIR /usr/local/turtlecoin-ha
CMD [ "pm2-runtime", "start", "service.js" ]
