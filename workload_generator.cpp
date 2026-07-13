#include<iostream>
#include<vector>
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
    int ram_percent = 0;
    int iops = 0;
    bool iops_provided = false;
    int time = 60;



struct option long_options[] ={
    {"cores", required_argument, 0, 'c'},
    {"cpu", required_argument, 0, 'u'},
    {"ram", required_argument, 0, 'r'},
    {"iops", required_argument, 0, 'i'},
    {"time", required_argument, 0, 't'},
    {"help", no_argument, 0, 'h'},
    {0, 0, 0, 0}
};

int opt;
int option_index = 0;


while((opt = getopt_long(argc, argv, "c:u:r:i:t:h", long_options, &option_index )) !=-1){
    switch(opt){
        case 'c': cores = stoi(optarg); break;
        case 'u': cpu_load = stoi(optarg); break;
        case 'r': ram_percent = stoi(optarg); break;
        case 'i': iops = stoi(optarg); iops_provided = true; break;
        case 't': time = stoi(optarg); break;
        case 'h':
            cout << "Usage: " << argv[0] << " [options]" << endl
                    << "Options:" << endl
                    << "  -c, --cores <number>      Number of CPU cores to use (default: 1)" << endl
                    << "  -u, --cpu <percentage>    CPU load percentage (default: 0)" << endl
                    << "  -r, --ram <percentage>    RAM usage percentage (default: 0)" << endl
                    << "  -i, --iops <number>       IOPS (default: 0)" << endl
                    << "  -t, --time <seconds>      Duration of the workload in seconds (default: 60)" << endl
                    << "  -h, --help                Show this help message" << endl;
            return 0;
        }
    }



}