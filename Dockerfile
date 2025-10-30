#Pull image slim as builder which is stable and larger for installing requirement
FROM python:3.11-slim AS builder
WORKDIR /app
#COPY the app needed inside the python image
#including requirements.txt
COPY app/ .
#clean cache after downloading
#54.1MB with --no-cache-dir
#otherwise
#the prefix is easy to let the runner to copy
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt
#otherwise still 54.1MB
#RUN pip install -r requirements.txt

#Pull image alpine as runner which is lighter than slim 
FROM python:3.11-alpine 
#Create non root user
RUN adduser -D appuser
WORKDIR /app
#Copy the downloaded item 
COPY --from=builder /app /app
COPY --from=builder /install /usr/local
#change to non root user 
USER appuser 
EXPOSE 5000
CMD ["python","app.py"]