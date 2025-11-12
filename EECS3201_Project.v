// the switch game


module EECS3201_Project(
	input CLOCK_50,        // 50 MHz
    input [1:0] KEY,       // the buttons on the board 
    input [9:0] SW,        // switches  
    output [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5
	output [9:0] LEDR
);

	timer timer(CLOCK_50, ~KEY[0], HEX4, HEX5); 

endmodule


module highScore(); // every round passed = +2 points every 5 rounds passed points double

endmodule


module timer(input clk, input reset_btn, output [6:0] hex4, hex5); // timer for each round (10-15 seconds????)+ 5-10 seconds between rounds + automatically resets with each new round and when button key0 pressed. 
wire clk1Hz;
    ClockDivider cd(clk, clk1Hz);

    reg [5:0] count;        // countdown 0-30
   

    // 15 for each round and 5 for reset     
	reg [5:0] max_time;
    always @(*) begin
        if ()// if round= start max time= 15 seconds 
            max_time = 6'd15;
        else // OW max_time = 5 seconds for reset 
            max_time = 6'd05;
    end


    always @(posedge clk1Hz or posedge reset_btn) begin
        if (reset_btn)
            count <= max_time;         
        else if (!paused && count > 0)
            count <= count - 1;        
        else
            count <= count;            
    end

	// 'tens' place will be assigned to HEX0 and 'ones' place will be assigned to HEX1 
    wire [3:0] tens = count / 10;
    wire [3:0] ones = count % 10;

    // initialize HexDisplay module
    HexDisplay h0(ones, hex4);
    HexDisplay h1(tens, hex5);
endmodule

module prompts();//randomizes switch selection and uses LEDs to communicate selection 

endmodule

// the clock divider module provided on eclass 
module ClockDivider(cin, cout);
// Based on code from fpga4student.com
// cin is the input clock; if from the DE10-Lite,
// the input clock will be at 50 MHz
// The clock divider toggles cout every 25 million cycles of the input clock
    input cin;
    output reg cout;

    reg [31:0] count;
    parameter D = 32'd25000000;  

   always @(posedge cin)
begin
   count <= count + 32'd1;
      if (count >= (D-1)) begin
         cout <= ~cout;
         count <= 32'd0;
      end
end
endmodule

//HexDisplay module from my lab3 submission file
module HexDisplay(
    input [3:0] x,
    output reg [6:0] hex
);

    always @(x) begin
        case(x)
            0: hex = 7'b1000000;
            1: hex = 7'b1111001;
            2: hex = 7'b0100100;
            3: hex = 7'b0110000;
            4: hex = 7'b0011001;
            5: hex = 7'b0010010;
            6: hex = 7'b0000010;
            7: hex = 7'b1111000;
            8: hex = 7'b0000000;
            9: hex = 7'b0010000;
            10: hex = 7'b0001000;
            11: hex = 7'b0000011;
            12: hex = 7'b1000110;
            13: hex = 7'b0100001;
            14: hex = 7'b0000110;
            15: hex = 7'b0001110;
            default: hex = 7'b1111111;
        endcase
    end
endmodule