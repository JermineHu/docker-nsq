FROM alpine:3.6
MAINTAINER Jermine <Jermine.hu@qq.com>
ENV GOLANG_VERSION 1.9

ENV GOPATH /go
ENV PATH $GOPATH/bin:/usr/local/go/bin:$PATH

RUN mkdir -p "$GOPATH/src" "$GOPATH/bin" && chmod -R 777 "$GOPATH"
WORKDIR $GOPATH

EXPOSE 4150 4151 4160 4161 4170 4171

VOLUME /data
VOLUME /etc/ssl/certs

COPY build.sh /build.sh
RUN set -eux; \
	apk add --no-cache --virtual .build-deps \
	   ca-certificates \
	    git \
		make \
		bash \
		gcc \
		musl-dev \
		openssl \
		go ; \
	    export \
# set GOROOT_BOOTSTRAP such that we can actually build Go
		GOROOT_BOOTSTRAP="$(go env GOROOT)" \
# ... and set "cross-building" related vars to the installed system's values so that we create a build targeting the proper arch
# (for example, if our build host is GOARCH=amd64, but our build env/image is GOARCH=386, our build needs GOARCH=386)
		GOOS="$(go env GOOS)" \
		GOARCH="$(go env GOARCH)" \
		GO386="$(go env GO386)" \
		GOARM="$(go env GOARM)" \
		GOHOSTOS="$(go env GOHOSTOS)" \
		GOHOSTARCH="$(go env GOHOSTARCH)" ; \
	wget -O go.tgz "https://golang.org/dl/go$GOLANG_VERSION.src.tar.gz"; \
	echo 'a4ab229028ed167ba1986825751463605264e44868362ca8e7accc8be057e993 *go.tgz' | sha256sum -c -; \
	tar -C /usr/local -xzf go.tgz; \
	rm go.tgz; \
	cd /usr/local/go/src; \
	for p in /go-alpine-patches/*.patch; do \
		[ -f "$p" ] || continue; \
		patch -p2 -i "$p"; \
	done; \
	./make.bash; \
	rm -rf /go-alpine-patches; \
	export PATH="/usr/local/go/bin:$PATH"; \
	go version ;\

wget https://raw.githubusercontent.com/pote/gpm/v1.4.0/bin/gpm && chmod +x gpm && mv gpm /usr/local/bin ;\

go get github.com/nsqio/nsq/... ; \
    cd /go/src/github.com/nsqio/nsq ; \
    gpm install ; \
    pwd ;\
    ls -alh ;\
    mv /build.sh . ;\
    bash build.sh ;\
     ls -alh /usr/local/bin ;\
      pwd ;\
    ls -alh ;\
   ln -s /usr/local/bin/*nsq* / ;\
  ln -s /usr/local/bin/*nsq* /bin/ ;\
  ls /usr/local/bin -alh ; \
  make clean ; \
	rm -r /var/cache/apk ; \
	rm -r /usr/share/man ; \
	rm -rf /go /usr/local/go ;\
   apk del .build-deps

