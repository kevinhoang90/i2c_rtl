module read_to_write_syn_block
#(
    parameter                       addr_size = 3
)
(
    input                           write_clock_i                               , //clock write domain
    input                           write_reset_n_i                             , //reset active low signal in write domain
    input       [addr_size:0]       read_pointer_i                              , //read pointer from read domain 

    output reg  [addr_size:0]       read_to_write_pointer_o                       //read to write pointer
);
    reg         [addr_size:0]       temp_read_to_write_pointer                  ; //temp variable for synchronize read -> write

    always @(posedge write_clock_i, negedge write_reset_n_i) 
    begin
        if (~write_reset_n_i)
            {read_to_write_pointer_o, temp_read_to_write_pointer} <= 0          ;
        else
            {read_to_write_pointer_o, temp_read_to_write_pointer} <= 
                {temp_read_to_write_pointer, read_pointer_i}                    ;
    end 

endmodule