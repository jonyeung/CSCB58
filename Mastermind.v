//Tito Ku 1001521775
//Jonathan Man Hon Yeung 1002090532

`timescale 1ns / 1ns


module Mastermind(SW, HEX0, HEX1, HEX2, HEX3, HEX6, HEX7, LEDR, LEDG, KEY, CLOCK_50);
	input [17:0] SW;
	input [3:0] KEY;
	input CLOCK_50;
	output [17:0] LEDR;
	output [8:0] LEDG;
	output [6:0] HEX0, HEX1, HEX2, HEX3, HEX6, HEX7;
	wire [3:0] seq0, seq1, seq2, seq3;
	wire [15:0] fullseq = {seq3, seq2, seq1, seq0};   // the wire containing the full loaded sequence
	wire [11:0] existcomp0 = {seq3, seq2, seq1};      // the wire holding characters 3, 2, 1 of the loaded seq   // these existcomp wires are used to pass into the existcomparators to segment the full sequence
	wire [11:0] existcomp1 = {seq3, seq2, seq0};      // the wire holding characters 3, 2, 0 of the loaded seq
	wire [11:0] existcomp2 = {seq3, seq1, seq0};      // the wire holding characters 3, 1, 0 of the loaded seq
	wire [11:0] existcomp3 = {seq2, seq1, seq0};      // the wire holding characters 2, 1, 0 of the loaded seq
	wire [3:0] greenleds = {LEDG[0], LEDG[1], LEDG[2], LEDG[3]};     // the wire holding the bit values of the four green leds
	wire win;   						// wire to connect the win condition to the rate divider which will halt the timer when the game is won
	wire [27:0] rd1_out;    		// rate divider output, fed into timer
	reg Enable;  						// used along with rd1_out to slow down natural clock, fed into timer
	wire [3:0] dc0_out, dc1_out;  // output of timers, fed into hex displays
	// wire disarmed; 
	
	fourbitreg setval0(    // set the sequence value for the first character
					.clock(KEY[3]),
					.d(SW[3:0]),
					.reset_n(SW[16]),
					.q(seq0)
					);
	
	fourbitreg setval1(   // set the sequence value for the second character
					.clock(KEY[3]),
					.d(SW[7:4]),
					.reset_n(SW[16]),
					.q(seq1)
					);
	
	fourbitreg setval2(   // set the sequence value for the third character
					.clock(KEY[3]),
					.d(SW[11:8]),
					.reset_n(SW[16]),
					.q(seq2)
					);
	
	fourbitreg setval3(   // set the sequence value for the fourth character
					.clock(KEY[3]),
					.d(SW[15:12]),
					.reset_n(SW[16]),
					.q(seq3)
					);
					
					
// This was used to keep track of sequence that was set to be guessed and that our guess actually matched for debugging purpose
//	hex_decoder h4(   // DEBUG
//					.hex_digit(seq0),
//					.segments(HEX4)
//					);
//	hex_decoder h5(   // DEBUG
//					.hex_digit(seq1),
//					.segments(HEX5)
//					);
//	hex_decoder h6(   // DEBUG
//					.hex_digit(seq2),
//					.segments(HEX6)
//					);
//	hex_decoder h7(   // DEBUG
//					.hex_digit(seq3),
//					.segments(HEX7)
//					);
					
					
	hex_decoder h0(       // display the current selected character of the first four bits
					.hex_digit(SW[3:0]),
					.segments(HEX0)
					);
	hex_decoder h1(       // display the current selected character of the second four bits
					.hex_digit(SW[7:4]),
					.segments(HEX1)
					);
	hex_decoder h2(       // display the current selected character of the third four bits
					.hex_digit(SW[11:8]),
					.segments(HEX2)
					);
	hex_decoder h3(       // display the current selected character of the fourth four bits
					.hex_digit(SW[15:12]),
					.segments(HEX3)
					);
					
	existcomparator existslot0(  // check if the first selected character exists in the sequence
					.clock(KEY[0]),
					.guess(SW[3:0]),
					.seq(existcomp0),
					.light(LEDR[0])
					);
					
	existcomparator existslot1(  // check if the second selected character exists in the sequence
					.clock(KEY[0]),
					.guess(SW[7:4]),
					.seq(existcomp1),
					.light(LEDR[1])
					);
	
	existcomparator existslot2(  // check if the third selected character exists in the sequence
					.clock(KEY[0]),
					.guess(SW[11:8]),
					.seq(existcomp2),
					.light(LEDR[2])
					);
	
	existcomparator existslot3(  // check if the fourth selected character exists in the sequence
					.clock(KEY[0]),
					.guess(SW[15:12]),
					.seq(existcomp3),
					.light(LEDR[3])
					);	

	slotcomparator compslots0(  // check if the first selected character is the correct value for first slot
					.clock(KEY[0]),
					.guess(SW[3:0]),
					.seq(seq0),
					.light(LEDG[0])
					);
					
	slotcomparator compslots1(  // check if the second selected character is the correct value for the second slot
					.clock(KEY[0]),
					.guess(SW[7:4]),
					.seq(seq1),
					.light(LEDG[1])
					);
		
	slotcomparator compslots2(  // check if the third selected character is the correct value for the third slot
					.clock(KEY[0]),
					.guess(SW[11:8]),
					.seq(seq2),
					.light(LEDG[2])
					);

	slotcomparator compslots3(  // check if the fourth selected character is the correct value for the fourth slot
					.clock(KEY[0]),
					.guess(SW[15:12]),
					.seq(seq3),
					.light(LEDG[3])
					);
				
		
	
	check_win_condition(   // checks to see if all green lights are on        ie. you won the game
					.leds(greenleds),
					.out(win)
					);
	
	RateDivider rd01(CLOCK_50, rd1_out, 1, 1'b1, 28'b0010111110101111000001111111, win);    // rate divider to make the timer tick down at one second intervals (more or less)
	
	always @(*)
	begin
		case(SW[17])
			1'b1: Enable = (rd1_out == 28'b0000000000000000000000000000) ? 1'b1 : 1'b0;
			default: Enable = 1'b0;
		endcase
	end
	
	DisplayCounter dc0(CLOCK_50, dc0_out, SW[16], Enable, dc1_out); // logic to display the first digit of our counter
	DisplayCounterCarry  dc1(CLOCK_50, dc1_out, SW[16], Enable, dc0_out); // logic to displays our second digit of our counter
	hex_decoder hx6(dc0_out, HEX6); // what converts the DisplayCounter output to hexdisplay
	hex_decoder hx7(dc1_out, HEX7); // what converts the DisplayCounterCarry output to hexdisplay

//	disarm disarm0(greenleds, disarmed);
//	arm arm0(SW[17], LEDR[17], disarmed);
	
endmodule


//module arm(clk, led, disarmed);
//	input clk, disarmed;
//	output reg led;
//	
//	always@(posedge clk)
//	begin
//		if (disarmed == 1'b1)
//			led = 0;
//		else
//			led = 1;
//	end
//endmodule
//
//module disarm(leds, disarmed);
//	input [3:0] leds;
//	output reg disarmed;
//	
//	always@(*)
//	begin
//		if (leds == 4'b1111)
//			disarmed <= 1'b1;
//		else
//			disarmed <= 1'b0;
//	end
//endmodule

// our logic to where we check if the guess digit is somewhere in the sequence
module existcomparator(clock, guess, seq, light);
	input clock;
	input [3:0] guess;
	input [11:0] seq;
	output reg light = 0;  // red light
	
	always @(posedge clock)    // check if the current character in this sequence slot exists in the guess input
	begin
		if (guess == seq[3:0])  // turn the light on if the character selected by guess matches any of the 4 bits of seq
			light = 1;
		else if (guess == seq[7:4])
			light = 1;
		else if (guess == seq[11:8])
			light = 1;
		else
			light = 0;
	end
			
		
endmodule

// our logic to where we check if the guess digit is exactly the same as the sequence digit
module slotcomparator(clock, guess, seq, light);
	input clock;
	input [3:0] guess;
	input [3:0] seq;
	output reg light = 0;  // green light
	
	always @(posedge clock)  // check if the current character in this sequence slot exists in the guess input
	begin
		if (guess == seq)     // turn the light on if the character is an exact match with the sequence
			light = 1;
		else
			light = 0;
	end
			
		
endmodule

// our logic to store each digit of the four digit sequence
module fourbitreg(clock, d, reset_n, q);
  input clock;
  input [1:0] reset_n;
  input [3:0] d;
  output reg [3:0] q;
  always @(posedge clock)
  begin
    if (reset_n == 1'b0) 
      q <= q; // maintain the value
    else 
      q <= d; // store value of d in the register
  end
endmodule

// generic hex_decoder taken from the labs to show output on hex displays
module hex_decoder(hex_digit, segments);
    input [3:0] hex_digit;
    output reg [6:0] segments;
   
    always @(*)
        case (hex_digit)
            4'h0: segments = 7'b100_0000;
            4'h1: segments = 7'b111_1001;
            4'h2: segments = 7'b010_0100;
            4'h3: segments = 7'b011_0000;
            4'h4: segments = 7'b001_1001;
            4'h5: segments = 7'b001_0010;
            4'h6: segments = 7'b000_0010;
            4'h7: segments = 7'b111_1000;
            4'h8: segments = 7'b000_0000;
            4'h9: segments = 7'b001_1000;
            4'hA: segments = 7'b000_1000;
            4'hB: segments = 7'b000_0011;
            4'hC: segments = 7'b100_0110;
            4'hD: segments = 7'b010_0001;
            4'hE: segments = 7'b000_0110;
            4'hF: segments = 7'b000_1110;   
            default: segments = 7'h7f;
        endcase
endmodule

// checks to see if the user has won by checking if all four green leds are on
module check_win_condition(leds, out);
	input [3:0] leds;
	output reg out;
	always @(*)
	begin
		if (leds == 4'b1111)
			out <= 1;
		else
			out <= 0;
	end
endmodule

// rate divider module taken from lab 4 to slow down the natural clock
module RateDivider(clk, Q, clear, enable, d, load);
	input clk, enable, clear, load;
	input [27:0] d;
	output [27:0] Q;
	reg [27:0] Q;
	always @(posedge clk)
	begin
		if(clear == 1'b0)
			Q <= 0;
		else if(load == 1'b1)
			Q <= d;
		else if(Q == 28'b0000000000000000000000000000)
			Q <= d;
		else if(enable == 1'b1)
			Q <= Q - 1'b1;
		else if(enable == 1'b0)
			Q <= Q;
	end
endmodule

// first digit of the timer (right)
module DisplayCounter(clk, Q, clear, enable, check);
	input clk, enable, clear;
	input [3:0] check;
	output [3:0] Q;
	reg [3:0] Q = 4'b1001;
	
	always @(posedge clk)
	begin
		if(clear == 1'b1)   // set Q to 9
			Q <= 4'b1001;
		else if(enable == 1'b1)  
			if (Q == 0)                 // if Q hits 0
				if (check != 4'b0000)	 	// and as well if the check (left digit of the counter) is not 0
					Q <= 4'b1001;         		// then reset to 9
				else
					Q <= Q;					 		// otherwise hold at 0
			else if (Q != 0)
				Q <= Q - 1'b1;           // decrement
		else if(enable == 1'b0)
			Q <= Q;
	end
endmodule

// second digit of the timer (left)
module DisplayCounterCarry(clk, Q, clear, enable, Qcarry);
	input clk, enable, clear;
	input [3:0] Qcarry;
	output [3:0] Q;
	reg [3:0] Q = 4'b1001;
	
	always @(posedge clk)
	begin
		if(clear == 1'b1)         // set Q to 9
			Q <= 4'b1001;
		else if(Qcarry == 4'b0000)   // if first digit reaches 0
			if (Q == 0)                // hold Q if Q is 0
				Q <= Q;
			else if (enable == 1'b1)   // otherwise decrement
				Q <= Q - 1'b1;
		else if(enable == 1'b0)
			Q <= Q;
	end
endmodule



