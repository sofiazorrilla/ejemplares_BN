# Instrucciones

El archivo de join_raw corresponde a la unión de la base de datos del inventario que hicimos (todos) con los códigos del GPS. Las columnas de ese archivo corresponden a lo siguiente:

1. ``row`` = número de fila cuando uni los archivos que me mandaron. Esa columna es solo para poder regresar al orden original (no contiene información muy importante)
2. ``Persona`` = Quién realizó el inventario.
3. ``Caja`` = Caja revisada (solo para que sea más fácil ir a revisar el ejemplar si es necesario)
4. ``Codigo`` = Código del ejemplar
5. ``Lugar`` = Lugar de colecta aproximado
6. ``Encino`` = SI o NO dependiendo de si el ejemplar es una muestra de encino
7. ``DUPLICADOS`` = Número de ejemplares con el mismo código
8. ``ETIQUETA`` = Presencia o ausencia de etiqueta en el ejemplar
9. ``COMENTARIO`` = Nota u observación en el periódico o durante el inventario
10. ``Longitude_gps`` = Coordenadas guardadas en el GPS (solo se muestran aquellas en las que el código del inventario y el del GPS eran exactamente iguales)
11. ``Latitude_gps`` = Coordenadas guardadas en el GPS (solo se muestran aquellas en las que el código del inventario y el del GPS eran exactamente iguales)
12. ``copia_codigo`` = Código guardado en el GPS (solo se muestra el de aquellas en las que el código del inventario y el del GPS eran exactamente iguales)
13. ``Pais``
14. ``Estado``
15. ``Localidad``
16. ``Altitud``
17. ``Colector`` = Colectores que van a ir en la etiqueta Apellido, Nombre (de todos)
18. ``Fecha_colecta`` = Mes (letras) - Año
19. ``Tipo_vegetación``
20. ``Comentario``

## Organización para coordenadas

Muchos de los códigos del GPS no son iguales a los que están en los periódicos. En algunos casos les falta un cero, en otros probablemente están mal escritos, etc. Ver qué código corresponde a qué requiere inspección manual. 

En total hay 90 ejemplares para los que no hay etiqueta y los códigos del GPS no corresponden con los del periodico (los llamaré códigos problemáticos). Lo que hay que hacer es revisar los códigos del GPS para ver si podemos decifrar cual le corresponde a cada uno. Sugiero que la división sea la siguiente: 

- Los primeros 30 códigos problemáticos (usando la columna de row como índice) serían para **Sofía**. Esos están entre la fila 1 y la 134.
- Del mismo modo para **Meli** corresponderían los códigos problemáticos entre la fila 135 y la 267. 
- Finalmente **Sergio** haría los de la 268 a la 301. 

Cuando se haya hecho la desición de qué código de GPS asignar a qué código de periódico porfa copien las coordenadas a las columnas Latitude_gps y Longitude_gps y ponganle el código que tiene el GPS en la columna codigo_gps
