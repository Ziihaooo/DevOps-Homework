1. Create nginx-static directory with command "mkdir nginx-static"
2. Go inside the nginx-static directory with command "cd nginx-static"
3. Create another directory call html with command "mkdir html"
4. Go inside html directory "cd html"
5. Create a file named sample.html with command "touch sample.html"
6. Provides a short descriptive message about the static site inside the sample.html 
   with command "vi sample.html" and put in your html code.
7. Press "esc" and type :wq to save sample.html file
8. Go back to nginx-static directory with command "cd .."
9. Create a Dockerfile with command "touch Dockerfile"
10.Edit the Dockerfile with vi and put in the following command
FROM nginx:stable-alpine3.21
COPY html/sample.html /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g","daemon off;"]
and save the file
11. built the container by using the created Dockerfile with command "docker build -t "containername" -f Dockerfile ." 
12. Match the port 80 of the container to the port 8080 of the host with command "docker run -d -p 8080:80 "containername" "
13. Go to your host browser and type "http://localhost:8080", which should be accessible and showing the content of your sample.html
14. Find the containerID with command "docker ps"
15. Use the containerID to view the logs "docker logs "containerID" "
16. If there is a 200 response showing, you are successful
