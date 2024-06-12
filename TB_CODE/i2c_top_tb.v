module i2c_top_tb();
    reg                 i2c_core_clock_i                                        ;
    reg                 pclk_i                                                  ;
    reg                 preset_n_i                                              ;
    reg                 penable_i                                               ;
    reg                 psel_i                                                  ;
    reg     [31:0]      paddr_i                                                 ;
    reg     [31:0]      pwdata_i                                                ;
    reg                 pwrite_i                                                ;

    wire    [31:0]      prdata_o                                                ;
    wire                pready_o                                                ;
    wire                sda_io                                                  ;
    wire                scl_io                                                  ;
    
    wire                start                                                   ;
    wire                stop                                                    ;
    wire    [7:0]       data_slave_read                                         ;
    wire                data_slave_read_valid                                   ;
//    reg                 sda_slave                                               ;
//    reg                 sda_slave_en                                            ;
    
    i2c_master_top dut(
        .i2c_core_clock_i(i2c_core_clock_i)                                     ,
        .pclk_i(pclk_i)                                                         ,
        .preset_n_i(preset_n_i)                                                 ,
        .penable_i(penable_i)                                                   ,
        .psel_i(psel_i)                                                         ,
        .paddr_i(paddr_i)                                                       ,
        .pwdata_i(pwdata_i)                                                     ,
        .pwrite_i(pwrite_i)                                                     ,
        .prdata_o(prdata_o)                                                     ,
        .pready_o(pready_o)                                                     ,
        .sda_io(sda_io)                                                         ,
        .scl_io(scl_io)
    );
    
//    assign sda_io = sda_slave_en ? sda_slave : 1'bz                             ;

    i2c_slave_model slave(
        .scl(scl_io)                                                            ,
        .sda(sda_io)                                                            ,
        .start(start)                                                           ,
        .stop(stop)                                                             ,
        .data_slave_read(data_slave_read)                                       ,
        .data_slave_read_valid(data_slave_read_valid)
    );

    pullup(sda_io)                                                              ;
    pullup(scl_io)                                                              ;
    initial 
    begin
        
        i2c_core_clock_i = 1                                                    ;
        pclk_i = 1                                                              ;
        preset_n_i = 0                                                          ;
        penable_i = 0                                                           ;
        psel_i = 0                                                              ;
        paddr_i = 0                                                             ;
        pwdata_i = 0                                                            ;
        pwrite_i = 0                                                            ;
