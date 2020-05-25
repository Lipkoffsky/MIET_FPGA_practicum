`timescale 1ns / 1ps

module stopwatch #(
  parameter PULSE_MAX  =  259999,
            COUNT_MAX   = 9
            )

(
    input             clk100_i,
    input             rstn_i,
    input             start_stop_i,
    input             set_i,
    input             change_i,
    output   [6:0]    hex0_o,
    output   [6:0]    hex1_o,
    output   [6:0]    hex2_o,
    output   [6:0]    hex3_o
);

localparam RUN_STATE = 1'd1;
localparam SET_STATE = 1'd0;

reg state_stopwatch = RUN_STATE;
reg device_running;

// PULSE COUNTER
// AND 0.01 SEC PASSED
reg [16:0] pulse_counter = 17'd0;
wire hundredth_of_second_passed = ( pulse_counter == PULSE_MAX );

always @( posedge clk100_i or negedge rstn_i ) begin
  if ( !rstn_i )
    pulse_counter <= 0;
  else if ( device_running || hundredth_of_second_passed )
    if ( hundredth_of_second_passed )
      pulse_counter <= 0;
    else 
      pulse_counter <= pulse_counter + 1;
end  

// START-STOP BUTTON PRESSED
wire button_pressed;

debounce start_stop(
  .clk_i     ( clk100_i     ),
  .rst_i     ( !rstn_i      ),
  .en_i      ( start_stop_i ),
   
  .en_down_o ( button_pressed ),
  .en_up_o   (                )
);

// SET BUTTON PRESSED
wire set_pressed;
debounce set(
  .clk_i     ( clk100_i     ),
  .rst_i     ( !rstn_i      ),
  .en_i      ( set_i        ),
   
  .en_down_o ( set_pressed  ),
  .en_up_o   (              )
);

// CHANGE BUTTON PRESSED
wire change_pressed;
debounce change(
  .clk_i     ( clk100_i       ),
  .rst_i     ( !rstn_i        ),
  .en_i      ( change_i       ),
   
  .en_down_o ( change_pressed ),
  .en_up_o   (                )
);




// DEVICE RUNNING

always @( posedge clk100_i )
  if( set_pressed && ~device_running )
    state_stopwatch <= SET_STATE;
 
always @( posedge clk100_i or negedge rstn_i ) begin
      if( !rstn_i )
        device_running <= 0;
      else if ( button_pressed && state_stopwatch == RUN_STATE )
        device_running <= ~device_running;
end   

 
 // MAIN COUNTERS
 // HUNDREDTHS COUNTER
reg [3:0] hundredths_counter = 4'd0; 
wire  tenth_of_second_passed;
assign tenth_of_second_passed = ( ( hundredths_counter == COUNT_MAX ) &  hundredth_of_second_passed );
always @( posedge clk100_i or negedge rstn_i ) begin
  if ( !rstn_i )
    hundredths_counter <= 0;
  else if ( hundredth_of_second_passed )
    if ( tenth_of_second_passed )
      hundredths_counter <= 0;
    else 
      hundredths_counter <= hundredths_counter + 1;
end
 
// TENTHS COUNTER
reg [3:0] tenths_counter = 4'd0; 
wire second_passed;
assign second_passed = ( ( tenths_counter == COUNT_MAX ) & tenth_of_second_passed );
always @( posedge clk100_i or negedge rstn_i ) begin
  if ( !rstn_i ) 
    tenths_counter <= 0;
  else if ( tenth_of_second_passed )
    if ( second_passed ) 
      tenths_counter <= 0;
    else 
      tenths_counter <= tenths_counter + 1;
end
 
// SECONDS COUNTER
reg [3:0] seconds_counter = 4'd0;
wire ten_seconds_passed;
assign ten_seconds_passed = ( ( seconds_counter == COUNT_MAX ) & second_passed );
always @( posedge clk100_i or negedge rstn_i ) begin
  if ( !rstn_i )
    seconds_counter <= 0;
  else if ( second_passed )
    if ( ten_seconds_passed ) 
      seconds_counter <= 0;
    else 
      seconds_counter <= seconds_counter + 1;
end
 
 // TENS COUNTER
reg [3:0] ten_seconds_counter = 4'd0;


always @( posedge clk100_i or negedge rstn_i ) begin
  if ( !rstn_i ) 
    ten_seconds_counter <= 0;
  else if ( ten_seconds_passed )
    if ( ten_seconds_counter == COUNT_MAX )
      ten_seconds_counter <= 0;
    else 
      ten_seconds_counter <= ten_seconds_counter + 1;
end

// DECODERS
 // TEN SECONDS
wire [6:0] decoder_ten_seconds;

decoder tens(
  .data_i ( ten_seconds_counter ),
  .data_o ( decoder_ten_seconds )
);
assign hex3_o = decoder_ten_seconds;

// SECONDS
wire [6:0] decoder_seconds;

decoder d2(
  .data_i  ( seconds_counter ),
  .data_o  ( decoder_seconds )
);

assign hex2_o = decoder_seconds;

// TENTHS OF SECOND
wire [6:0] decoder_tenths;

decoder d3(
  .data_i  ( tenths_counter [3:0] ),
  .data_o  ( decoder_tenths [6:0] )
);

assign hex1_o = decoder_tenths;

// HUNDREDTHS OF SECONDS
wire [6:0] decoder_hundredths;

decoder d4(
  .data_i  ( hundredths_counter [3:0] ),
  .data_o  ( decoder_hundredths [6:0] )
);

assign hex0_o = decoder_hundredths;


// MACHINE INITIALIZATION

reg [2:0] state;
reg [2:0] next_state;   

localparam RUNNING_STATE    = 3'd0;
localparam CHANGE_HUND  = 3'd1;
localparam CHANGE_TENTH = 3'd2;
localparam CHANGE_SEC   = 3'd3;
localparam CHANGE_TEN   = 3'd4;

always @(*) 
 begin
   case ( state )
     RUNNING_STATE : if ( ( !device_running ) & ( set_pressed ) ) 
                   next_state = CHANGE_TEN;
                 else 
                   next_state = RUN_STATE;
                   
     CHANGE_HUND : if ( set_pressed ) 
                     next_state = CHANGE_TENTH;
                   else if ( change_pressed ) 
                     begin 
                       if ( hundredths_counter == 4'd9 )
                         hundredths_counter = 4'd0;
                       else
                         hundredths_counter = hundredths_counter + 1;
                         next_state = CHANGE_HUND;
                     end
                   else 
                     next_state = CHANGE_HUND;

     CHANGE_TENTH : if ( set_pressed ) 
                      next_state = CHANGE_SEC;
                    else if ( change_pressed ) 
                      begin
                        if ( tenths_counter == 4'd9 )
                          tenths_counter = 4'd0;
                        else
                          tenths_counter = tenths_counter + 1;
                          next_state = CHANGE_TENTH;
                     end
                   else 
                     next_state = CHANGE_TENTH;

     CHANGE_SEC : if ( set_pressed ) 
                    next_state = CHANGE_TEN;
                  else if ( change_pressed ) 
                    begin
                      if ( seconds_counter == 4'd9 )
                        seconds_counter = 4'd0;
                      else
                        seconds_counter = seconds_counter + 1;
                        next_state = CHANGE_SEC;
                    end
                  else 
                    next_state = CHANGE_SEC;

     CHANGE_TEN : if ( set_pressed )
                    next_state = RUNNING_STATE;
                  else if ( change_pressed ) 
                    begin
                      if ( ten_seconds_counter == 4'd9 )
                        ten_seconds_counter = 4'd0;
                      else
                        ten_seconds_counter = ten_seconds_counter + 1;
                        next_state = CHANGE_TEN;
                    end
                 else 
                   next_state = CHANGE_TEN;

     default : next_state = RUNNING_STATE;
   endcase
 end 

always @( posedge clk100_i or negedge rstn_i ) begin
if ( !rstn_i ) begin
  state                 <= RUNNING_STATE;
  ten_seconds_counter   <= 4'd0;
  seconds_counter       <= 4'd0;
  tenths_counter        <= 4'd0;
  hundredths_counter    <= 4'd0;
end
else 
  state <= next_state;
end

endmodule