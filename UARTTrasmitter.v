module transmitter(input wire [7:0] din,
		   input wire wr_en,
		   input wire clk,
		   input wire clken,
		   output reg tx, //shift register
		   output wire tx_busy);

initial begin
	 tx = 1'b1;
end
// States for state machine
parameter TX_IDLE	= 2'b00;
parameter TX_START	= 2'b01;
parameter TX_DATA	= 2'b10;
parameter TX_STOP	= 2'b11;

reg [7:0] data = 8'h00;
reg [2:0] bitpos = 3'h0;
reg [1:0] state = TX_IDLE;

always @(posedge clk) begin
	case (state)
    // Start transmission if write_enable input is enabled
	TX_IDLE: begin
		if (wr_en) begin
			state <= TX_START;
			data <= din;
			bitpos <= 3'h0;
		end
	end
    
    // Transmit START bit if clock_enable input is enabled
	TX_START: begin
		if (clken) begin
			tx <= 1'b0;
			state <= TX_DATA;
		end
	end

    // Transmit DATA bits if clock_enable input is enabled
	TX_DATA: begin
		if (clken) begin
			if (bitpos == 3'h7)
				state <= TX_STOP;
			else
				bitpos <= bitpos + 3'h1;
			tx <= data[bitpos];
		end
	end

    // Transmit stop bit if clock_enable input is enabled
	TX_STOP: begin
		if (clken) begin
			tx <= 1'b1;
			state <= TX_IDLE;
		end
	end
    
    // Reset to idle state
	default: begin
		tx <= 1'b1;
		state <= TX_IDLE;
	end
	endcase
end

assign tx_busy = (state != TX_IDLE);

endmodule