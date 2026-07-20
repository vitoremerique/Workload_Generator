#include<iostream>
#include<vector>
#include<algorithm>
#include<cctype>
#include<stdexcept>
#include<unistd.h>
#include<sys/wait.h>
#include<getopt.h>
using namespace std;

pid_t process_trigger(vector<string>& args_str){
    pid_t pid = fork();

    if(pid == -1){
        cerr << "Error: Failed to fork process" << endl;
        return -1;
    }

    if(pid == 0 ){
        vector<const char*> args;
        for(const auto& arg : args_str){
            args.push_back(arg.c_str());
        }

        args.push_back(nullptr);
        execvp(args[0], const_cast<char* const*>(args.data()));
        cerr << "Error: Failed to execute process" << endl;
        exit(1);
    }

    return pid;
};


int main(int argc, char* argv[]){
    cout << "Synthetic Workload Configuration (CPU, RAM, and IOPS)" << endl;
    int cores  = 1;
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



struct option long_options[] ={
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


while((opt = getopt_long(argc, argv, "c:u:r:i:t:w:g:h", long_options, &option_index )) !=-1){
    switch(opt){
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
                    << "  -w, --readwrite <percentage>  Percentage of read operations (default: 0)" << endl
                    << "  -t, --time <seconds>      Duration of the workload in seconds (default: 60)" << endl
                    << "  -g, --gpu <percentage>    GPU load percentage (default: 0)" << endl
                    << "  -h, --help                Show this help message" << endl;
            return 0;
        }
    }


        pid_t pid_cpu = -1;
        if (cpu_provided) {
        vector<string> args_cpu = {
            "stress-ng",
            "--cpu", to_string(cores),
            "--cpu-method", "matrixprod",
            "--cpu-load", to_string(cpu_load),
            "--cpu-load-slice", "10",
            "--timeout", to_string(time) + "s"
        };
        pid_cpu = process_trigger(args_cpu);
    }


        pid_t pid_ram = -1;
        if (ram_provided) {
        vector<string> args_ram = {
            "stress-ng",
            "--vm", "1",
            "--vm-bytes", to_string(ram_gigabytes) + "G",
            "--vm-keep",
            "--timeout", to_string(time) + "s"
        };
        pid_ram = process_trigger(args_ram);
    }
   
    
  

        pid_t pid_fio = -1;
        if (iops_provided) {
                vector<string>args_fio ={
                    "fio",
                        "--name=teste_io",
                        "--ioengine=libaio",
                        "--rw=randrw",
                        "--bs=4K", //Tamanho do Bloco 
                        "--size=4G",
                        "--direct=1", // Ignora o cache de RAM do SO para forçar escrita real no disco
                        "--rate_iops=" + to_string(iops),
                        "--time_based",
                        "--runtime=" + to_string(time),
                        "--rwmixread=" + to_string(readwrite), // foco na leitura em %, resto para escrita
                };

                pid_fio = process_trigger(args_fio);
        }

        pid_t pid_gpu = -1;
        if (gpu_provided) {
            vector<string> args_gpu = {
                "gpu-burn",
                "-m", to_string(gpu_load) + "%",
                 to_string(time)
            };
            pid_gpu = process_trigger(args_gpu);
        }




cout << "[Orquestrator Process Started]" << endl;
int status_cpu, status_ram, status_fio, status_gpu;
if (pid_cpu > 0) waitpid(pid_cpu, &status_cpu, 0);
if (pid_ram > 0) waitpid(pid_ram, &status_ram, 0);
if (pid_fio > 0) waitpid(pid_fio, &status_fio, 0);
if (pid_gpu > 0) waitpid(pid_gpu, &status_gpu, 0);

cout << "[Orquestrator] Experiment completed." << endl;




}