From nginx:1.19.2
COPY ["index.html", "macnicadevops.png", "demo.css", "logo.png", "/usr/share/nginx/html/"]
RUN chmod +x /usr/share/nginx/html/index.html
HEALTHCHECK CMD curl http://localhost
EXPOSE 80
