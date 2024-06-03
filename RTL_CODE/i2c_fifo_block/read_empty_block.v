module read_empty_block
#(
    parameter                       addr_size = 3
)
(
    input                           read_clock_i                                , //clock in read domain
    input                           read_reset_n_i                              , //reset active low signal in read domain
    input                           read_inc_i                                  , //variable increases read address value
    input       [addr_size:0]       write_to_read_pointer_i                     , //write address to read domain to check mem empty 
    
    output reg  [addr_size - 1:0]   read_address_o                              , //read address
    output reg  [addr_size:0]       read_pointer_o                              , //read address pointer
    output reg                      read_empty_o                                , //signal that mem is empty
    output reg                      read_almost_empty_o                           //signal that mem is almost empty
);
    reg         [addr_size:0]       read_binary                                 ; //binary current read address
    reg         [addr_size:0]       read_binary_next                            ; //binary next read address
    reg         [addr_size:0]       read_gray_next                              ; //gray next read address
    reg         [addr_size:0]       read_gray_next_almost_empty_check           ;

    always @*
    begin
        read_address_o = read_binary[addr_size - 1:0]                           ; //assign value for read address output
        read_binary_next = read_binary + (read_inc_i & ~read_empty_o)           ;
        read_gray_next = (read_binary_next >> 1) ^ read_binary_next             ; //compute value of gray code: G3 = G3, G2 = B3 ^ B2, G1 = B2 ^ B1, G0 = B1 ^ B0
        read_gray_next_almost_empty_check = ((read_binary_next + 1) >> 1) 
                                            ^ (read_binary_next+ 1 )            ;
    end

    always @(posedge read_clock_i, negedge read_reset_n_i) 
    begin
        if (~read_reset_n_i)
            {read_binary, read_pointer_o} <= 0                                  ;
        else
            {read_binary, read_pointer_o} <= {read_binary_next, read_gray_next} ;
    end
    
    always @(posedge read_clock_i, negedge read_reset_n_i) 
    begin
        if (~read_reset_n_i)
            begin
                read_empty_o <= 1                                               ;
                read_almost_empty_o <= 0                                        ;
            end
        else
            begin
                read_empty_o = (write_to_read_pointer_i == read_gray_next)      ; //fifo empty check
                read_almost_empty_o = (write_to_read_pointer_i == 
                                       read_gray_next_almost_empty_check)       ; //fifo almost empty check
            end

    end

endmodule