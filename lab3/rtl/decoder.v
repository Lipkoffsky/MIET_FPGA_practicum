`timescale 1ns / 1ps

module decoder(
  input      [3:0] data_i,
  
  output     [6:0] data_o
);

  reg [6:0] data;

  always @ ( * ) begin
    case ( data_i [3:0] )
      4'd0   :    data = 7'b100_0000;
      4'd1   :    data = 7'b111_1001;
      4'd2   :    data = 7'b010_0100;
      4'd3   :    data = 7'b011_0000;
      4'd4   :    data = 7'b001_1001;
      4'd5   :    data = 7'b001_0010;
      4'd6   :    data = 7'b000_0010;
      4'd7   :    data = 7'b111_1000;
      4'd8   :    data = 7'b000_0000;
      4'd9   :    data = 7'b001_0000;
      default:    data = 7'b111_1111;
    endcase
  end

  assign data_o = data;

endmodule

