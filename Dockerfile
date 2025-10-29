#for API service
#developer provide json file
#so using node.js

#safest version
FROM node:20-alpine

# Update system packages to reduce vulnerabilities
RUN apk update && apk upgrade

#to app and run following command
WORKDIR /app

#package.json is a file tell npm what dependencies i want
#lock.json tells npm exactly which version to use
COPY src/package*.json ./

#install dependencies
#this only work if there is a lock.json 
#so we must run npm install for packagejson to create lock.json on local first
RUN npm ci
#clean cache
RUN npm cache clean --force

#COPY the rest of js file
COPY src/ .

# COPY wait-for.sh script to the container
COPY wait-for.sh .

#expose port for api
EXPOSE 3000

#start the app
CMD ["node","app.js"]