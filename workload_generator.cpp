#include<iostream>
#include<vector>
#include<unistd.h>
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


}



int main(){


}