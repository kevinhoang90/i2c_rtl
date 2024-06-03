module fifo_mem_block 
#(
    parameter                   data_size = 8                               ,
    parameter                   addr_size = 3
)
(
    input                       write_clock_i                               , //clock write domain
    input                       write_en_i                                  , //enable write data
    input                       write_full_i                                , //signal that mem is full
    input   [data_size - 1:0]   data_i                                      , //input data write to mem
    input   [addr_size - 1:0]   write_addr_i                                , //address in which data is written
    input   [addr_size - 1:0]   read_addr_i                                 , //address in which data is read

    output  [data_size - 1:0]   data_o                                        //output data read from mem
);
    localparam                  fifo_depth = 1 << addr_size                 ;
    reg     [data_size - 1:0]   fifo_mem [fifo_depth - 1:0]                 ;
    

    assign data_o = fifo_mem[read_addr_i]                                   ; //read data from mem

    always @(posedge write_clock_i) 
    begin
        if (write_en_i && ~write_full_i)
            fifo_mem[write_addr_i] <= data_i                                ; //write data to mem 
    end

endmodule