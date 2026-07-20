# Documentação de execução do Workload Generator

Este projeto gera cargas sintéticas de CPU, RAM e IOPS para testes de desempenho. O ponto principal de execução é o binário compilado `workload_generator`, além dos scripts auxiliares para instalação e monitoramento.

## 1. Estrutura do projeto

- [workload_generator.cpp](workload_generator.cpp): código principal que gera a carga sintética.
- [install_dependencies.sh](install_dependencies.sh): instala dependências necessárias.
- [Bateria_testes.sh](Bateria_testes.sh): executa uma bateria de testes e gera saída de monitoramento.
- [Monitor_Processo.sh](Monitor_Processo.sh): monitora o processo específico do workload generator e grava um CSV.

## 2. Dependências necessárias

Antes de executar, certifique-se de que os seguintes componentes estejam instalados:

- `g++`
- `make`
- `stress-ng`
- `fio`
- `pcp` (para o script de bateria)

Você pode tentar instalar tudo com:

```bash
./install_dependencies.sh
```

## 3. Compilar o código

Na pasta do projeto, execute:

```bash
g++ -o workload_generator workload_generator.cpp
```

Se a compilação for bem-sucedida, será criado o executável `./workload_generator`.

## 4. Como executar o workload generator

### 4.1 Ajuda do programa

```bash
./workload_generator --help
```

### 4.2 Opções disponíveis

- `-c, --cores <numero>`: quantidade de cores de CPU a usar.
- `-u, --cpu <percentual>`: percentual de uso de CPU.
- `-r, --ram <gigabytes>`: quantidade de RAM a alocar/emular.
- `-i, --iops <numero>`: taxa de IOPS para a carga de disco.
- `-w, --readwrite <percentual>`: percentual de operações de leitura (o restante será escrita).
- `-t, --time <segundos>`: duração da execução.
- `-h, --help`: mostra a ajuda.

### 4.3 Exemplos práticos

#### CPU apenas

```bash
./workload_generator --cores 2 --cpu 50 --time 30
```

#### CPU + RAM

```bash
./workload_generator --cores 2 --cpu 50 --ram 3 --time 30
```

#### CPU + RAM + IOPS

```bash
./workload_generator --cores 2 --cpu 50 --ram 3 --iops 100 --time 30
```

#### CPU + RAM + IOPS com mistura de leitura/escrita

```bash
./workload_generator --cores 2 --cpu 50 --ram 3 --iops 10000 --readwrite 60 --time 30
```

Nesse exemplo:
- `--iops 10000` define a taxa de IOPS.
- `--readwrite 60` define que 60% das operações serão de leitura e 40% serão de escrita.

## 5. Executar a bateria de testes

O script [Bateria_testes.sh](Bateria_testes.sh) roda múltiplas execuções seguidas e salva os resultados em um diretório de saída.

```bash
./Bateria_testes.sh
```

### O que ele faz

- executa várias rodadas do workload generator;
- usa o PCP para coletar métricas do sistema;
- salva os resultados em diretórios dentro de `metricas_out/`.

## 6. Monitorar o processo específico

O script [Monitor_Processo.sh](Monitor_Processo.sh) monitora especificamente o processo gerado pelo workload generator e grava um CSV com métricas como:

- `cpu_pct`
- `utime_ms`
- `stime_ms`
- `rss_kb`
- `vsize_kb`
- `rchar`
- `wchar`
- `threads`

### Executar

```bash
./Monitor_Processo.sh
```

### Saída

Os arquivos CSV são salvos em:

```bash
metricas_out/process_monitor/
```

## 7. Diretórios de saída

- `metricas_out/pcp/`: saída da bateria de testes com PCP.
- `metricas_out/process_monitor/`: saída do monitoramento por processo.

## 8. Dicas de uso

- Para testar apenas CPU, use `--cpu` sem `--ram` e sem `--iops`.
- Para testar memória, use `--ram` e mantenha `--cpu`/`--iops` em zero ou sem passar.
- Para testar disco, use `--iops` e ajuste `--readwrite` conforme a proporção desejada.
- Para experimentos mais longos, aumente `--time`.
- Para aumentar o nível de carga, aumente `--cpu`, `--ram` e `--iops` gradualmente.

## 9. Exemplo completo

```bash
./workload_generator --cores 4 --cpu 80 --ram 4 --iops 5000 --readwrite 70 --time 60
```

Este comando gera:
- CPU intensa em 4 núcleos;
- uso de RAM de 4 GB;
- IOPS de 5000 com 70% de leitura e 30% de escrita;
- duração de 60 segundos.
