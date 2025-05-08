# 🚀 Deploying a .NET Core Web App with systemd, Nginx, and Docker

This guide walks you through building, publishing, deploying, and containerizing a simple .NET Core Web API (`MyWebApp`) on Ubuntu using systemd, Nginx, and Docker.

---

## 🛠️ Create and Build the App

```bash
dotnet new web -n MyWebApp
cd MyWebApp
dotnet build
dotnet publish -c Release -o ./publish
```

---

## 🖥️ Create a systemd Service

```bash
sudo vi /etc/systemd/system/MyWebApp.service
```

Paste this:

```ini
[Unit]
Description=Hello World .NET Core Service
Wants=network-online.target
After=network-online.target

[Service]
WorkingDirectory=/home/ubuntu/MyWebApp/publish
ExecStart=/usr/bin/dotnet /home/ubuntu/MyWebApp/publish/MyWebApp.dll --urls=http://localhost:3000
Restart=always
RestartSec=10
KillSignal=SIGINT

[Install]
WantedBy=multi-user.target
```

Enable and start the service:

```bash
sudo systemctl enable MyWebApp
sudo systemctl start MyWebApp
```

---

## 🌐 Nginx Installation & Reverse Proxy

```bash
sudo apt install -y nginx
```

Create Nginx config:

```bash
sudo vi /etc/nginx/sites-available/helloworld
```

Paste:

```nginx
server {
    listen 80 default_server;
    server_name _;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection keep-alive;
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }

    location /app {
        alias /path/to/your/publish/directory;  # Replace with your app's directory
        index index.html;
    }

    location ~* \.(jpg|jpeg|gif|png|css|js|ico|xml)$ {
        expires 1y;
    }
}
```

Enable the site and reload Nginx:

```bash
sudo ln -s /etc/nginx/sites-available/helloworld /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl start nginx
sudo systemctl enable nginx
sudo systemctl restart nginx
```

---

## 🔧 Modify `Program.cs` to Bind on Port 3000

```csharp
var builder = WebApplication.CreateBuilder(args);
builder.WebHost.UseUrls("http://0.0.0.0:3000");
var app = builder.Build();

app.MapGet("/", () => "Hello World!");
app.Run();
```

Restart the app:

```bash
sudo systemctl restart MyWebApp
sudo systemctl restart nginx
```

---

## 🐳 Dockerize the Published App

### Dockerfile (using published files)

```dockerfile
FROM mcr.microsoft.com/dotnet/aspnet:3.1
WORKDIR /app
COPY ./publish ./
EXPOSE 80
CMD ["dotnet", "MyWebApp.dll"]
```

Build and run:

```bash
docker build -t helloworld-app .
docker run -d -p 80:80 helloworld-app
```

---

## 🐳 Dockerize from Scratch (Multistage Build)

```dockerfile
# Stage 1: Build the app
FROM mcr.microsoft.com/dotnet/sdk:3.1 AS build
WORKDIR /app
COPY MyWebApp.csproj ./
RUN dotnet restore
COPY . .
RUN dotnet publish -c Release -o /app/publish

# Stage 2: Run the app
FROM mcr.microsoft.com/dotnet/aspnet:3.1 AS runtime
WORKDIR /app
COPY --from=build /app/publish .
EXPOSE 80
CMD ["dotnet", "MyWebApp.dll"]
```

Then:

```bash
docker build -t helloworld-app .
docker run -d -p 80:80 helloworld-app
```

---

## ✅ Summary

You now have:
- A .NET Core app running as a systemd service
- Reverse-proxied via Nginx
- Optionally containerized with Docker

