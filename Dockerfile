# Stage 1: Build the application
FROM mcr.microsoft.com/dotnet/sdk:3.1 AS build

# Set the working directory in the build container
WORKDIR /app

# Copy the project files and restore dependencies
COPY MyWebApp.csproj ./
RUN dotnet restore

# Copy the application source code
COPY . .

# Publish the application
RUN dotnet publish -c Release -o /app/publish

# Stage 2: Create the runtime container
FROM mcr.microsoft.com/dotnet/aspnet:3.1 AS runtime

# Set the working directory in the runtime container
WORKDIR /app

# Copy the published application files from the build container to the runtime container
COPY --from=build /app/publish .

# Expose the port that your application will listen on (replace with your app's port)
EXPOSE 80

# Define the command to run your application when the container starts
CMD ["dotnet", "MyWebApp.dll"]





