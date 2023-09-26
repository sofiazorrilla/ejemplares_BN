#!/bin/bash

## Para correr este script se necesita calcular el número de etiquetas totales y correr con el siguiente comando: 
# Nota: Solo se pueden crear archivos de a lo más 200 etiquetas. 
# Ejemplo: quarto render labels.qmd -P min:1 -P max:100 -P min_id_ejemplar:1361 -o labels_1_100.html
# min para el numero de fila de la informacion de las etiquetas expandidas (data) del que se quiere iniciar
# max para el numero de fila de la informacion de las etiquetas expandidas (data) del que se quiere terminar

# Define the range and step values
min_range=1
max_range=270
step=50

# Loop through the range in steps
for ((i=min_range; i<=max_range; i+=step)); do
    # Calculate the minimum and maximum values for each iteration
    min=$((i))
    max=$((i+step-1))

    # Adjust the maximum value if it exceeds the max_range
    if ((max > max_range)); then
        max=$max_range
    fi

    # Construct the command with the calculated values
    command="quarto render labels.qmd -P min:$min -P max:$max -P min_id_ejemplar:1361 -o labels_${min}_${max}.html"

    # Execute the command
    echo "Executing command: $command"
    eval "$command"

    # Optionally, you can add a sleep delay between iterations if needed
    sleep 1
done


