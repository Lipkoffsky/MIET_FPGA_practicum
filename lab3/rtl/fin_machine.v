`timescale 1ns / 1ps


module fin_machine(
  input        clk_i,
  input        rstn_i,

  input        dev_run_i,
  input        set_i,
  input        change_i,

  output [2:0] state_value_o,
  output       inc_this_o,
  output       passed_all_o
);

  reg [2:0] state;
  reg [2:0] next_state;   
  reg       increm; 
  reg       states_is_over;
   
  localparam RUN_STATE    = 3'd0;
  localparam CHANGE_HUND  = 3'd1;
  localparam CHANGE_TENTH = 3'd2;
  localparam CHANGE_SEC   = 3'd3;
  localparam CHANGE_TEN   = 3'd4;
    
  assign state_value_o = state;
  assign passed_all = states_is_over;
   
    
  always @(*)begin
    if( rstn_i )
      increm <= 1'b0;
    case ( state )
      RUN_STATE    :  if ( !dev_run_i )
                        if ( set_i ) next_state = CHANGE_TEN;
                      else begin
                        next_state = RUN_STATE;
                        states_is_over <= 0;
                      end
      CHANGE_HUND  :  if ( set_i ) begin
                        next_state = CHANGE_TENTH;
                        states_is_over <= 1;
                      end
                      else begin 
                        if ( change_i )  increm     <= 1'b1;
                        else             increm     <= 1'b0;
                        next_state <= CHANGE_HUND;
                      end 
      CHANGE_TENTH :  if ( set_i ) next_state <= CHANGE_SEC;
                      else begin       
                        if ( change_i )  increm     <= 1'b1;
                        else             increm     <= 1'b0;
                        next_state <= CHANGE_TENTH;
                      end
      CHANGE_SEC   :  if ( set_i ) next_state <= CHANGE_TEN;
                        else begin       
                        if ( change_i )  increm     <= 1'b1;
                        else             increm     <= 1'b0;
                        next_state <= CHANGE_SEC;
                      end
      CHANGE_TEN   :  if ( set_i )     next_state <= CHANGE_HUND;
                        else begin       
                        if ( change_i )  increm     <= 1'b1;
                        else             increm     <= 1'b0;
                        next_state <= CHANGE_TEN;
                      end 
      default : next_state = RUN_STATE;
    endcase
     end 
    
  always @( posedge clk_i or posedge rstn_i ) begin
    if ( rstn_i ) begin
      state <= RUN_STATE;
    end
    else 
      state <= next_state;
  end    
  
  
  wire inc_this;
  
  debounce d(
    .clk_i     ( clk_i    ),
    .rst_i     ( rstn_i   ),
    .en_i      ( increm   ),
   
    .en_down_o ( inc_this ),
    .en_up_o   (          )
  );
  
  assign inc_this_o = inc_this;
endmodule
