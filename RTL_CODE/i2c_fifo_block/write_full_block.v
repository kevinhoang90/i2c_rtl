module write_full_block
#(
    parameter                       addr_size = 3
)
(
    input                           write_clock_i                                                                       , //clock in write domain
    input                           write_reset_n_i                                                                     , //reset active low signal from write domain
    input                           write_inc_i                                                                         , //variable increases write address value
    input       [addr_size:0]       read_to_write_pointer_i                                                             , //read address to write domain to check fifo full
    
    output reg  [addr_size - 1:0]   write_addr_o                                                                        , //write address
    output reg  [addr_size:0]       write_pointer_o                                                                     , //write address pointer
    output reg                      write_full_o                                                                        , //signal that fifo is full
    output reg                      write_almost_full_o                                                                   //signal that fifo is almost full        
);
    reg         [addr_size:0]       write_binary                                                                        ;
    reg         [addr_size:0]       write_binary_next                                                                   ;
    reg         [addr_size:0]       write_gray_next                                                                     ;
    reg         [addr_size:0]       write_gray_almost_full_check                                                        ;

    always @*
    begin
        write_addr_o = write_binary[addr_size - 1:0]                                                                    ;
        write_binary_next = write_binary + (write_inc_i & ~write_full_o)                                                ;
        write_gray_next = (write_binary_next >> 1) ^ write_binary_next                                                  ;
        write_gray_almost_full_check = ((write_binary_next + 1) >> 1) 
                                        ^ (write_binary_next + 1)                                                       ;
    end

    always @(posedge write_clock_i, negedge write_reset_n_i) 
    begin
        if (~write_reset_n_i)
            {write_binary, write_pointer_o} <= 0                                                                        ;
        else
            {write_binary, write_pointer_o} <= {write_binary_next, write_gray_next}                                     ;
    end

    always @(posedge write_clock_i, negedge write_reset_n_i) 
    begin
        if (~write_reset_n_i)
            begin
                write_full_o <= 0                                                                                       ;
                write_almost_full_o <= 0                                                                                ;
            end
        else
            begin
                write_full_o <= (write_gray_next[addr_size:addr_size - 1] == ~read_to_write_pointer_i[addr_size:addr_size - 1] 
                    && write_gray_next[addr_size - 2:0] == read_to_write_pointer_i[addr_size - 2:0])                    ; //check fifo mem is full

                write_almost_full_o <= (write_gray_almost_full_check[addr_size] == ~read_to_write_pointer_i[addr_size] 
                    && write_gray_almost_full_check[addr_size - 1:0] == read_to_write_pointer_i[addr_size - 1:0])       ;// check fifo mem is almost full 

            end
    end
endmodule