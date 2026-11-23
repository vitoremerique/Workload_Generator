# Workload Generator

Gerador de carga sintética de **CPU**, **RAM**, **disco (IOPS)** e **GPU** para testes de desempenho.

O `workload_generator` é um orquestrador: cada tipo de carga roda em sua própria thread, que dispara uma ferramenta especializada. Todas rodam em paralelo pela mesma duração.

| Carga | Ferramenta | Opções |
|-------|------------|--------|
| CPU   | `stress-ng --cpu` | `--cores`, `--cpu` |
| RAM   | `stress-ng --vm`  | `--ram` |
| Disco | `fio` (leitura/escrita aleatória, blocos de 4K) | `--iops`, `--readwrite` |
| GPU   | `gpu-burn` | `--gpu` |

## Arquivos

- `workload_generator.cpp`: código-fonte do gerador.
- `install_dependencies.sh`: instala as dependências e compila o binário.

## Instalação

### Automática

```bash
chmod +x install_dependencies.sh
./install_dependencies.sh          # instala g++, stress-ng e fio e compila
./install_dependencies.sh --gpu    # também instala o gpu-burn (precisa de GPU NVIDIA + CUDA)
```

Distribuições suportadas: Ubuntu/Debian, Fedora, RHEL/CentOS/Rocky/Alma e Arch.

### Manual

Instale `g++`, `stress-ng` e `fio` (e `gpu-burn`, se for gerar carga de GPU) e compile:

```bash
g++ -O2 -pthread -o workload_generator workload_generator.cpp
```

## Uso

```bash
./workload_generator [opções]
```

| Opção | Descrição | Padrão |
|-------|-----------|--------|
| `-c, --cores <n>` | Número de núcleos usados pela carga de CPU | `1` |
| `-u, --cpu <%>` | Percentual de uso em cada núcleo (0–100) | — |
| `-r, --ram <GB>` | Memória a alocar, em gigabytes (inteiro) | — |
| `-i, --iops <n>` | Taxa de operações de disco por segundo | — |
| `-w, --readwrite <%>` | Percentual de leituras; o restante é escrita | `50` |
| `-g, --gpu <%>` | Percentual da memória da GPU usada pelo `gpu-burn` | — |
| `-t, --time <s>` | Duração da carga, em segundos | `60` |
| `-h, --help` | Mostra a ajuda | |

Só as cargas cujas opções forem passadas são geradas. Por exemplo, sem `--ram` não há carga de memória. `--cores` sozinho não gera carga; use-o junto com `--cpu`.

## Exemplos

Apenas CPU: 2 núcleos a 50% por 30 segundos.
```bash
./workload_generator --cores 2 --cpu 50 --time 30
```

Apenas memória: 3 GB por 30 segundos.
```bash
./workload_generator --ram 3 --time 30
```

Apenas disco: 1000 IOPS com 70% de leitura e 30% de escrita.
```bash
./workload_generator --iops 1000 --readwrite 70 --time 30
```

Apenas GPU: 50% por 60 segundos.
```bash
./workload_generator --gpu 50 --time 60
```

Tudo junto:
```bash
./workload_generator --cores 4 --cpu 80 --ram 4 --iops 5000 --readwrite 70 --gpu 50 --time 60
```

## Observações

- **Arquivo de teste do fio:** a carga de disco cria um arquivo de **4 GB** (`teste_io.0.0`) no diretório atual. Rode o comando num disco com espaço livre e apague o arquivo ao terminar:
  ```bash
  rm -f teste_io.0.0
  ```
- **I/O direto:** o `fio` usa `--direct=1` (ignora o cache de páginas). Alguns sistemas de arquivos, como o `tmpfs`, não aceitam esse modo.
- **Memória:** não peça mais RAM do que a máquina tem livre, senão o sistema pode começar a usar swap ou acionar o OOM killer.
- **Interromper:** `Ctrl+C` encerra o gerador e as ferramentas que ele disparou.
- **Monitorar a carga:** use ferramentas como `htop`, `iostat -x 1`, `vmstat 1` ou `nvidia-smi` em outro terminal.
