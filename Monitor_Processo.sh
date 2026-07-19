#!/bin/bash

# ==================== CONFIGURAÇÕES ====================
TOTAL_RUNS=30
RUN_DURATION=30      # Tempo (em segundos) de cada teste
COOLDOWN=5           # Tempo de espera (em segundos) entre as rodadas

# --- PARÂMETRO DE TEMPO DO SEU EXECUTÁVEL ---
DURATION_FLAG="--time"

# Identificação dos processos no sistema
PROCESS_NAME="workload_generator"

# Hz da CPU para converter jiffies em segundos
CLK_TCK=$(getconf CLK_TCK)

# Organização dos diretórios
BASE_OUTPUT_DIR="./metricas_out"
TOOL_DIR="$BASE_OUTPUT_DIR/process_monitor"
# =======================================================

# Cria a pasta específica se não existir
mkdir -p "$TOOL_DIR"

if [ ! -f "./workload_generator" ]; then
    echo "Erro: O executável ./workload_generator não foi encontrado."
    exit 1
fi

# Garante a interrupção limpa caso use Ctrl+C
cleanup() {
    echo -e "\n\n[!] Interrompendo monitoramento prematuramente..."
    kill "$GEN_PID" "$MON_PID" 2>/dev/null
    exit 1
}
trap cleanup SIGINT INT TERM

collect_process_tree() {
    local root_pid="$1"
    local queue="$root_pid"
    local all_pids="$root_pid"

    while [ -n "$queue" ]; do
        local next_queue=""
        for pid in $queue; do
            children=$(pgrep -P "$pid" 2>/dev/null || true)
            if [ -n "$children" ]; then
                next_queue="$next_queue $children"
                all_pids="$all_pids $children"
            fi
        done
        queue="$next_queue"
    done

    echo "$all_pids"
}

echo "================================================================="
echo " Iniciando Monitoramento de Processo (Process-Specific)"
echo " Total de execuções: $TOTAL_RUNS"
echo " Duração de cada teste: $RUN_DURATION segundos"
echo " Processo alvo: $PROCESS_NAME"
echo " Salvando em: $TOOL_DIR/"
echo "================================================================="

for i in $(seq 1 $TOTAL_RUNS); do
    FILE_INDEX=$(printf "%02d" $i)
    CSV_FILE="$TOOL_DIR/run_${FILE_INDEX}.csv"
    
    echo "[$(date '+%H:%M:%S')] Execução $i/$TOTAL_RUNS -> $CSV_FILE"

    # 1. Grava os metadados no topo do arquivo CSV
    echo "timestamp,pid,cpu_pct,utime_ms,stime_ms,rss_kb,vsize_kb,rchar,wchar,threads" > "$CSV_FILE"

    # 2. Dispara o gerador
    (exec -a "$PROCESS_NAME" ./workload_generator --cores 2 --cpu 50 --ram 3 "$DURATION_FLAG" "$RUN_DURATION") &
    GEN_PID=$!
    
    # Aguarda o processo estar visível no sistema
    sleep 0.5

    # 3. Dispara monitoração do processo e seus filhos via /proc com awk
    (
        prev_total=0
        prev_read=0
        prev_write=0
        first_sample=1

        while kill -0 "$GEN_PID" 2>/dev/null; do
            pids=$(collect_process_tree "$GEN_PID")
            total_utime=0
            total_stime=0
            total_vsize=0
            total_rss=0
            total_rchar=0
            total_wchar=0
            total_threads=0

            for pid in $pids; do
                if [ -f "/proc/$pid/stat" ]; then
                    stats=$(awk '{print $14, $15, $23, $24}' "/proc/$pid/stat")
                    utime=$(echo "$stats" | awk '{print $1}')
                    stime=$(echo "$stats" | awk '{print $2}')
                    vsize=$(echo "$stats" | awk '{print $3}')
                    rss=$(echo "$stats" | awk '{print $4}')

                    total_utime=$((total_utime + utime))
                    total_stime=$((total_stime + stime))
                    total_vsize=$((total_vsize + vsize))
                    total_rss=$((total_rss + rss))
                fi

                if [ -f "/proc/$pid/io" ]; then
                    rchar=$(grep "^rchar:" "/proc/$pid/io" | awk '{print $2}')
                    wchar=$(grep "^wchar:" "/proc/$pid/io" | awk '{print $2}')
                    [ -z "$rchar" ] && rchar=0
                    [ -z "$wchar" ] && wchar=0

                    total_rchar=$((total_rchar + rchar))
                    total_wchar=$((total_wchar + wchar))
                fi

                if [ -f "/proc/$pid/status" ]; then
                    threads=$(grep "^Threads:" "/proc/$pid/status" | awk '{print $2}')
                    [ -z "$threads" ] && threads=0
                    total_threads=$((total_threads + threads))
                fi
            done

            utime_ms=$((total_utime * 1000 / CLK_TCK))
            stime_ms=$((total_stime * 1000 / CLK_TCK))
            rss_kb=$((total_rss * 4))
            vsize_kb=$((total_vsize / 1024))

            total_jiffies=$((total_utime + total_stime))
            if [ "$first_sample" -eq 1 ]; then
                cpu_pct=0.00
                first_sample=0
            else
                delta_jiffies=$((total_jiffies - prev_total))
                cpu_pct=$(awk "BEGIN {printf \"%.2f\", ($delta_jiffies / $CLK_TCK) * 100}")
            fi
            prev_total=$total_jiffies

            echo "$(date '+%s.%N'),$GEN_PID,$cpu_pct,$utime_ms,$stime_ms,$rss_kb,$vsize_kb,$total_rchar,$total_wchar,$total_threads" >> "$CSV_FILE"
            sleep 1
        done
    ) &
    MON_PID=$!

    # 4. Aguarda o processo terminar
    wait "$GEN_PID" 2>/dev/null

    # 5. Interrompe monitoração
    kill "$MON_PID" 2>/dev/null
    wait "$MON_PID" 2>/dev/null

    # 6. Cooldown
    if [ $i -lt $TOTAL_RUNS ]; then
        echo "Aguardando ${COOLDOWN}s de cooldown..."
        sleep "$COOLDOWN"
    fi
    echo "-----------------------------------------------------------------"
done

echo "================================================================="
echo " ✓ Monitoramento concluído!"
echo " Arquivos salvos em: $TOOL_DIR/"
echo " Método: Leitura direta de /proc/[PID]/"
echo "================================================================="
echo ""
echo "Para visualizar os dados:"
echo "  cat $TOOL_DIR/run_01.csv"
echo ""
