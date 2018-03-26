FROM nginx:mainline-alpine

RUN apk -U add git \
        && git clone https://github.com/nsaovh/nocdn /usr/share/nginx/nocdn \
        && git clone https://github.com/nsaovh/public /usr/share/nginx/nocdn/public \
        && sed -i "s|\/html|\/nocdn/public|" /etc/nginx/conf.d/default.conf

EXPOSE 80
