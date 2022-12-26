module receiver(
  input wire serial_in,
  output reg ready,
  input wire ready_clear, 
  input wire clk, 
  input wire clock_enable,
  output reg [7:0] received_data 
);

initial begin
  // Initialize ready and received_data outputs to 0
  ready = 0;
  received_data = 8'b0;
end
//state machines
parameter RX_START = 2'b00;
parameter RX_DATA = 2'b01;  
parameter RX_STOP = 2'b10;  

reg [1:0] current_state = RX_START;
reg [3:0] current_sample = 0;
reg [3:0] current_bit = 0;
reg [7:0] temporary_data = 8'b0;

// State machines to process serial input data
always @(posedge clk) begin
  if (ready_clear)
    ready <= 0;

  // Process input data if clock_enable input is asserted
  if (clock_enable) begin
    // State machine to process serial input data
    case (current_state)
      RX_START: begin
        // Start counting samples from the first low sample
        if (!serial_in || current_sample != 0)
          current_sample <= current_sample + 4'b1;

        // Start collecting data bits once a full bit has been sampled
        if (current_sample == 15) begin
          current_state <= RX_DATA;
          current_bit <= 0;
          current_sample <= 0;
          temporary_data <= 0;
        end
      end

      RX_DATA: begin
        // Increment sample count and collect data bits
        current_sample <= current_sample + 4'b1;
        if (current_sample == 4'h8) begin
          temporary_data[current_bit[2:0]] <= serial_in;
          current_bit <= current_bit + 4'b1;
        end
        // Transition to stop state once all data bits have been collected
        if (current_bit == 8 && current_sample == 15)
          current_state <= RX_STOP;
      end

      RX_STOP: begin
        /*
         * Wait for a full stop bit or until we're at least half way
         * through the stop bit before transitioning back to start state
         */
        if (current_sample == 15 || (current_sample >= 8 && !serial_in)) begin
          current_state <= RX_START;
          received_data <= temporary_data;
          ready <= 1'b1;
          current_sample <= 0;
        end else begin
          current_sample <= current_sample + 4'b1;
        end
      end

      default: begin
        current_state <= RX_START;
      end
    endcase
  end
end

endmodule