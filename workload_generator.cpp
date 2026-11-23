#include <iostream>
#include <vector>
#include <string>
#include <thread>
#include <cstdlib>
#include <getopt.h>

using namespace std;

// Função que será executada por cada thread.
// Ela invoca a ferramenta externa e aguarda sua conclusão.
void run_tool_in_thread(const string& tool_name, const string& command) {
    cout << "[" << tool_name << "] Iniciando via thread..." << endl;
    
    // system() executa o comando e bloqueia a thread atual até ele terminar
    int status = system(command.c_str());
    
    if (status != 0) {
        cerr << "[" << tool_name << "] Aviso: Comando finalizou com erro ou foi interrompido." << endl;
    } else {
        cout << "[" << tool_name << "] Concluído com sucesso." << endl;
    }
}

int main(int argc, char* argv[]) {
    cout << "Synthetic Workload Configuration (CPU, RAM, and IOPS)" << endl;
    int cores = 1;
    int cpu_load = 0;
    int ram_gigabytes = 0;
    int iops = 0;
    int readwrite = 50;
    int gpu_load = 0;
    bool cpu_provided = false;
    bool ram_provided = false;
    bool iops_provided = false;
    bool gpu_provided = false;
    int time = 60;

    struct option long_options[] = {
        {"cores", required_argument, 0, 'c'},
        {"cpu", required_argument, 0, 'u'},
        {"ram", required_argument, 0, 'r'},
        {"iops", required_argument, 0, 'i'},
        {"time", required_argument, 0, 't'},
        {"readwrite", required_argument, 0, 'w'},
        {"gpu", required_argument, 0, 'g'},
        {"help", no_argument, 0, 'h'},
        {0, 0, 0, 0}
    };

    int opt;
    int option_index = 0;

    while ((opt = getopt_long(argc, argv, "c:u:r:i:t:w:g:h", long_options, &option_index)) != -1) {
        switch (opt) {
            case 'c': cores = stoi(optarg); break;
            case 'u': cpu_load = stoi(optarg); cpu_provided = true; break;
            case 'r': ram_gigabytes = stoi(optarg); ram_provided = true; break;
            case 'i': iops = stoi(optarg); iops_provided = true; break;
            case 'w': readwrite = stoi(optarg); break;
            case 't': time = stoi(optarg); break;
            case 'g': gpu_load = stoi(optarg); gpu_provided = true; break;
            case 'h':
                cout << "Usage: " << argv[0] << " [options]" << endl
                     << "Options:" << endl
                     << "  -c, --cores <number>      Number of CPU cores to use (default: 1)" << endl
                     << "  -u, --cpu <percentage>    CPU load percentage (default: 0)" << endl
                     << "  -r, --ram <gigabytes>    RAM usage in gigabytes (example: 2 for 2G, default: 0)" << endl
                     << "  -i, --iops <number>       IOPS (default: 0)" << endl
                     << "  -w, --readwrite <percentage>  Percentage of read operations (default: 50)" << endl
                     << "  -t, --time <seconds>      Duration of the workload in seconds (default: 60)" << endl
                     << "  -g, --gpu <percentage>    GPU load percentage (default: 0)" << endl
                     << "  -h, --help                Show this help message" << endl;
                return 0;
        }
    }

    // Vetor para armazenar as threads que estão orquestrando as cargas
    vector<thread> active_threads;

    if (cpu_provided) {
        string cmd_cpu = "stress-ng --cpu " + to_string(cores) + 
                         " --cpu-method matrixprod --cpu-load " + to_string(cpu_load) + 
                         " --cpu-load-slice 10 --timeout " + to_string(time) + "s";
        active_threads.push_back(thread(run_tool_in_thread, "CPU", cmd_cpu));
    }

    if (ram_provided) {
        string cmd_ram = "stress-ng --vm 1 --vm-bytes " + to_string(ram_gigabytes) + "G" +
                         " --vm-keep --timeout " + to_string(time) + "s";
        active_threads.push_back(thread(run_tool_in_thread, "RAM", cmd_ram));
    }

    if (iops_provided) {
        string cmd_fio = "fio --name=teste_io --ioengine=libaio --rw=randrw" +
                         string(" --bs=4K --size=4G --direct=1") +
                         " --rate_iops=" + to_string(iops) + 
                         " --time_based --runtime=" + to_string(time) + 
                         " --rwmixread=" + to_string(readwrite);
        active_threads.push_back(thread(run_tool_in_thread, "IOPS", cmd_fio));
    }

    if (gpu_provided) {
        string cmd_gpu = "gpu-burn -m " + to_string(gpu_load) + "% " + to_string(time);
        active_threads.push_back(thread(run_tool_in_thread, "GPU", cmd_gpu));
    }

    cout << "[Orquestrator] Geração de carga iniciada em background." << endl;

    // Aguarda todas as threads terminarem (o que significa que as ferramentas terminaram de rodar)
    for (auto& t : active_threads) {
        if (t.joinable()) {
            t.join();
        }
    }

    cout << "[Orquestrator] Experimento completado." << endl;
    return 0;
}