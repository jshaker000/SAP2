#include "VTop.h"
#include "VTop_Top.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

#include <ncurses.h>

#include <cstdint>
#include <cstdlib>

#include <chrono>
#include <iostream>
#include <string>
#include <thread>

static std::string GetEnv(const std::string &var)
{
    const char* val = std::getenv(var.c_str());
    return val==nullptr ? "" : std::string(val);
}

static inline char bool_to_c (bool in)
{
    return in ? '1' : '0';
}

static void tick ( int tickcount, VTop *tb,
                   VerilatedVcdC *tfp )
{
    tb->eval();
    // log right before clock
    if (tfp != nullptr)
        tfp->dump(tickcount*10-0.0001);
    tb->eval();
    tb->clk = 1;
    tb->eval();
    // log at the posedge
    if (tfp != nullptr)
        tfp->dump(tickcount * 10);
    // log before neg edge
    if (tfp != nullptr)
    {
        tfp->dump(tickcount*10 + 4.999);
        tfp->flush();
    }
    tb->clk  = 0;
    tb->eval();
    // log after negedge
    if (tfp != nullptr)
    {
        tfp->dump(tickcount*10 + 5.0001);
        tfp->flush();
    }
    return;
}

int main(int argc, char**argv)
{
    const bool          dump_traces = (GetEnv("DUMPTRACES") == "1") || (GetEnv("DUMP_TRACES") == "1");
    const std::string   dp_f        = (GetEnv("DUMP_F") != "")    ? GetEnv("DUMP_F")                : "top_trace.vcd";
    const std::uint64_t max_steps   = (GetEnv("MAX_STEPS") != "") ? std::atoll(GetEnv("MAX_STEPS").c_str()) : 3500000;
    Verilated::commandArgs(argc,argv);
    VTop          *tb  = new VTop;
    if (tb == nullptr)
    {
        std::cerr << "Error opening Verilator bench." << std::endl;
        return 1;
    }
    VerilatedVcdC *tfp = nullptr;

    if (dump_traces)
    {
        Verilated::traceEverOn(true);
        tfp = new VerilatedVcdC;
        tb->trace(tfp,99);
        tfp->open(dp_f.c_str());
        std::cerr << "Opening Dump File: " << dp_f << std::endl;
        if (tfp == nullptr)
        {
            std::cerr << "Error opening VCD file." << std::endl;
            delete tb;
            return 2;
        }
    }

    tb->clk = 0;
    tb->eval();

    bool          halt   = false;
    bool          out_in = false;
    std::uint64_t out_data = 0;

    std::uint64_t k = 1;
    do
    {
        tick(k, tb, tfp);
        halt     = tb->Top->get_halt();
        out_data = tb->Top->get_out_data();
        if (out_in) {
          std::cout << "Out Register (dec): " << out_data << " at clk " << k-1 << std::endl;
        }
        out_in   = tb->Top->get_out_in();
        k++;
    } while (k < max_steps && (halt!=1));


    // return an error if we exited by infinite loop
    int exit_code;
    if (halt == 1)
    {
        exit_code = 0;
        std::cerr << "Success: Simulation Terminated successfully at a HLT at clk " << k-1 << std::endl;
        std::cerr << "Out Register (dec): " << out_data << std::endl;
    }
    else
    {
        exit_code = 1;
        std::cerr << "Error:   Simulation Terminated at clk " << k-1 << " without hitting a HLT!" << std::endl;
    }
    if (tfp) tfp->close();
    delete tb;
    delete tfp;
    return exit_code;
}