//        sda_slave_en = 0                                                        ;
//        sda_slave = 0                                                           ;
        #10

        preset_n_i = 1                                                          ;

        #20
        //--------------------test write + repeat start + read------------------ 
        //cpu write to prescaler register
        #3
        psel_i = 1                                                              ; 
        penable_i = 0                                                           ;
        pwrite_i = 1                                                            ;
        paddr_i = 8'h00                                                         ;
        pwdata_i = 8'b00000111                                                  ; //prescaler value
        #10
        psel_i = 1                                                              ;
        penable_i = 1                                                           ;
        #10
        psel_i = 0                                                              ;
        penable_i = 0                                                           ;
        #10
        
        //cpu write to cmd register to disable reset i2c core
        psel_i = 1                                                              ; 
        penable_i = 0                                                           ;
        pwrite_i = 1                                                            ;
        paddr_i = 8'h01                                                         ;
        pwdata_i = 8'b00100100                                                  ; //reset command is set
        #10
        psel_i = 1                                                              ;
        penable_i = 1                                                           ;
        #10
        psel_i = 0                                                              ;
        penable_i = 0                                                           ;
        
        //cpu send address of slave, and read write bit
        #10                                                                      
        psel_i = 1                                                              ; 
        penable_i = 0                                                           ;
        pwrite_i = 1                                                            ;
        paddr_i = 8'h04                                                         ;
        pwdata_i = 8'b10101010                                                        ; //address value
        #10
        psel_i = 1                                                              ;
        penable_i = 1                                                           ;
        #10
        psel_i = 0                                                              ;
        penable_i = 0                                                           ;
        
        //cpu send data which is sent to slave
        #10                                                                      
        psel_i = 1                                                              ; 
        penable_i = 0                                                           ;
        pwrite_i = 1                                                            ;
        paddr_i = 8'h02                                                         ;
        pwdata_i = 8'h00                                                        ; //data value
        #10
        psel_i = 1                                                              ;
        penable_i = 1                                                           ;
        #10
        psel_i = 0                                                              ;
        penable_i = 0                                                           ;

        #10                                                                      
        psel_i = 1                                                              ; 
        penable_i = 0                                                           ;
        pwrite_i = 1                                                            ;
        paddr_i = 8'h02                                                         ;
        pwdata_i = 8'b11010101                                                  ; //data value
        #10
        psel_i = 1                                                              ;
        penable_i = 1                                                           ;
        #10
        psel_i = 0                                                              ;
        penable_i = 0                                                           ;
        
        #10                                                                      
        psel_i = 1                                                              ; 
        penable_i = 0                                                           ;
        pwrite_i = 1                                                            ;
        paddr_i = 8'h02                                                         ;
        pwdata_i = 8'b11010001                                                  ; //data value
        #10
        psel_i = 1                                                              ;
        penable_i = 1                                                           ;
        #10
        psel_i = 0                                                              ;
        penable_i = 0                                                           ;
        
        #10                                                                      
        psel_i = 1                                                              ; 
        penable_i = 0                                                           ;
        pwrite_i = 1                                                            ;
        paddr_i = 8'h02                                                         ;
        pwdata_i = 8'b10110101                                                  ; //data value
        #10
        psel_i = 1                                                              ;
        penable_i = 1                                                           ;
        #10
        psel_i = 0                                                              ;
        penable_i = 0                                                           ;
        
        #10                                                                      
        psel_i = 1                                                              ; 
        penable_i = 0                                                           ;
        pwrite_i = 1                                                            ;
        paddr_i = 8'h02                                                         ;
        pwdata_i = 8'b11111101                                                  ; //data value
        #10
        psel_i = 1                                                              ;
        penable_i = 1                                                           ;
        #10
        psel_i = 0                                                              ;
        penable_i = 0                                                           ;
        
        #10                                                                      
        psel_i = 1                                                              ; 
        penable_i = 0                                                           ;
        pwrite_i = 1                                                            ;
        paddr_i = 8'h02                                                         ;
        pwdata_i = 8'b11110111                                                  ; //data value
        #10
        psel_i = 1                                                              ;
        penable_i = 1                                                           ;
        #10
        psel_i = 0                                                              ;
        penable_i = 0                                                           ;
        
        #10                                                                      
        psel_i = 1                                                              ; 
        penable_i = 0                                                           ;
        pwrite_i = 1                                                            ;
        paddr_i = 8'h02                                                         ;
        pwdata_i = 8'b11110111                                                  ; //data value
        #10
        psel_i = 1                                                              ;
        penable_i = 1                                                           ;
        #10
        psel_i = 0                                                              ;
        penable_i = 0                                                           ;
        
        #10                                                                      
        psel_i = 1                                                              ; 
        penable_i = 0                                                           ;
        pwrite_i = 1                                                            ;
        paddr_i = 8'h02                                                         ;
        pwdata_i = 8'b11110111                                                  ; //data value
        #10
        psel_i = 1                                                              ;
        penable_i = 1                                                           ;
        #10
        psel_i = 0                                                              ;
        penable_i = 0                                                           ;
        
        #10                                                                      
        psel_i = 1                                                              ; 
        penable_i = 0                                                           ;
        pwrite_i = 1                                                            ;
        paddr_i = 8'h02                                                         ;
        pwdata_i = 8'b11110111                                                  ; //data value
        #10
        psel_i = 1                                                              ;
        penable_i = 1                                                           ;
        #10
        psel_i = 0                                                              ;
        penable_i = 0                                                           ;
        
        #10                                                                      
        psel_i = 1                                                              ; 
        penable_i = 0                                                           ;
        pwrite_i = 1                                                            ;
        paddr_i = 8'h02                                                         ;
        pwdata_i = 8'b11110111                                                  ; //data value
        #10
        psel_i = 1                                                              ;
        penable_i = 1                                                           ;
        #10
        psel_i = 0                                                              ;
        penable_i = 0                                                           ;
        
        #10                                                                      
        psel_i = 1                                                              ; 
        penable_i = 0                                                           ;
        pwrite_i = 1                                                            ;
        paddr_i = 8'h02                                                         ;
        pwdata_i = 8'b11110111                                                  ; //data value
        #10
        psel_i = 1                                                              ;
        penable_i = 1                                                           ;
        #10
        psel_i = 0                                                              ;
        penable_i = 0                                                           ;
        
        #10                                                                      
        psel_i = 1                                                              ; 
        penable_i = 0                                                           ;
        pwrite_i = 1                                                            ;
        paddr_i = 8'h02                                                         ;
        pwdata_i = 8'b11110111                                                  ; //data value
        #10
        psel_i = 1                                                              ;
        penable_i = 1                                                           ;
        #10
        psel_i = 0                                                              ;
        penable_i = 0                                                           ;
        
        #10                                                                      
        psel_i = 1                                                              ; 
        penable_i = 0                                                           ;
        pwrite_i = 1                                                            ;
        paddr_i = 8'h02                                                         ;
        pwdata_i = 8'b11110111                                                  ; //data value
        #10
        psel_i = 1                                                              ;
        penable_i = 1                                                           ;
        #10
        psel_i = 0                                                              ;
        penable_i = 0                                                           ;
        
        #10                                                                      
        psel_i = 1                                                              ; 
        penable_i = 0                                                           ;
        pwrite_i = 1                                                            ;
        paddr_i = 8'h02                                                         ;
        pwdata_i = 8'b11110111                                                  ; //data value
        #10
        psel_i = 1                                                              ;
        penable_i = 1                                                           ;
        #10
        psel_i = 0                                                              ;
        penable_i = 0                                                           ;
        
        #10                                                                      
        psel_i = 1                                                              ; 
        penable_i = 0                                                           ;
        pwrite_i = 1                                                            ;
        paddr_i = 8'h02                                                         ;
        pwdata_i = 8'b11110111                                                  ; //data value
        #10
        psel_i = 1                                                              ;
        penable_i = 1                                                           ;
        #10
        psel_i = 0                                                              ;
        penable_i = 0                                                           ;
        
        #10                                                                      
        psel_i = 1                                                              ; 
        penable_i = 0                                                           ;
        pwrite_i = 1                                                            ;
        paddr_i = 8'h02                                                         ;
        pwdata_i = 8'b11110111                                                  ; //data value
        #10
        psel_i = 1                                                              ;
        penable_i = 1                                                           ;
        #10
        psel_i = 0                                                              ;
        penable_i = 0                                                           ;
        
        
        
        //cpu enable i2c core and write repeat start bit
        #10                                                                      
        psel_i = 1                                                              ; 
        penable_i = 0                                                           ;
        pwrite_i = 1                                                            ;
        paddr_i = 8'h01                                                         ;
        pwdata_i = 8'b11100000                                                  ; //cmd register
        #10
        psel_i = 1                                                              ;
        penable_i = 1                                                           ;
        #10
        psel_i = 0                                                              ;
        penable_i = 0                                                           ;
        
        
