module i2c_fsm_block(
    //---------------------------------------------------------            //----------------------input---------------
    input               i2c_core_clock_i                                                            , // i2c core clock
    input               enable_bit_i                                                                , // enable bit from cmd register
    input               reset_bit_n_i                                                               , // reset bit from cmd register
    input               rw_bit_i                                                                    , //rw bit from addr_rw_bit register
    input               sda_i                                                                       , // sda line input	
    input               repeat_start_bit_i                                                          , // repeat start bit from cmd register
    input               trans_fifo_empty_i                                                          , // status of trans fifo from fifo block
    input               rev_fifo_full_i                                                             , // status of rev fifo from fifo block
    input       [7:0]   state_done_time_i                                                           , //state done time 
    input       [7:0]   counter_detect_edge_i                                                       , //counter detect edge from clock generator
    input       [7:0]   counter_data_ack_i                                                          , //counter data, ack from datapath
    input       [7:0]   prescaler_i                                                                 , //value of prescaler register
    //---------------------------------------------------------             //----------------------output---------------
    							    
    output reg          start_cnt_o                                                                 , // start signal to datapath and clock generator						    
    output reg          write_addr_cnt_o                                                            , // write addr signal to datapath and clock generator to transfer addr of slave
    output reg          write_data_cnt_o                                                            , // write data signal to datapath and clock generator to transfer data
    output reg          read_data_cnt_o                                                             , // read data signal to datapath and clock generator to read data 
    output reg          write_ack_cnt_o                                                             , // after read data is done, master send ack bit
    output reg          read_ack_cnt_o                                                              , //read ack from slave
    output reg          stop_cnt_o                                                                  , // stop signal to datapath and clock generator
    output reg          repeat_start_cnt_o                                                          , // repeat start signal to datapath and clock generator
    
    output reg          write_fifo_en_o                                                             , //signal that datapath write data which read recently into receive fifo
    output reg          read_fifo_en_o                                                              , //signal that datapath read data which cpu want to send to i2c slave from transmit fifo
    					    
    output reg          scl_en_o                                                                    , // enable scl
    output reg          sda_en_o                                                                    , // enable sda
    output reg  [7:0]   counter_state_done_time_repeat_start_o                                      , //for state: repeat start
    output              ack_bit_o                                                  
    //---------------------------------------------------------
);
    localparam IDLE = 0                                                                             ;
    localparam START = 1                                                                            ;
    localparam ADDR = 2                                                                             ;
    localparam READ_ADDR_ACK = 3                                                                    ;
    localparam WRITE_DATA = 4                                                                       ;
    localparam READ_DATA = 5                                                                        ;
    localparam READ_DATA_ACK = 6                                                                    ;
    localparam WRITE_DATA_ACK = 7                                                                   ;
    localparam REPEAT_START = 8                                                                     ;
    localparam STOP = 9                                                                             ;


    reg [3:0] current_state                                                                         ;
    reg [3:0] next_state                                                                            ;
    reg [7:0] counter_state_done_time_start_stop                                                    ; //for state: start, stop
    reg       state_of_write_rx_fifo                                                                ;
    reg       state_of_read_tx_fifo                                                                 ;
    assign ack_bit_o = rev_fifo_full_i                                                              ;
    
     
    
     //register state logic
    always @(posedge i2c_core_clock_i, negedge reset_bit_n_i)
    begin
        if (~reset_bit_n_i)
                current_state <= IDLE                                                               ;
        else
            if (next_state == STOP && (current_state == READ_ADDR_ACK || current_state == READ_DATA_ACK))
                if (counter_detect_edge_i == (prescaler_i))
                    current_state <= next_state                                                     ; //update current state
                else
                    current_state <= current_state                                                  ;
            else if (next_state == REPEAT_START && (current_state == WRITE_DATA_ACK 
                    || current_state == READ_ADDR_ACK || current_state == READ_DATA_ACK))
                if (counter_detect_edge_i == prescaler_i)
                    current_state <= next_state                                                     ; //update current state
                else
                    current_state <= current_state                                                  ;
            else if (next_state == READ_ADDR_ACK && current_state == ADDR)
                if (counter_detect_edge_i == prescaler_i)
                    current_state <= next_state                                                     ; //update current state
                else
                    current_state <= current_state                                                  ;
            else if (next_state == WRITE_DATA  && (current_state == READ_ADDR_ACK || current_state == READ_DATA_ACK))
                if (counter_detect_edge_i == prescaler_i)
                    current_state <= next_state                                                     ;
                else
                    current_state <= current_state                                                  ;
            else if (next_state == WRITE_DATA_ACK && current_state == READ_DATA)
                if (counter_detect_edge_i == prescaler_i)
                    current_state <= next_state                                                     ;
                else
                    current_state <= current_state                                                  ;
            else if (next_state == READ_DATA && current_state == WRITE_DATA_ACK)
                if (counter_detect_edge_i == prescaler_i)
                    current_state <= next_state                                                     ;
                else
                    current_state <= current_state                                                  ;
            else if (next_state == READ_DATA_ACK && current_state == WRITE_DATA)                        
                if (counter_detect_edge_i == prescaler_i)
                    current_state <= next_state                                                     ;
                else
                    current_state <= current_state                                                  ;
            else
                current_state <= next_state                                                         ; //update current state
    end
    //current_state and input to next_state
    always @*
    begin
        case (current_state)
            //---------------------------------------------------------
            IDLE: begin
                if (enable_bit_i && counter_state_done_time_start_stop == 0)                        // hold 4 cylcle i2c core clock before transfer to next state
                    next_state = START                                                              ;
                else
                    next_state = IDLE                                                               ;
            end    
            //----------------------------------------------------------
            START: begin                                                                             //hold 4 cylcle i2c core clock before transfer to next state
                if (counter_state_done_time_start_stop == 1)
                    next_state = ADDR                                                               ;
                else
                    next_state = START                                                              ;
            end
            //---------------------------------------------------------
            ADDR: begin
                if (counter_data_ack_i == 1)
                    next_state = READ_ADDR_ACK                                                      ;
                else if (next_state == READ_ADDR_ACK)
                    next_state = READ_ADDR_ACK                                                      ;
                else    
                    next_state = ADDR                                                               ;
            end 
            //---------------------------------------------------------
            READ_ADDR_ACK: begin                                                                    //read ack when scl is positive edge
                if (counter_data_ack_i == 0)
                    begin
                        if (sda_i == 1)
                            if (repeat_start_bit_i == 1)
                                  next_state = REPEAT_START                                         ;
                            else
                                  next_state = STOP                                                 ;
                        else
                            if (rw_bit_i == 1)
                              next_state = READ_DATA                                                ;
                            else
                              next_state = WRITE_DATA                                               ;
                    end
                else if (next_state == STOP )
                    next_state = STOP                                                               ;
                else if (next_state == WRITE_DATA)
                    next_state = WRITE_DATA                                                         ;
                else if (next_state == REPEAT_START)
                    next_state = REPEAT_START                                                       ;
                else
                    next_state = READ_ADDR_ACK                                                      ;
            end
            //---------------------------------------------------------
            WRITE_DATA: begin                                                                        //write data   
                if (counter_data_ack_i == 1)
                    next_state = READ_DATA_ACK                                                      ;
                else if (next_state == READ_DATA_ACK)
                    next_state = READ_DATA_ACK                                                      ;
                else
                    next_state = WRITE_DATA                                                         ;
            end 
            //---------------------------------------------------------
            READ_DATA: begin                                                                          //read data  
                if (counter_data_ack_i == 1)                          
                    next_state = WRITE_DATA_ACK                                                     ;
                else if (next_state == WRITE_DATA_ACK)
                    next_state = WRITE_DATA_ACK                                                     ;
                else
                    next_state = READ_DATA                                                          ;
            end
            //---------------------------------------------------------
            READ_DATA_ACK: begin                                                                      // read ack from slave
                if (counter_data_ack_i == 0)
                        if (trans_fifo_empty_i == 1 || sda_i == 1)
                            if (repeat_start_bit_i == 1)
                              next_state = REPEAT_START                                             ;
                            else
                              next_state = STOP                                                     ;
                        else
                            next_state = WRITE_DATA                                                 ;
                else if (next_state == STOP )
                    next_state = STOP                                                               ;
                else if (next_state == WRITE_DATA)
                    next_state = WRITE_DATA                                                         ;
                else if (next_state == REPEAT_START)
                    next_state = REPEAT_START                                                       ;
                else
                    next_state = READ_DATA_ACK                                                      ;
                
            end
            //---------------------------------------------------------
            WRITE_DATA_ACK: begin                                                                       //if rev fifo is not full, continue read data
                if (counter_data_ack_i == 9 && counter_detect_edge_i == prescaler_i) 
                    if (rev_fifo_full_i == 0 )
                            next_state = READ_DATA                                                  ;
                    else
                        if (repeat_start_bit_i == 1)               
                            next_state = REPEAT_START                                               ;
                        else 
                            next_state = STOP                                                       ;
                else if (next_state == REPEAT_START)
                    next_state = REPEAT_START                                                       ;
                else if (next_state == READ_DATA)
                    next_state = READ_DATA                                                          ;
                else
                    next_state = WRITE_DATA_ACK                                                     ;
            end
            //---------------------------------------------------------
            REPEAT_START: begin
                 if (counter_state_done_time_repeat_start_o == 0)
                    next_state = ADDR                                                               ;
                else
                    next_state = REPEAT_START                                                       ;
            end
            //---------------------------------------------------------
            STOP: begin
                if (counter_state_done_time_start_stop == 0)
                    next_state = IDLE                                                               ;
                else
                    next_state = STOP                                                               ;
            end 
            //---------------------------------------------------------
            default: begin
                next_state = IDLE                                                                   ;
            end
        endcase
        
    
    end
    //current state to output
    always @*
    begin
        case (current_state)
            //---------------------------------------------------------
            IDLE: begin
                sda_en_o = 0                                                                        ;
                scl_en_o = 0                                                                        ;
                start_cnt_o = 0                                                                     ;
                write_addr_cnt_o = 0                                                                ;
                write_ack_cnt_o = 0                                                                 ;
                read_ack_cnt_o = 0                                                                  ;
                write_data_cnt_o = 0                                                                ;
                read_data_cnt_o = 0                                                                 ;
                stop_cnt_o = 0                                                                      ;
                repeat_start_cnt_o = 0                                                              ;
            end
            //---------------------------------------------------------
            START: begin  
                sda_en_o = 1                                                                        ;
                scl_en_o = 0                                                                        ;
                start_cnt_o = 1                                                                     ; //fsm inform to data_path and clock_gen generate start condition
                write_addr_cnt_o = 0                                                                ;
                write_ack_cnt_o = 0                                                                 ;
                read_ack_cnt_o = 0                                                                  ;
                write_data_cnt_o = 0                                                                ;
                read_data_cnt_o = 0                                                                 ;
                stop_cnt_o = 0                                                                      ;
                repeat_start_cnt_o = 0                                                              ;
            end
            //---------------------------------------------------------
            ADDR: begin
                sda_en_o = 1                                                                        ;
                scl_en_o = 1                                                                        ;
                start_cnt_o = 0                                                                     ;
                write_addr_cnt_o = 1                                                                ; //signal to datapath write addr of slave in sda line
                write_ack_cnt_o = 0                                                                 ;
                read_ack_cnt_o = 0                                                                  ;
                write_data_cnt_o = 0                                                                ;
                read_data_cnt_o = 0                                                                 ;
                stop_cnt_o = 0                                                                      ;
                repeat_start_cnt_o = 0                                                              ;
            
            end
            //---------------------------------------------------------
            READ_ADDR_ACK: begin
                sda_en_o = 0                                                                        ;
                scl_en_o = 1                                                                        ;
                start_cnt_o = 0                                                                     ;
                write_addr_cnt_o = 0                                                                ;
                write_ack_cnt_o = 0                                                                 ;
                read_ack_cnt_o = 1                                                                  ;
                write_data_cnt_o = 0                                                                ;
                read_data_cnt_o = 0                                                                 ;
                stop_cnt_o = 0                                                                      ;
                repeat_start_cnt_o = 0                                                              ;
            end
            //---------------------------------------------------------
            WRITE_DATA: begin
                sda_en_o = 1                                                                        ;
                scl_en_o = 1                                                                        ;
                start_cnt_o = 0                                                                     ;
                write_addr_cnt_o = 0                                                                ;
                write_ack_cnt_o = 0                                                                 ;
                read_ack_cnt_o = 0                                                                  ;
                write_data_cnt_o = 1                                                                ; //signal to datapath write data in sda line
                read_data_cnt_o = 0                                                                 ;
                stop_cnt_o = 0                                                                      ;
                repeat_start_cnt_o = 0                                                              ;
            end
            //---------------------------------------------------------
            READ_DATA: begin
                sda_en_o = 0                                                                        ;
                scl_en_o = 1                                                                        ;
                start_cnt_o = 0                                                                     ;
                write_addr_cnt_o = 0                                                                ;
                write_ack_cnt_o = 0                                                                 ;
                read_ack_cnt_o = 0                                                                  ;
                write_data_cnt_o = 0                                                                ;
                read_data_cnt_o = 1                                                                 ; //signal to datapath read data in sda line when scl in positive edge
                stop_cnt_o = 0                                                                      ;
                repeat_start_cnt_o = 0                                                              ;
            end
            //---------------------------------------------------------
            READ_DATA_ACK: begin
                sda_en_o = 0                                                                        ;
                scl_en_o = 1                                                                        ;
                start_cnt_o = 0                                                                     ;
                write_addr_cnt_o = 0                                                                ;
                write_ack_cnt_o = 0                                                                 ;
                read_ack_cnt_o = 1                                                                  ;
                write_data_cnt_o = 0                                                                ;
                read_data_cnt_o = 0                                                                 ;
                stop_cnt_o = 0                                                                      ;
                repeat_start_cnt_o = 0                                                              ;
            end
            //---------------------------------------------------------
            WRITE_DATA_ACK: begin
                sda_en_o = 1                                                                        ;
                scl_en_o = 1                                                                        ;
                start_cnt_o = 0                                                                     ;
                write_addr_cnt_o = 0                                                                ;
                write_ack_cnt_o = 1                                                                 ; //signal to data_path write ack in sda line
                read_ack_cnt_o = 0                                                                  ;
                write_data_cnt_o = 0                                                                ;
                read_data_cnt_o = 0                                                                 ;
                stop_cnt_o = 0                                                                      ;
                repeat_start_cnt_o = 0                                                              ;
            end
            //---------------------------------------------------------
            REPEAT_START: begin
                sda_en_o = 1                                                                        ;
                if (counter_state_done_time_repeat_start_o <= prescaler_i)
                    scl_en_o = 0                                                                    ;
                else
                    scl_en_o = 1                                                                    ;
                start_cnt_o = 0                                                                     ;
                write_addr_cnt_o = 0                                                                ;
                write_ack_cnt_o = 0                                                                 ;
                read_ack_cnt_o = 0                                                                  ;
                write_data_cnt_o = 0                                                                ;
                read_data_cnt_o = 0                                                                 ;
                stop_cnt_o = 0                                                                      ;
                repeat_start_cnt_o = 1                                                              ; //signal to both data_path and clock_gen to generate repeat start condition
            end
            //---------------------------------------------------------
            STOP: begin
                sda_en_o = 1                                                                        ;
                if (counter_state_done_time_start_stop <= state_done_time_i - 1)
                    scl_en_o = 0                                                                    ;
                else
                    scl_en_o = 1                                                                    ;
                start_cnt_o = 0                                                                     ;
                write_addr_cnt_o = 0                                                                ;
                write_ack_cnt_o = 0                                                                 ;
                read_ack_cnt_o = 0                                                                  ;
                write_data_cnt_o = 0                                                                ;
                read_data_cnt_o = 0                                                                 ;
                stop_cnt_o = 1                                                                      ; //signal to both data_path and clock_gen to generate stop condition
                repeat_start_cnt_o = 0                                                              ;
            end
            //---------------------------------------------------------
             default: begin
                sda_en_o = 0                                                                        ;
                scl_en_o = 0                                                                        ;
                start_cnt_o = 0                                                                     ;
                write_addr_cnt_o = 0                                                                ;
                write_ack_cnt_o = 0                                                                 ;
                write_data_cnt_o = 0                                                                ;
                read_ack_cnt_o = 0                                                                  ;
                read_data_cnt_o = 0                                                                 ;
                stop_cnt_o = 0                                                                      ;
                repeat_start_cnt_o = 0                                                              ;
            end
        endcase
    end
    
    // counter state done time for start, stop condition
     always @(posedge i2c_core_clock_i, negedge reset_bit_n_i)
     begin
        
        if (~reset_bit_n_i)
            counter_state_done_time_start_stop <= state_done_time_i                                 ;
        else       
                if (next_state == IDLE && current_state == STOP && enable_bit_i == 1)
                      counter_state_done_time_start_stop <= 2 *state_done_time_i                    ;
                else if (current_state == IDLE                                                             //in IDLE state, when master get enable bit-- 
                    && enable_bit_i == 1 && counter_state_done_time_start_stop != 0)                  //--start counter clock (detail in current_state and input to next_state)
                    counter_state_done_time_start_stop <= counter_state_done_time_start_stop - 1    ;
                else if ((current_state == START || current_state == STOP)
                        && counter_state_done_time_start_stop != 0 && counter_detect_edge_i > (prescaler_i - 1)) //in start or stop state, start counter clock 
                    counter_state_done_time_start_stop <= counter_state_done_time_start_stop - 1    ;
                else if (counter_state_done_time_start_stop == 0 
                        || (current_state == ADDR && counter_state_done_time_start_stop == 1))   
                    counter_state_done_time_start_stop <= state_done_time_i                         ;
                else
                    counter_state_done_time_start_stop <= counter_state_done_time_start_stop        ;
    end
    
    // counter state done time for repeat start condition
     always @(posedge i2c_core_clock_i, negedge reset_bit_n_i)
     begin
        
        if (~reset_bit_n_i)
            counter_state_done_time_repeat_start_o <= prescaler_i + 1                               ;
        else
            if (current_state == REPEAT_START && counter_state_done_time_repeat_start_o != 0 
                && counter_detect_edge_i > (prescaler_i - 1))                                         //in repeat_start state, start counter clock 
                counter_state_done_time_repeat_start_o <= counter_state_done_time_repeat_start_o - 1;
            else if (next_state == REPEAT_START && (current_state == READ_DATA_ACK 
                    || current_state == READ_ADDR_ACK || current_state == WRITE_DATA_ACK))   
                counter_state_done_time_repeat_start_o <= prescaler_i + 1                           ;
    end
    
    //output control signals to trans fifo block
    always @(posedge i2c_core_clock_i, negedge reset_bit_n_i) 
    begin
        if (~reset_bit_n_i)
            begin
                read_fifo_en_o <= 0                                                                 ;
                state_of_read_tx_fifo <= 0                                                          ;
            end
        else
            begin
                if (next_state == READ_DATA_ACK && current_state == WRITE_DATA && state_of_read_tx_fifo == 0)
                    begin
                        read_fifo_en_o <= 1                                                         ;
                        state_of_read_tx_fifo <= 1                                                  ;
                    end
                else 
                    read_fifo_en_o <= 0                                                             ;
                if (current_state == next_state)
                    state_of_read_tx_fifo <= 0                                                      ;
            end
    end

    //output control signals to receive fifo block
    always @(posedge i2c_core_clock_i, negedge reset_bit_n_i) 
    begin
        if (~reset_bit_n_i)
            begin
                write_fifo_en_o <= 0                                                                ;
                state_of_write_rx_fifo <= 0                                                         ;
            end
        else
            begin
                if (next_state == WRITE_DATA_ACK && current_state == READ_DATA && state_of_write_rx_fifo == 0) //prepare data from trans fifo to send to slave
                    begin
                        write_fifo_en_o <= 1                                                        ;
                        state_of_write_rx_fifo <= 1                                                 ;
                    end
                else
                    write_fifo_en_o <= 0                                                            ;
                if (next_state == current_state)
                    state_of_write_rx_fifo <= 0                                                     ;
                
            end
    end
    
endmodule 