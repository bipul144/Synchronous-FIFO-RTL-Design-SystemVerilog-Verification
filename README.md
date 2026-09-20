# Synchronous FIFO — RTL Design & SystemVerilog Verification
 
A 16-deep, 8-bit wide **synchronous (single-clock) FIFO**, verified with a
class-based, UVM-style SystemVerilog testbench (transaction / generator /
driver / monitor / scoreboard architecture) built directly on mailboxes and
events rather than the UVM library.
 
> 📄 See [`docs/REPORT.pdf`](REPORT.pdf) (also available as
> [`docs/REPORT.md`](REPORT.md)) for the full detailed design and
> verification report, including architecture, signal descriptions,
> verification methodology, and known limitations.
 
---
 
## Repository Structure
 
```
sync_fifo_project/
├── rtl/
│   ├── syn_fifo.sv      # DUT: synchronous FIFO RTL
│   └── fifo_if.sv        # SystemVerilog interface (DUT <-> testbench)
├── tb/
│   └── fifo_tb.sv        # Class-based testbench (transaction..top module)
├── docs/
│   ├── REPORT.pdf         # Detailed design & verification report (PDF)
│   └── REPORT.md          # Same report, in Markdown
└── README.md
```
 
## Design Overview
 
| Parameter          | Value                          |
|---------------------|--------------------------------|
| Data width           | 8 bits                         |
| Depth                | 16 words                       |
| Clock                | Single, synchronous (`clk`)    |
| Reset                | Synchronous, active-high (`rst`) |
| Write/Read priority  | Write has priority over read (same-cycle) |
| Status flags         | `full`, `empty` (combinational, from internal counter) |
 
The FIFO uses a circular buffer (`mem[15:0]`), write/read pointers
(`wptr`, `rptr`), and a 5-bit occupancy counter (`cnt`) to derive `full`
(`cnt == 16`) and `empty` (`cnt == 0`).
 
This mirrors the classic **synchronous FIFO** architecture: a single
free-running clock drives both write and read logic, so `full` and `empty`
are always synchronized with that clock, with no cross-clock-domain
metastability concerns (as opposed to an asynchronous/dual-clock FIFO).
 
## Verification Overview
 
The testbench is organized as five cooperating classes plus a top module:
 
1. **`transaction`** — randomized stimulus item; `oper` bit selects
   write (`1`) or read (`0`) with a 50/50 distribution.
2. **`generator`** — randomizes and issues `count` transactions
   (90 in the provided top module) through a mailbox.
3. **`driver`** — translates each transaction into pin-level FIFO
   write/read activity on the virtual interface; also drives DUT reset.
4. **`monitor`** — passively samples the interface after each driven
   operation and packages the observed values into a transaction.
5. **`scoreboard`** — a reference model (`bit [7:0] din[$]`) that
   predicts FIFO contents and checks every read's data against it,
   reporting `DATA MATCH` / `DATA MISMATCH` and a final error count.
All components run concurrently in `environment::test()` using
`fork ... join_any`, with the generator and scoreboard paced against each
other through a shared event (`nextgs`) so exactly one transaction is
in flight through the pipeline before the next is issued.
 
## Running the Simulation
 
Any SystemVerilog-capable simulator can compile and run this testbench.
File order matters: compile the interface and DUT before the testbench.
 
### Synopsys VCS
```bash
vcs -sverilog rtl/fifo_if.sv rtl/syn_fifo.sv tb/fifo_tb.sv -o simv
./simv
```
 
### Cadence Xcelium
```bash
xrun -sv rtl/fifo_if.sv rtl/syn_fifo.sv tb/fifo_tb.sv
```
 
### Mentor/Siemens QuestaSim / ModelSim
```bash
vlog -sv rtl/fifo_if.sv rtl/syn_fifo.sv tb/fifo_tb.sv
vsim -c tb -do "run -all; quit"
```
 
### EDA Playground / Icarus (with SV support)
Icarus Verilog has only partial SystemVerilog class support; a
UVM/class-capable simulator (VCS, Xcelium, Questa, or EDA Playground with
one of those simulators selected) is recommended for this testbench.
 
A `dump.vcd` waveform file is generated on every run (via `$dumpfile` /
`$dumpvars`) and can be viewed in GTKWave or your simulator's waveform
viewer.
 
## Sample Console Output
 
```
[DRV] : DUT Reset Done
------------------------------------------
[GEN] : Oper : 1 iteration : 1
[DRV] : DATA WRITE  data : 7
[MON] : Wr:1 rd:0 din:7 dout:0 full:0 empty:1
[SCO] : Wr:1 rd:0 din:7 dout:0 full:0 empty:1
[SCO] : DATA STORED IN QUEUE :7
--------------------------------------
...
---------------------------------------------
Error Count :0
---------------------------------------------
```
 
## Known Limitations / Suggested Improvements
 
See the **Known Limitations** section of [`docs/REPORT.pdf`](docs/REPORT.pdf)
for details on: `mem`/`dout` not being cleared on reset, no simultaneous
read+write support, no functional coverage collection, and the
`tr.randomize` call missing parentheses.
 

