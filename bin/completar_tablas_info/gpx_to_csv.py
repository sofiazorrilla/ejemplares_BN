# Extraer elevación de los archivos gpx


def gpx2csv(file_path, outfile_path, several_files = False, dir_path="."):

    import pandas as pd
    import os
    from io import StringIO

    file_path = "data/puntos_gps/Waypoints_03-MAY-24.gpx"
    several_files = False
    dir_path = "data/puntos_gps"
    outfile_path = "data/puntos_gps/coordinates030524.csv"

    if several_files:
        files = [x for x in os.listdir(dir_path) if x.endswith(".gpx")]
    else:
        files = [file_path]

    extract_data= pd.DataFrame(columns = ["time","lat","lon","ele","name","cmt"])

    xml_list = []

    for file in files:
        with open(file, "r") as xml:
            xml_content = xml.readline()
            xml_list.append(xml_content)

    for xml in xml_list:
        df = pd.read_xml(StringIO(xml))
        df2 = df[["time","lat","lon","ele","name","cmt"]].iloc[1:]
        extract_data = pd.concat([extract_data, df2])

    extract_data.reset_index(drop=True)
    extract_data.to_csv(outfile_path, index=False)


#gpx2csv(file_path="data/puntos_gps/Waypoints_03-MAY-24.gpx", outfile_path="data/puntos_gps/coordinates030524.csv", several_files=False)

