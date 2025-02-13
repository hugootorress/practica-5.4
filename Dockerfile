FROM ubuntu:latest

RUN apt-get update \
    && apt-get install -y nginx git

RUN rm -rf /usr/share/nginx/html/* \
    && git clone https://github.com/josejuansanchez/2048 /usr/share/nginx/html/

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"] 