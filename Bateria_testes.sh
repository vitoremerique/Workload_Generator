#!/bin/bash

# ==================== CONFIGURAÇÕES ====================
TOTAL_RUNS=30
RUN_DURATION=30      # Tempo (em segundos) de cada teste
COOLDOWN=5           # Tempo de espera (em segundos) entre as rodadas

# --- PARÂMETRO DE TEMPO DO SEU EXECUTÁVEL ---
DURATION_FLAG="--time" 

# --- FERRAMENTA DE MONITORAÇÃO ---
MONITOR_TOOL="pcp" 

# Identificação dos processos no sistema
PROCESS_NAME="workload_generator"
MONITOR_NAME="${MONITOR_TOOL}_monitor"

# Organização dos diretórios
BASE_OUTPUT_DIR="./metricas_out"
TOOL_DIR="$BASE_OUTPUT_DIR/$MONITOR_TOOL"
# =======================================================

# Cria a pasta específica da ferramenta se não existir
mkdir -p "$TOOL_DIR"

if [ ! -f "./workload_generator" ]; then
    echo "Erro: O executável ./workload_generator não foi encontrado."
    exit 1
fi

# Garante a interrupção limpa caso use Ctrl+C
cleanup() {
    echo -e "\n\n[!] Interrompendo bateria de testes prematuramente..."
    kill "$GEN_PID" "$PMR_PID" 2>/dev/null
    exit 1
}
trap cleanup SIGINT INT TERM

echo "================================================================="
echo " Iniciando bateria de $TOTAL_RUNS execuções"
echo " Duração interna: $RUN_DURATION segundos"
echo " Ferramenta: $MONITOR_TOOL (Process-Specific: CPU e RAM)"
echo " Salvando em: $TOOL_DIR/"
echo "================================================================="

for i in $(seq 1 $TOTAL_RUNS); do
    FILE_INDEX=$(printf "%02d" $i)
    CSV_FILE="$TOOL_DIR/run_${FILE_INDEX}.csv"
    
    echo "[$(date '+%H:%M:%S')] Execução $i/$TOTAL_RUNS -> $CSV_FILE"

    # 1. Grava os metadados no topo do arquivo CSV
    echo "# Tool: $MONITOR_TOOL" > "$CSV_FILE"
    echo "# Targets: $PROCESS_NAME, stress-ng" >> "$CSV_FILE"
    echo "# Run: $FILE_INDEX of $TOTAL_RUNS" >> "$CSV_FILE"
    echo "# Duration: $RUN_DURATION s" >> "$CSV_FILE"
    echo "# Units: CPU (utime/stime) in ms/s, RAM (rss) in Kilobytes" >> "$CSV_FILE"
    echo "# Date: $(date)" >> "$CSV_FILE"
    echo "# ------------------------------------------------" >> "$CSV_FILE"

    # 2. Dispara o gerador passando o tempo diretamente como argumento
    (exec -a "$PROCESS_NAME" ./workload_generator --cores 2 --cpu 50 --ram 3 "$DURATION_FLAG" "$RUN_DURATION") &
    GEN_PID=$!

  # 3. Dispara a monitoração global (estável, sem travar o kernel e com CSV perfeito)
    if [ "$MONITOR_TOOL" == "pcp" ]; then
        (exec -a "$MONITOR_NAME" pmrep -t 1s -o csv \
            kernel.all.cpu.user \
            kernel.all.cpu.sys \
            mem.util.used \
            kernel.all.pswitch \
            mem.vmstat.pgfault) >> "$CSV_FILE" &
        PMR_PID=$!
    fi

    # 4. Sincronização: Aguarda o processo terminar naturalmente
    wait "$GEN_PID" 2>/dev/null

    # 5. Interrompe o PCP
    if [ ! -z "$PMR_PID" ]; then
        kill "$PMR_PID" 2>/dev/null
        wait "$PMR_PID" 2>/dev/null
    fi

    # 6. Cooldown
    if [ $i -lt $TOTAL_RUNS ]; then
        echo "Aguardando ${COOLDOWN}s de cooldown..."
        sleep "$COOLDOWN"
    fi
    echo "-----------------------------------------------------------------"
done

echo "================================================================="
echo " Bateria concluída! Processos monitorados com sucesso."
echo "================================================================="