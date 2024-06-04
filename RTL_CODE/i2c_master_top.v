module i2c_master_top(
    input               i2c_core_clock_i                                                ,

    input               pclk_i                                                          , //apb clock
    input               preset_n_i                                                      , //apb reset
    input               penable_i                                                       ,
    input               psel_i                                                          ,
    input       [7:0]   paddr_i                                                         ,
    input       [7:0]   pwdata_i                                                        ,
    input               pwrite_i                                                        ,

    //----------------------------------------------------------------------------------
    output      [7:0]   prdata_o                                                        ,
    output              pready_o                                                        ,
    output              reset                                                           ,
    inout               sda_io                                                          ,
    inout               scl_io
);
    //fsm block internal signal
    wire                start_cnt                                                       ;
    wire                write_addr_cnt                                                  ;
    wire                write_data_cnt                                                  ;
    wire                read_data_cnt                                                   ;
    wire                write_ack_cnt                                                   ;
    wire                read_ack_cnt                                                    ;
    wire                stop_cnt                                                        ;
    wire                repeat_start_cnt                                                ;
    wire                write_fifo_en                                                   ;
    wire                read_fifo_en                                                    ;
    wire                scl_en                                                          ;
    wire                sda_en                                                          ;
    wire        [7:0]   counter_state_done_time_repeat_start                            ;
    wire                ack_bit                                                         ;

    
    //clock gen block internal signal
    wire        [7:0]   counter_detect_edge                                             ;
    wire                clock_gen_scl_o                                                 ;

    //datapath block internal signal
    wire                data_path_sda_o                                                 ;
    wire        [7:0]   data_read_from_i2c_slave                                        ;
    wire        [7:0]   counter_data_ack                                                ;
    //TX fifo top block internal signal
    wire        [7:0]   tx_fifo_data_i                                                  ;
    wire        [7:0]   tx_fifo_data_o                                                  ;
    wire                tx_fifo_read_empty                                              ;
    wire                tx_fifo_read_almost_empty                                       ;
    wire                tx_fifo_write_full                                              ;
    wire                tx_fifo_write_almost_full                                       ;

    //RX fifo top block internal signal
    wire        [7:0]   rx_fifo_data_i                                                  ;
    wire        [7:0]   rx_fifo_data_o                                                  ;
    wire                rx_fifo_read_empty                                              ;
    wire                rx_fifo_read_almost_empty                                       ;
    wire                rx_fifo_write_full                                              ;
    wire                rx_fifo_write_almost_full                                       ;
    //register block
    wire        [7:0]   prescaler                                                       ; //0x00
    wire        [7:0]   cmd                                                             ; //0x01
    wire        [7:0]   transmit                                                        ; //0x02
    wire        [7:0]   address_rw                                                      ; //0x04
    wire        [7:0]   status                                                          ;
    wire                tx_fifo_write_enable                                            ;
    wire                rx_fifo_read_enable                                             ;
    assign status = {2'b00, tx_fifo_read_empty, rx_fifo_write_full, 4'b0000}            ;

    //tristate   
    assign sda_io = sda_en == 1 ? data_path_sda_o : 1'bz                                ;
    assign scl_io = scl_en == 1 ? clock_gen_scl_o : 1                                   ;
    assign reset = cmd[5]                                                               ;
    i2c_fsm_block fsm(
        //input
        .i2c_core_clock_i(i2c_core_clock_i)                                             ,
        .enable_bit_i(cmd[6])                                                           ,
        .reset_bit_n_i(cmd[5])                                                          ,
        .rw_bit_i(address_rw[0])                                                        ,
        .sda_i(sda_io)                                                                  ,
        .repeat_start_bit_i(cmd[7])                                                     ,
        .trans_fifo_empty_i(tx_fifo_read_empty)                                         ,
        .rev_fifo_full_i(rx_fifo_write_full)                                            ,
        .counter_detect_edge_i(counter_detect_edge)                                     ,
        .counter_data_ack_i(counter_data_ack)                                           ,
        .prescaler_i(prescaler)                                                         ,
        
        //output
        .start_cnt_o(start_cnt)                                                         ,
        .write_addr_cnt_o(write_addr_cnt)                                               ,
        .write_data_cnt_o(write_data_cnt)                                               ,
        .read_data_cnt_o(read_data_cnt)                                                 ,
        .write_ack_cnt_o(write_ack_cnt)                                                 ,
        .read_ack_cnt_o(read_ack_cnt)                                                   ,
        .stop_cnt_o(stop_cnt)                                                           ,
        .repeat_start_cnt_o(repeat_start_cnt)                                           ,
        .write_fifo_en_o(write_fifo_en)                                                 ,
        .read_fifo_en_o(read_fifo_en)                                                   ,
        .scl_en_o(scl_en)                                                               ,
        .sda_en_o(sda_en)                                                               ,
        .counter_state_done_time_repeat_start_o(counter_state_done_time_repeat_start)   ,
        .ack_bit_o(ack_bit)
    );

    i2c_data_path_block data_path(
        //input
        .i2c_core_clock_i(i2c_core_clock_i)                                             ,
        .reset_bit_n_i(cmd[5])                                                          ,
        .sda_i(sda_io)                                                                  ,
        .data_i(tx_fifo_data_o)                                                         ,
        .addr_rw_i(address_rw)                                                          ,
        .ack_bit_i(ack_bit)                                                             ,
        .start_cnt_i(start_cnt)                                                         ,
        .write_addr_cnt_i(write_addr_cnt)                                               ,
        .write_data_cnt_i(write_data_cnt)                                               ,
        .read_data_cnt_i(read_data_cnt)                                                 ,
        .write_ack_cnt_i(write_ack_cnt)                                                 ,
        .read_ack_cnt_i(read_ack_cnt)                                                   ,
        .stop_cnt_i(stop_cnt)                                                           ,
        .repeat_start_cnt_i(repeat_start_cnt)                                           ,
        .counter_state_done_time_repeat_start_i(counter_state_done_time_repeat_start)   ,
        .counter_detect_edge_i(counter_detect_edge)                                     ,
        .prescaler_i(prescaler)                                                         ,

        //output
        .sda_o(data_path_sda_o)                                                         ,
        .data_o(rx_fifo_data_i)                                                         ,
        .counter_data_ack_o(counter_data_ack)
    );

    i2c_clock_gen_block clock_gen(
        //input
        .i2c_core_clock_i(i2c_core_clock_i)                                             ,
        .reset_bit_n_i(cmd[5])                                                          ,
        .prescaler_i(prescaler)                                                         ,
        
        //output
        .scl_o(clock_gen_scl_o)                                                         ,
        .counter_detect_edge_o(counter_detect_edge)
    );

    fifo_top_block tx_fifo(
        //input
        .read_clock_i(i2c_core_clock_i)                                                 ,
        .read_reset_n_i(cmd[5])                                                         ,
        .read_inc_i(read_fifo_en)                                                       ,
        .write_clock_i(pclk_i)                                                          ,
        .write_reset_n_i(preset_n_i)                                                    ,
        .write_inc_i(tx_fifo_write_enable)                                              ,
        .data_i(transmit)                                                               ,
        
        //output
        .data_o(tx_fifo_data_o)                                                         ,
        .read_empty_o(tx_fifo_read_empty)                                               ,
        .read_almost_empty_o(tx_fifo_read_almost_empty)                                 ,
        .write_full_o(tx_fifo_write_full)                                               ,
        .write_almost_full_o(tx_fifo_write_almost_full)
    );

    fifo_top_block rx_fifo(
        //input
        .read_clock_i(pclk_i)                                                           ,
        .read_reset_n_i(preset_n_i)                                                     ,
        .read_inc_i(rx_fifo_read_enable)                                                ,
        .write_clock_i(i2c_core_clock_i)                                                ,
        .write_reset_n_i(cmd[5])                                                        ,
        .write_inc_i(write_fifo_en)                                                     ,
        .data_i(rx_fifo_data_i)                                                         ,

        //output
        .data_o(rx_fifo_data_o)                                                         ,
        .read_empty_o(rx_fifo_read_empty)                                               ,
        .read_almost_empty_o(rx_fifo_read_almost_empty)                                 ,
        .write_full_o(rx_fifo_write_full)                                               ,
        .write_almost_full_o(rx_fifo_write_almost_full)
    );
    i2c_register_block register(
        //input
        .pclk_i(pclk_i)                                                                 ,
        .preset_n_i(preset_n_i)                                                         ,
        .penable_i(penable_i)                                                           ,
        .psel_i(psel_i)                                                                 ,
        .paddr_i(paddr_i)                                                               ,
        .pwdata_i(pwdata_i)                                                             ,
        .pwrite_i(pwrite_i)                                                             ,
        .receive_i(rx_fifo_data_o)                                                      ,
        .status_i(status)                                                               ,
        .stop_cnt_i(stop_cnt)                                                           ,
        //output
        .prdata_o(prdata_o)                                                             ,
        .pready_o(pready_o)                                                             ,
        .prescaler_o(prescaler)                                                         ,
        .cmd_o(cmd)                                                                     ,
        .address_rw_o(address_rw)                                                       ,
        .transmit_o(transmit)                                                           ,
        .tx_fifo_write_enable_o(tx_fifo_write_enable)                                   ,
        .rx_fifo_read_enable_o(rx_fifo_read_enable)
    );  

endmodule