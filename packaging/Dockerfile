# Static package-repository image: nginx serving the pre-built, pre-signed
# apt/rpm/arch trees assembled by packaging/make-repos.sh in CI.
FROM nginx:1.29-alpine

COPY html/ /usr/share/nginx/html/

# Directory listings help humans browse pool/ and repodata/.
RUN printf 'server {\n\
    listen 80;\n\
    root /usr/share/nginx/html;\n\
    autoindex on;\n\
}\n' > /etc/nginx/conf.d/default.conf
