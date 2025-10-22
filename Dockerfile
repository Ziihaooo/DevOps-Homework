#pull nginx image
FROM nginx:stable-alpine3.21
#make my html file become the static content of the nginx server
COPY html/index.html /usr/share/nginx/html


