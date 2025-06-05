# Usa una imagen de Nginx como base
FROM nginx:alpine

# Copia los archivos generados en build/web al contenedor
COPY build/web /usr/share/nginx/html

# Exponer el puerto 80
EXPOSE 80

# Comando para iniciar Nginx
CMD ["nginx", "-g", "daemon off;"]
