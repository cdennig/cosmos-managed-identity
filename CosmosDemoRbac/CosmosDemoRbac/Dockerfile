FROM mcr.microsoft.com/dotnet/runtime:5.0 AS base
WORKDIR /app

FROM mcr.microsoft.com/dotnet/sdk:5.0 AS build
WORKDIR /src
COPY ["CosmosDemoRbac/CosmosDemoRbac.csproj", "CosmosDemoRbac/"]
RUN dotnet restore "CosmosDemoRbac/CosmosDemoRbac.csproj"
COPY . .
WORKDIR "/src/CosmosDemoRbac"
RUN dotnet build "CosmosDemoRbac.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "CosmosDemoRbac.csproj" -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "CosmosDemoRbac.dll"]
