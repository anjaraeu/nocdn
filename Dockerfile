FROM nginx:mainline-alpine

RUN apk -U add git \
        && cd /usr/share/nginx \
        && git clone https://github.com/nsaovh/nocdn \
        && git clone https://github.com/nsaovh/public nocdn/public \
        && sed -i "s|\/html|\/nocdn/public|" /etc/nginx/conf.d/default.conf

EXPOSE 80
