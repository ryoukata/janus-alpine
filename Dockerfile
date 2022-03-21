# FROM ubuntu:21.04
#==================================================
# Build Layer
FROM alpine:latest as build

LABEL description="Janus WebRTC by Alpine image" 

RUN apk --no-cache add --virtual=build-dependencies --upgrade \
		autoconf \
		automake \
		cmake \
		curl-dev \
		doxygen \
		fakeroot \
		ffmpeg-dev \
		fftw-dev \
		gengetopt \
		g++ \
		gcc \
		git \
		glib-dev \
		graphviz \
		gtk-doc \
		jansson-dev \
		jpeg-dev \
		libpng-dev \
		libtool \
		make \
		nodejs \
		nodejs-npm \
		mpg123-dev \
		libconfig-dev \
		libcurl \
		libogg-dev \
		libmicrohttpd-dev \
		libnice \
		libnice-dev \
		libwebsockets-dev \
		lua5.3-dev \
		openjpeg-dev \
		openssl-dev \
		opus-dev \
		pkgconf \
		python3-dev \
		sudo \
		supervisor \
		rust \
		zlib-dev

RUN git clone https://github.com/sctplab/usrsctp \
		&& cd usrsctp && ./bootstrap \
		&& ./configure CFLAGS="-Wno-error=cpp" --prefix=/usr/lib64 && make && sudo make install && rm -fr /usrsctp \
		&& cd ..

RUN wget https://github.com/cisco/libsrtp/archive/v2.3.0.tar.gz \
        && tar xfv v2.3.0.tar.gz  && cd libsrtp-2.3.0 \
        && ./configure --prefix=/usr --enable-openssl \
        && make shared_library && sudo make install && rm -fr /libsrtp-2.3.0 && rm -f /v2.3.0.tar.gz

RUN git clone --depth 1 https://github.com/meetecho/janus-gateway.git \
		&& cd janus-gateway \
		&& sh autogen.sh \
		&& ./configure \
		--prefix=/opt/janus \
		--disable-rabbitmq \
		--disable-mqtt \
		--enable-doc \
		--enable-post-processing \
		--enable-json-logger \
		--enable-javascript-common-js-module \
		--enable-javascript-es-module \
		--enable-javascript-umd-module \
		--enable-javascript-iife-module \
		&& make \
		&& make install \
		&& make configs

RUN sed -i s/'\tenabled = false'/'\tenabled = true'/ /opt/janus/etc/janus/janus.transport.pfunix.jcfg
RUN sed -i s/'#path = "\/path\/to\/ux-janusapi"'/'path = "\/tmp\/janus.sock"'/ /opt/janus/etc/janus/janus.transport.pfunix.jcfg
RUN sed -i s/'var server = gatewayCallbacks.server;'/'var server = \"http:\/\/\" + window.location.hostname + \":8088\/janus";'/ /opt/janus/share/janus/demos/janus.js

#==================================================
# Run Layer
FROM alpine:latest

RUN apk --no-cache add \
glib \
jansson \
libconfig \
libcurl \
libmicrohttpd \
libnice \
libogg \
libsrtp \
libwebsockets \
nodejs \
nodejs-npm \
opus 

COPY --from=build /opt/janus /opt/janus
VOLUME [ "/opt/janus/share/janus/demos" ]

ENTRYPOINT ["/opt/janus/bin/janus"]