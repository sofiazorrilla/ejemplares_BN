# Extraer elevación de los archivos gpx

import pandas as pd
import os

files = [x for x in os.listdir(".") if x.endswith(".gpx")]

extract_data= pd.DataFrame(columns = ["time","lat","lon","ele","name"])

for file in files:
    
    df = pd.read_xml(file)
    df2 = df[["time","lat","lon","ele","name"]].iloc[1:]
    extract_data = pd.concat([extract_data, df2])


extract_data.reset_index(drop=True)

extract_data.to_csv("./coordinates.csv", index=False)



