module write_to_read_syn_block 
#(
    parameter                       addr_size = 3
)
(
    input                           read_clock_i                                , //clock in read domain
    input                           read_reset_n_i                              , //reset active low signal from read domain
    input       [addr_size:0]       write_pointer_i                             , //write address pointer from write domain
    
    output reg  [addr_size:0]       write_to_read_pointer_o                       //write to read pointer 
);
    reg         [addr_size:0]       tem_write_to_read_pointer                   ; //temp variable for synchronize write -> read

    always @(posedge read_clock_i, negedge read_reset_n_i) 
    begin
        if (~read_reset_n_i)
            {write_to_read_pointer_o, tem_write_to_read_pointer} <= 0           ;
        else
            {write_to_read_pointer_o, tem_write_to_read_pointer} <=
                {tem_write_to_read_pointer, write_pointer_i}                    ;
    end

endmodule