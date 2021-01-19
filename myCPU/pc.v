`timescale 1ns / 1ps


module pc #(parameter WIDTH = 8)(
	input wire clk,rst,en,clr,
	input wire[WIDTH-1:0] d,
	input wire[WIDTH-1:0] t,
	output reg[WIDTH-1:0] q
    );
	always @(posedge clk,posedge rst) begin
		if(rst) begin
			q <=  32'hbfc00000;
		end else if(clr) begin
			q <= t;
		end else if(en) begin
			/* code */
			q <= d;
		end
	end
endmodule