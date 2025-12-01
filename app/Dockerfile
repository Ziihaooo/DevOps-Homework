#image recommended by Microsoft Docs
#divide to base,build and final stages is recommended by AI
#base is gonna use by multiple final stage so dont need to write the expose again if we have multiple projects
FROM mcr.microsoft.com/dotnet/aspnet:8.0-alpine AS base
WORKDIR /app
EXPOSE 8080

#build stage
#download the sdk image
#SDK = Software Development Kit include the dotnet so can build and publish
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY . .
#similar to pip install -r requirements.txt or npm install
RUN dotnet restore
#compile the code in .dll, copy the dependencies to /app/publish folder
RUN dotnet publish -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=build /app/publish .
#run the dll file to start the app
ENTRYPOINT ["dotnet", "week8-app.dll"]
#trivy output show 3 medium and no high and critical vulnerabilities
