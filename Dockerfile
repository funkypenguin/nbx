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

FROM ubuntu:18.04 as release 

# Now we DO need these, for the auto-labeling of the image
ARG BUILD_DATE
ARG VCS_REF

# Good docker practice, plus we get microbadger badges
LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.vcs-url="https://github.com/funkypenguin/nbx.git" \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.schema-version="2.2-r1"


COPY --from=builder /home/sups/Development/NBX/src/nibble-service /usr/local/bin/
COPY --from=builder /home/sups/Development/NBX/src/Nibbled /usr/local/bin/

RUN mkdir /root/.NibbleClassic

EXPOSE 17120
EXPOSE 17122

VOLUME /root/.NibbleClassic

ENTRYPOINT ["/usr/local/bin/Nibbled"]
CMD ["--no-console","--rpc-bind-ip","0.0.0.0","--rpc-bind-port","17122","--p2p-bind-port","171220"]
