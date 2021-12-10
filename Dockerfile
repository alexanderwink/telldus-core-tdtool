FROM alpine as build
RUN apk add --no-cache bash tzdata eudev ca-certificates
ENV LANG C.UTF-8
RUN apk add --no-cache \
      confuse libftdi1 libstdc++ jq socat \
  && apk add --no-cache --virtual .build-dependencies \
      cmake build-base gcc doxygen confuse-dev argp-standalone libftdi1-dev git \
  && ln -s /usr/include/libftdi1/ftdi.h /usr/include/ftdi.h \
  && mkdir -p /usr/src \
  && cd /usr/src \
  && git clone -b master --depth 1 https://github.com/telldus/telldus \
  && cd telldus/telldus-core \
  && sed -i "/\<sys\/socket.h\>/a \#include \<sys\/select.h\>" common/Socket_unix.cpp \
  && cmake . -DBUILD_LIBTELLDUS-CORE=ON -DBUILD_TDADMIN=OFF -DBUILD_TDTOOL=ON -DGENERATE_MAN=OFF -DFORCE_COMPILE_FROM_TRUNK=ON -DFTDI_LIBRARY=/usr/lib/libftdi1.so \
  && make \
  && make install

FROM alpine
RUN apk add --no-cache libstdc++
COPY --from=build /usr/local/sbin/telldusd /usr/local/sbin/telldusd
COPY --from=build /etc/tellstick.conf /etc/tellstick.conf
COPY --from=build /var/state/telldus-core.conf /var/state/telldus-core.conf
COPY --from=build /usr/local/lib/libtelldus-core.so.2.1.3 /usr/local/lib/libtelldus-core.so.2.1.3
COPY --from=build /usr/local/lib/libtelldus-core.so.2 /usr/local/lib/libtelldus-core.so.2
COPY --from=build /usr/local/lib/libtelldus-core.so /usr/local/lib/libtelldus-core.so
COPY --from=build /usr/local/include/telldus-core.h /usr/local/include/telldus-core.h
COPY --from=build /usr/local/bin/tdtool /usr/local/bin/tdtool
