// the switch game


module EECS3201_Project(
    input MAX10_CLK1_50,        
    input [1:0] KEY,            
    input [9:0] SW,             
    output [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5,
    output [9:0] LEDR
);

    wire playGame;
    wire [9:0] ExpectedSwitchArrangement;
    wire timeout;

    // reset button
    wire reset = ~KEY[0];

    // override stop condition when reset is pressed (was having some issues with the countdown and leds not properly reseting) 
    wire adjusted_isCorrect = reset ? 1'b1 : playGame;

    // Timer
    timer timerInst(
        MAX10_CLK1_50, 
        reset,
        ~adjusted_isCorrect,  // stop_timer (make sure the timer properly resets) 
        HEX0, HEX1, 
        timeout
    );

    //Gameplay
    gameplay playingTheGame(MAX10_CLK1_50, reset, timeout, SW, HEX4, HEX5, LEDR, playGame);

    assign HEX2 = 7'b1111111;
    assign HEX3 = 7'b1111111;



endmodule

module gameplay(
    input clk,
    input reset,
    input timeout,
    input [9:0] currSwitchArrangement,
    output [6:0] HEX4, HEX5,
    output [9:0] LEDR,  
    output reg playgame
);

    reg [1:0] state;
    //0 = choose prompt
    //1 = wait for switch change, compare new switch arrangement to old, add or subtract points
    //2 = game ends
     
    reg [9:0] newLEDarrangement, originalSwitches;

    //state == 0 variables 
    reg [9:0] newExpectedSwitchArrangement;
    reg [3:0] rVal; //random value
    reg [9:0] xorVal;

    //state == 1 variables
    reg [9:0] prevSwitches;
    reg [6:0] score;

    always @(posedge clk or posedge reset) begin
        if(reset) begin
            state <= 2'b0;
            originalSwitches <= currSwitchArrangement;
            newExpectedSwitchArrangement <= currSwitchArrangement;
            newLEDarrangement <= 10'b1111111111;
            rVal <= 4'b0;
            xorVal <= 10'b0;

            prevSwitches <= currSwitchArrangement;
            score <= 7'b0000000;

            playgame <= 1'b1;
        end
        else if (timeout) begin
            //Game over due to timeout
            state <= 2'b10;
            newLEDarrangement <= 10'b1111111111;
            playgame <= 1'b0;
        end
        else begin
            case(state)
                2'b00: begin //Choosing prompt state
                    rVal <= (rVal + 7) % 10; //not true random but will go through all combinations 0-9
                    xorVal <= (10'b1 << rVal);
                    originalSwitches <= currSwitchArrangement;
                    newExpectedSwitchArrangement <= originalSwitches ^ xorVal;
                    newLEDarrangement <= xorVal; //light should be on for the switch needed
                    prevSwitches <= currSwitchArrangement;
                    state <= 2'b01;
                end
                
                2'b01: begin // Waiting for switch change
                    newLEDarrangement <= xorVal;
                    newExpectedSwitchArrangement <= originalSwitches ^ xorVal;

                    if(prevSwitches != currSwitchArrangement) begin
                        if (currSwitchArrangement == newExpectedSwitchArrangement) begin
                            //Correct answer
                            score <= score + 1;
                            state <= 2'b00; // Get new prompt
                        end
                        else begin
                            //Wrong answer
                            state <= 2'b10;
                            newLEDarrangement <= 10'b1111111111;
                            playgame <= 1'b0;
                        end
                    end
                end
                
                2'b10: begin // Game ended state
                    newLEDarrangement <= 10'b1111111111;
                    playgame <= 1'b0;
                end
            endcase
        end
    end

    wire [3:0] tens = score / 10;
    wire [3:0] ones = score % 10;
     
    HexDisplay h0(ones, HEX4);
    HexDisplay h1(tens, HEX5);
    
    assign LEDR = newLEDarrangement;

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
