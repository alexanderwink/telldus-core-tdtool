FROM debian:buster as build
RUN apt-get update && apt-get install -y wget cmake build-essential libconfuse-dev libftdi-dev
RUN wget https://s3.eu-central-1.amazonaws.com/download.telldus.com/pool/main/t/telldus-core/telldus-core_2.1.3-beta1.orig.tar.gz
RUN tar xvf telldus-core_2.1.3-beta1.orig.tar.gz
WORKDIR telldus-core-2.1.3-beta1
RUN cmake .
RUN make
RUN make install
RUN ldconfig

FROM debian:buster
RUN apt-get update && apt-get install -y libconfuse-dev libftdi-dev
COPY --from=build /usr/local/sbin/telldusd /usr/local/sbin/telldusd
COPY --from=build /etc/tellstick.conf /etc/tellstick.conf
COPY --from=build /var/state/telldus-core.conf /var/state/telldus-core.conf
COPY --from=build /usr/local/lib/libtelldus-core.so.2.1.3 /usr/local/lib/libtelldus-core.so.2.1.3
COPY --from=build /usr/local/lib/libtelldus-core.so.2 /usr/local/lib/libtelldus-core.so.2
COPY --from=build /usr/local/lib/libtelldus-core.so /usr/local/lib/libtelldus-core.so
COPY --from=build /usr/local/include/telldus-core.h /usr/local/include/telldus-core.h
COPY --from=build /usr/local/bin/tdtool /usr/local/bin/tdtool
COPY --from=build /usr/local/sbin/tdadmin /usr/local/sbin/tdadmin
COPY --from=build /etc/udev/rules.d/05-tellstick.rules /etc/udev/rules.d/05-tellstick.rules
COPY --from=build /usr/local/share/telldus-core/helpers/udev.sh /usr/local/share/telldus-core/helpers/udev.sh
RUN ldconfig
ENTRYPOINT ["/usr/local/sbin/telldusd", "--nodaemon"]
