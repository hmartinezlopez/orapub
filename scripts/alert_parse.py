# alert_parse.py
# Script to analyze Oracle alert logs for parse errors
#
# 2025-04-28 hmartinez create
# 


import sys
import re
import csv

def analyze_alert_log(log_file):
    errors = []
    with open(log_file, 'r') as file:
        lines = file.readlines()

    i = 0
    while i < len(lines):
        # Identify the start of a "too many parse errors" block
        if "WARNING: too many parse errors" in lines[i]:
            # Extract timestamp (from previous line)
            timestamp = ''
            if i > 0 and re.match(r'\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d+\+\d{2}:\d{2}', lines[i-1].strip()):
                timestamp = lines[i-1].strip()

            # Extract count and SQL hash
            m = re.search(r'count=(\d+)\s+SQL hash=(0x[0-9a-fA-F]+)', lines[i])
            count = m.group(1) if m else ''
            sql_hash = m.group(2) if m else ''

            # Find the PARSE ERROR line and extract error code
            error_code = ''
            while i < len(lines) and "PARSE ERROR" not in lines[i]:
                i += 1
            if i < len(lines):
                m = re.search(r'error=(\d+)', lines[i])
                error_code = m.group(1) if m else ''

            # The SQL text is in the next timestamped line
            sql_text = ''
            i += 1
            if i < len(lines) and re.match(r'\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d+\+\d{2}:\d{2}', lines[i].strip()):
                sql_text = lines[i+1].strip() if (i+1 < len(lines)) else ''
                # But sometimes the SQL text is on the same line (for short statements)
                if sql_text.startswith("BEGIN") or sql_text.startswith("begin"):
                    pass
                else:
                    # Sometimes the SQL text is immediately after the timestamp
                    sql_text = lines[i].strip()
            else:
                # fallback: try the current line
                if i < len(lines) and (lines[i].strip().startswith("BEGIN") or lines[i].strip().startswith("begin")):
                    sql_text = lines[i].strip()

            # Find the sqlid and username in the following lines
            sqlid = ''
            username = ''
            lookahead = 0
            while i + lookahead < len(lines) and lookahead < 10:
                if 'sqlid=' in lines[i+lookahead]:
                    m = re.search(r'sqlid=([a-z0-9]+)', lines[i+lookahead])
                    if m:
                        sqlid = m.group(1)
                if 'Current username=' in lines[i+lookahead]:
                    m = re.search(r'Current username=([^\s]+)', lines[i+lookahead])
                    if m:
                        username = m.group(1)
                        break  # Found username, can stop
                lookahead += 1

            errors.append([timestamp, count, sql_hash, error_code, sqlid, username, sql_text])
        i += 1

    return errors

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Uso: python script.py <alert_log_file>")
        sys.exit(1)

    log_file = sys.argv[1]

    try:
        results = analyze_alert_log(log_file)
        with open('resultado_parse.csv', 'w', newline='') as csvfile:
            writer = csv.writer(csvfile)
            writer.writerow(['Timestamp', 'Parse Count', 'SQL Hash', 'Error Code', 'SQL ID', 'Username', 'SQL Text'])
            writer.writerows(results)
        print(f"Se han encontrado {len(results)} errores. Resultados guardados en resultado_parse.csv")
    except FileNotFoundError:
        print(f"Error: El archivo {log_file} no existe.")
        sys.exit(1)
    except Exception as e:
        print(f"Error al procesar el archivo: {e}")
        sys.exit(1)
