// the switch game


module EECS3201_Project(
    input MAX10_CLK1_50,        
    input [1:0] KEY,            
    input [9:0] SW,             
    output [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5,
    output [9:0] LEDR
);

    wire checkFlag, isCorrect;
    wire chooseFlag;
    wire [9:0] ExpectedSwitchArrangement;
    wire timeout;

    // reset button
    wire reset = ~KEY[0];

    // override stop condition when reset is pressed (was having some issues with the countdown and leds not properly reseting) 
    wire adjusted_isCorrect = reset ? 1'b1 : isCorrect;

    // Timer
    timer timerInst(
        MAX10_CLK1_50, 
        reset,
        ~adjusted_isCorrect,  // stop_timer (make sure the timer properly resets) 
        HEX0, HEX1, 
        timeout
    );

    wire [9:0] ledPrompt;
    LEDPrompts LEDPromptsInst(MAX10_CLK1_50, chooseFlag, SW, ExpectedSwitchArrangement, ledPrompt);

    switchChange switchChangeInst(MAX10_CLK1_50, SW, checkFlag);

    checkSwitchArrangement checkSwitchArrangementInst(MAX10_CLK1_50, reset, checkFlag, SW, ExpectedSwitchArrangement, isCorrect, chooseFlag, HEX5, HEX4);

    // LED output: timeout or reset overrides normal LEDs
    assign LEDR = (timeout || reset) ? 10'b1111111111 : ledPrompt;
    assign HEX2 = 7'b1111111;
    assign HEX3 = 7'b1111111;



endmodule

module highScore(); // every round passed = +2 points every 5 rounds passed points double

endmodule

/*The timer lags with the switch input so if we were to have the timer reset for every correct input there would be a significant lag
to fix the lag, I altered the timer a bit so that it counts down from 20 and the user has to rack up the highest possible score in those 20 seconds
the reset button and incorrect input case still work as initially designed
Also I added a timeout case so if the timer runs out all the LEDs turn on to signal that the game is over until the reset button is pressed*/
module timer(
    input clk, 
    input reset_btn, 
    input stop_timer, 
    output [6:0] hex0, 
    output [6:0] hex1,
    output reg timeout
); 
    wire clk1Hz;
    ClockDivider cd(clk, clk1Hz);

    reg [5:0] count;        
    reg [5:0] max_time;

    always @(*) begin
        max_time = 6'd20; 
    end

    always @(posedge clk1Hz or posedge reset_btn) begin
        if (reset_btn)
            count <= max_time;         
        else if (!stop_timer && count > 0)
            count <= count - 1;        
        else
            count <= count;
    end

    always @(*) begin
        timeout = (count == 0) ? 1'b1 : 1'b0;
    end

    wire [3:0] tens = count / 10;
    wire [3:0] ones = count % 10;

    HexDisplay h0(ones, hex0);
    HexDisplay h1(tens, hex1);
endmodule

//Determines what prompts to give out for the LEDS
module LEDPrompts(
    input clk,
    input chooseFlag,
    input [9:0] currSwitchArrangement,
    output reg [9:0] newExpectedSwitchArrangement,
    output reg [9:0] newLEDarrangement
);  

	//choose random number bewteen 0-9 for the 10 switches 
    reg [3:0] rVal;
    reg [9:0] xorVal;
    reg prevChooseFlag;

	 //Initial values
    initial begin
        newExpectedSwitchArrangement = 10'b0;
        newLEDarrangement = 10'b0;
        rVal = 4'b0;
        xorVal = 10'b0;
        prevChooseFlag = 1'b1;
    end
    
    always @(posedge clk) begin //choose a new number everytime flag is changed
        if (chooseFlag != prevChooseFlag) begin
            rVal <= (rVal + 7) % 10; //not true random but will go through all combinations 0-9
            xorVal <= (10'b1 << rVal);
            newExpectedSwitchArrangement <= currSwitchArrangement ^ xorVal;
            newLEDarrangement <= xorVal; //light should be on for the switch needed
        end
        prevChooseFlag <= chooseFlag;
    end
endmodule

//Run if any switches on SW has changed
module switchChange(
    input clk, 
    input [9:0] currSwitchArrangement, 
    output reg checkFlag
);
    reg [9:0] prevSwitches;

    initial begin
        checkFlag = 1'b0;
        prevSwitches = currSwitchArrangement;
    end

    always @(posedge clk) begin
        if(prevSwitches != currSwitchArrangement)
            checkFlag <= ~checkFlag; //raise flag that switches has changed to check if switches are correct in changing or not
        prevSwitches <= currSwitchArrangement;
    end
endmodule

//Checks if current switch arrangement is the expected arrangment when checkflag is changed
//Output isCorrect lets us know if the arrangment is correct or not
module checkSwitchArrangement(
    input clk, 
    input reset,
    input checkFlag, 
    input [9:0] currSwitchArrangement, 
    input [9:0] ExpectedSwitchArrangement, 
    output reg isCorrect, 
    output reg chooseFlag, 
	 output [6:0] HEX5,
	 output [6:0] HEX4
);
    reg prevCheckFlag;
	 reg [6:0] score;

    initial begin
        prevCheckFlag = 1'b0;
		  score = 7'b0000000;
    end

    always @(posedge clk) begin
        if(reset)
            score <= 7'b0000000;
        else begin
            if (checkFlag != prevCheckFlag) begin
                if (currSwitchArrangement == ExpectedSwitchArrangement) begin
                    isCorrect <= 1'b1;
                    score <= score + 1;
                    end
                else
                    isCorrect <= 1'b0; 
                chooseFlag <= ~chooseFlag;     
            end
            prevCheckFlag <= checkFlag;
        end
    end
	wire [3:0] tens = score / 10;
    wire [3:0] ones = score % 10;

    HexDisplay h0(ones, HEX4);
    HexDisplay h1(tens, HEX5);
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

    always @(posedge cin) begin
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








