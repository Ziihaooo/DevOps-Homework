#Builder Stage
#using js so need node image
FROM node:lts-alpine3.22 AS builder 
#1 med vul and 1 low from docker hub.\
#best practice to app workdir
WORKDIR /app 
#COPY requirement file inside for download 
#best practice so this step wont get affected if one of the file got modified 
COPY package*.json ./ 
#clean cache for smaller size
#omit dev just download one dependency
RUN npm ci --omit=dev && npm cache clean --force
COPY . .

#COPY the rest of the js file 

#Production Stage
FROM node:lts-alpine3.22 AS production
#create non root user
RUN adduser -D appuser
WORKDIR /app

#copy all file include dependencies 
COPY --from=builder /app .

USER appuser
EXPOSE 3000
#package.json got script with start so just need npm start here
CMD ["npm","start"]