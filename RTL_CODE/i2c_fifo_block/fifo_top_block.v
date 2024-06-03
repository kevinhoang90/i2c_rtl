module fifo_top_block
#(
    parameter                       data_size = 8                                       , 
    parameter                       addr_size = 3
)
(
    input                           read_clock_i                                        , //clock in read domain 
    input                           read_reset_n_i                                      , //reset active low signal in read domain
    input                           read_inc_i                                          , //variable increases read address value
    
    input                           write_clock_i                                       , //clock in write domain
    input                           write_reset_n_i                                     , //reset active low signal from write domain
    input                           write_inc_i                                         , //variable increases write address value
    input       [data_size - 1:0]   data_i                                              , //input data write to mem

    output      [data_size - 1:0]   data_o                                              , //output data read from mem
    output                          read_empty_o                                        , //signal that mem is empty
    output                          read_almost_empty_o                                 , //signal that mem is almost empty
    
    output                          write_full_o                                        , //signal that fifo is full
    output                          write_almost_full_o                                   //signal that fifo is almost full
);
    //internal variable
    wire        [addr_size - 1:0]   read_addr                                           ; //address in which data is read
    wire        [addr_size - 1:0]   write_addr                                          ; //address in which data is written
    wire        [addr_size:0]       write_to_read_pointer                               ;
    wire        [addr_size:0]       read_to_write_pointer                               ;
    wire        [addr_size:0]       read_pointer                                        ;
    wire        [addr_size:0]       write_pointer                                       ;


    fifo_mem_block mem(
        .write_clock_i(write_clock_i)                                                   ,
        .write_en_i(write_inc_i)                                                        ,
        .write_full_i(write_full_o)                                                     ,
        .data_i(data_i)                                                                 ,
        .write_addr_i(write_addr)                                                       ,
        .read_addr_i(read_addr)                                                         ,
        .data_o(data_o)
    );
    read_empty_block r_empt(
        .read_clock_i(read_clock_i)                                                     ,
        .read_reset_n_i(read_reset_n_i)                                                 ,
        .read_inc_i(read_inc_i)                                                         ,
        .write_to_read_pointer_i(write_to_read_pointer)                                 ,
        .read_address_o(read_addr)                                                      ,
        .read_pointer_o(read_pointer)                                                   ,
        .read_empty_o(read_empty_o)                                                     ,
        .read_almost_empty_o(read_almost_empty_o)
    );
    read_to_write_syn_block r2w(
        .write_clock_i(write_clock_i)                                                   ,
        .write_reset_n_i(write_reset_n_i)                                               ,
        .read_pointer_i(read_pointer)                                                   ,
        .read_to_write_pointer_o(read_to_write_pointer)
    );
    write_full_block w_full(
        .write_clock_i(write_clock_i)                                                   ,
        .write_reset_n_i(write_reset_n_i)                                               ,
        .write_inc_i(write_inc_i)                                                       ,
        .read_to_write_pointer_i(read_to_write_pointer)                                 ,
        .write_addr_o(write_addr)                                                       ,
        .write_pointer_o(write_pointer)                                                 ,
        .write_full_o(write_full_o)                                                     ,
        .write_almost_full_o(write_almost_full_o)
    );
    write_to_read_syn_block w2r(
        .read_clock_i(read_clock_i)                                                     ,
        .read_reset_n_i(read_reset_n_i)                                                 ,
        .write_pointer_i(write_pointer)                                                 ,
        .write_to_read_pointer_o(write_to_read_pointer)
    );
endmodule