#pull the image
FROM nginx:stable-alpine3.21

#use my own nginx configuration file
#this would overwrite the etc file in the container, since this is only for homework which is safe
COPY etc/nginx /etc/nginx
#expose the container port to make it accessible from host
EXPOSE 80
#run in foreground
CMD ["nginx","-g","daemon off;"]
