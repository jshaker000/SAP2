`default_nettype none

// Load ram from file, then allow Ram to be addressed for reading / writing.
// We want the RAM to allow for synchronosu reads
// To do this, without increasing read latency, we add a 2:1 mux for the RAM address
//   Writing - use the Memory address register for address, use the bus for write data
//   Reading - use the bus for address

module Ram #(
  parameter  WIDTH      = 16,
  parameter  FILE       = "ram.hex"
)(
  input  wire                  clk,
  input  wire                  clk_en,
  input  wire      [WIDTH-1:0] i_memory_address_register,
  input  wire                  i_load_enable,
  input  wire                  i_read_enable,
  input  wire      [WIDTH-1:0] i_bus_data,
  output reg       [WIDTH-1:0] o_data
);

  localparam RAM_DEPTH = 2**WIDTH; // since we have a shared bus, WIDTH = ADDR_WIDTH = log2(RAM_DEPTH)

  reg        [WIDTH-1:0] ram [0:RAM_DEPTH-1];

  initial begin
    $readmemh(FILE, ram);
  end

  wire i_load_enable_masked =  i_load_enable & ~i_read_enable;
  wire i_read_enable_masked = ~i_load_enable &  i_read_enable;

  wire [WIDTH-1:0] address_use = i_load_enable ? i_memory_address_register : i_bus_data;

  always @(posedge clk) ram[address_use] <= clk_en & i_load_enable_masked ? i_bus_data       : ram[address_use];
  always @(posedge clk) o_data           <= clk_en & i_read_enable_masked ? ram[address_use] : o_data;

  `ifndef SYNTHESIS
    always @(posedge clk) if (clk_en & i_load_enable & i_read_enable) $fatal(1, "RAM cannot have i_load_enable and i_read_enable simultaneously asserted");
  `endif

endmodule
