FROM ubuntu:bionic AS opkg-builder

ENV \
    ZLIB_BINARY=zlib-1.2.11 \
    LIBARCHIVE_BINARY=libarchive-3.4.0 \
    OPENSSL_BINARY=openssl-1.1.1c \
    CURL_BINARY=curl-7.65.3 \
    LIBASSUAN_BINARY=libassuan-2.5.3 \
    LIBGPGERROR_BINARY=libgpg-error-1.36 \
    GPGME_BINARY=gpgme-1.13.1 \
    OPKG_BINARY=opkg-0.4.1 \
    GLIBC_BINARY=glibc-2.29 \
    MAKE_BINARY=make-4.2

RUN \
    apt-get update -qq -o=Dpkg::Use-Pty=0 && \
    apt-get install -qq -o=Dpkg::Use-Pty=0 -y wget gcc libtool autoconf pkg-config libtool-bin bison python3 gawk

RUN \
    wget https://www.zlib.net/${ZLIB_BINARY}.tar.gz  && \
    tar -zxf ${ZLIB_BINARY}.tar.gz
RUN \
    cd ${ZLIB_BINARY} && \
    ./configure --prefix=/usr && \
    make --silent && \
    export DESTDIR="/zlib" && \
    make install && \
    ls -lR /zlib && \
    cp -R /zlib/usr/* /usr/

RUN \
    wget https://github.com/libarchive/libarchive/releases/download/v3.4.0/${LIBARCHIVE_BINARY}.tar.gz  && \
    tar -zxf ${LIBARCHIVE_BINARY}.tar.gz
RUN \
    cd ${LIBARCHIVE_BINARY} && \
    ./configure --prefix=/usr && \
    make --silent  && \
    export DESTDIR="/libarchive" && \
    make install-exec && \
    ls -lR /libarchive && \
    cp -R /libarchive/usr/* /usr/

RUN \
    wget https://www.openssl.org/source/${OPENSSL_BINARY}.tar.gz  && \
    tar -zxf ${OPENSSL_BINARY}.tar.gz
RUN \
    cd ${OPENSSL_BINARY} && \
    ./config --prefix=/usr && \
    make --silent  && \
    make DESTDIR=/openssl install && \
    ls -lR /openssl && \
    cp -R /openssl/usr/* /usr/

RUN \
    wget https://curl.haxx.se/download/${CURL_BINARY}.tar.gz  && \
    tar -zxf ${CURL_BINARY}.tar.gz
RUN \
    cd ${CURL_BINARY} && \
    ./configure --prefix=/usr && \
    make --silent  && \
    export DESTDIR="/curl" && \
    make install-exec && \
    ls -lR /curl && \
    cp -R /curl/usr/* /usr/

RUN \
    wget https://gnupg.org/ftp/gcrypt/libgpg-error/${LIBGPGERROR_BINARY}.tar.bz2 && \
    tar -jxf ${LIBGPGERROR_BINARY}.tar.bz2
RUN \
    cd ${LIBGPGERROR_BINARY} && \
    ./configure --prefix=/usr && \
    make --silent  && \
    export DESTDIR="/libgpg-error" && \
    make install-exec && \
    ls -lR /libgpg-error && \
    cp -R /libgpg-error/usr/* /usr/

RUN \
    wget https://gnupg.org/ftp/gcrypt/libassuan/${LIBASSUAN_BINARY}.tar.bz2 && \
    tar -jxf ${LIBASSUAN_BINARY}.tar.bz2
RUN \
    cd ${LIBASSUAN_BINARY} && \
    ./configure --prefix=/usr && \
    make --silent  && \
    export DESTDIR="/libassuan" && \
    make install-exec && \
    ls -lR /libassuan && \
    cp -R /libassuan/usr/* /usr/

RUN \
    wget https://gnupg.org/ftp/gcrypt/gpgme/${GPGME_BINARY}.tar.bz2 && \
    tar -jxf ${GPGME_BINARY}.tar.bz2
RUN \
    cd ${GPGME_BINARY} && \
    ./configure --prefix=/usr && \
    make --silent  && \
    export DESTDIR="/gpgme" && \
    make install-exec && \
    ls -lR /gpgme && \
    cp -R /gpgme/usr/* /usr/

RUN \
    wget https://git.yoctoproject.org/cgit/cgit.cgi/opkg/snapshot/${OPKG_BINARY}.tar.gz  && \
    tar -zxf ${OPKG_BINARY}.tar.gz
RUN \
    cd ${OPKG_BINARY} && \
    ./autogen.sh && \
    ./configure --with-static-libopkg --disable-shared --enable-gpg --enable-curl --prefix=/usr && \
    make --silent  && \
    export DESTDIR="/opkg" && \
    make install-exec && \
    ls -lR /opkg

RUN \
    wget https://ftp.gnu.org/gnu/glibc/${GLIBC_BINARY}.tar.bz2 && \
    tar -jxf ${GLIBC_BINARY}.tar.bz2
RUN \
    mkdir glibc-build && \
    cd glibc-build && \
    ../${GLIBC_BINARY}/configure --prefix=/usr && \
    make --silent  && \
    export DESTDIR="/glibc" && \
    make install-exec && \
    ls -lR /glibc

COPY make-4.2.1.patch .
RUN \
    wget https://ftp.gnu.org/gnu/make/${MAKE_BINARY}.tar.bz2 && \
    tar -jxf ${MAKE_BINARY}.tar.bz2
RUN \
    patch -p0 < ../make-4.2.1.patch && \
    cd ${MAKE_BINARY} && \
    ./configure --prefix=/usr && \
    make --silent  && \
    export DESTDIR="/make" && \
    make install-exec && \
    ls -lR /make

FROM busybox:glibc

COPY --from=opkg-builder /zlib /
COPY --from=opkg-builder /libarchive /
COPY --from=opkg-builder /openssl /
COPY --from=opkg-builder /curl /
COPY --from=opkg-builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=opkg-builder /libassuan /
COPY --from=opkg-builder /libgpg-error /
COPY --from=opkg-builder /gpgme /
COPY --from=opkg-builder /opkg /
COPY --from=opkg-builder /glibc/ /
COPY --from=opkg-builder /make/ /

COPY opkg/ /

ENV LD_LIBRARY_PATH=/usr/lib:/lib64:/usr/lib64
