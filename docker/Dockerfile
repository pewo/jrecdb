FROM nginx:latest
RUN apt-get clean && apt-get update && apt-get install -y nano spawn-fcgi fcgiwrap wget curl libcgi-pm-perl libjson-perl libdigest-sha-perl && apt-get clean
#RUN apt-get install -y libcache-memcached-perl memcached
RUN sed -i 's/www-data/nginx/g' /etc/init.d/fcgiwrap
RUN chown nginx:nginx /etc/init.d/fcgiwrap
ADD ./vhost.conf /etc/nginx/conf.d/default.conf
RUN mkdir /var/www
COPY custom_403.html /var/www
COPY jrecdb.crt /etc/nginx/
COPY jrecdb.key /etc/nginx/
COPY db.pl /var/www/dbread
COPY db.pl /var/www/dbwrite
COPY db.pl /var/www/digest
WORKDIR /var/www
CMD /etc/init.d/fcgiwrap start && nginx -g 'daemon off;'
