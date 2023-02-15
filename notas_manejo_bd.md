# Comandos e instrucciones importantes para el manejo de las BD en MariaDB

## Restaurar bd desde un archivo de respaldo 


```{bash}
mariadb -u "user" -p -D "database" < "path_to_file.sql"
```
