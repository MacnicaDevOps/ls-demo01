From nginx:1.22
COPY ["index.html", "macnicadevops.png", "demo.css", "/usr/share/nginx/html/"]
RUN chmod +x /usr/share/nginx/html/index.html
HEALTHCHECK CMD curl http://localhost
EXPOSE 80