//        #3777
//        sda_slave_en = 1                                                        ;
//        sda_slave = 0                                                           ;
//        #400        
//        sda_slave_en = 0                                                        ;
//        #3200
//        sda_slave_en = 1                                                        ;
//        sda_slave = 0                                                           ;
//        #400
//        sda_slave_en = 0                                                        ;
//        #3200
//        sda_slave_en = 1                                                        ;
//        sda_slave = 0                                                           ;
//        #400
//        sda_slave_en = 0                                                        ;
        
        
//        #3200
//        sda_slave_en = 1                                                        ;
//        sda_slave = 0                                                           ;
//        #400
//        sda_slave_en = 0                                                        ;
        
        #101000
        #10
        psel_i = 1                                                              ; 
        penable_i = 0                                                           ;
        pwrite_i = 1                                                            ;
        paddr_i = 8'h04                                                         ;
        pwdata_i = 8'b10101011                                                        ; //address value
        #10
        psel_i = 1                                                              ;
        penable_i = 1                                                           ;
        #10
        psel_i = 0                                                              ;
        penable_i = 0                                                           ;
//        #10
//        psel_i = 1                                                              ; 
//        penable_i = 0                                                           ;
//        pwrite_i = 1                                                            ;
//        paddr_i = 8'h01                                                         ;
//        pwdata_i = 8'b01100100                                                  ; //cmd register
//        #10
//        psel_i = 1                                                              ;
//        penable_i = 1                                                           ;
//        #10
//        psel_i = 0                                                              ;
//        penable_i = 0                                                           ;//323
        
        
        // #674
        // #10000
        // //cpu read to status register
        // #10
        // psel_i = 1                                                              ; //#32
        // penable_i = 0                                                           ;
        // pwrite_i = 0                                                            ;
        // paddr_i = 8'h03                                                         ;
        // #10
        // psel_i = 1                                                              ;
        // penable_i = 1                                                           ;
        // #10
        // psel_i = 0                                                              ;
        // penable_i = 0                                                           ;
        
        // #10
        // psel_i = 1                                                              ; //#32
        // penable_i = 0                                                           ;
        // pwrite_i = 0                                                            ;
        // paddr_i = 8'h03                                                         ;
        // #10
        // psel_i = 1                                                              ;
        // penable_i = 1                                                           ;
        // #10
        // psel_i = 0                                                              ;
        // penable_i = 0                                                           ;
    end
    
    always #5 pclk_i = ~pclk_i                                                   ;
    always #100 i2c_core_clock_i = ~i2c_core_clock_i                              ;

endmodule