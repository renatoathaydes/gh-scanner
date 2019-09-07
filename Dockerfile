FROM google/dart AS dartc

WORKDIR /app

ADD pubspec.* /app/
RUN pub get
ADD bin/ /app/bin/
ADD lib/ /app/lib/
RUN pub get --offline
RUN dart2aot /app/bin/gh-scanner.dart /app/main.aot

FROM bitnami/minideb

COPY --from=dartc /app/main.aot /main.aot
COPY --from=dartc /usr/lib/dart/bin/dartaotruntime /dartaotruntime

CMD []
ENTRYPOINT ["/dartaotruntime", "/main.aot"]