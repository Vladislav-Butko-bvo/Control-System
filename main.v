`timescale 1ns / 1ps
module spec_dig_dev(d1, d2, reset_divider_extern, reset_spec_dev_extern, clk, S1, ready);
input [0:3] d1, d2;
input reset_divider_extern, reset_spec_dev_extern, clk;
output [0:3] S1;
output reg ready;

reg [0:3] A, B, S1, S2, S3;
reg [3:0] Y;
reg reset_divider;
reg to_first_state;
reg rst_to_first_state;
reg [0:1] automat_state;
reg [0:1] automat_state2;
reg rst_spec_dev_flag;
reg rst_rst_spec_dev_flag;
reg [0:3] tmp_d1_filt, tmp_d2_filt;
reg tmp_rst_to_first_state;
reg tmp_reset_spec_dev_extern;
reg tmp_rst_rst_spec_dev_flag;

wire clk_divided;
wire [0:3] d1_filt, d2_filt; 

debounce_filter #(
    .CNTR_WIDTH(10)
) filter_d1 (
    .clock(clk),
    .reset(reset_spec_dev_extern),
    .button(d1),
    .pressed(d1_filt)
);

debounce_filter #(
    .CNTR_WIDTH(10)
) filter_d2 (
    .clock(clk),
    .reset(reset_spec_dev_extern),
    .button(d2),
    .pressed(d2_filt)
);

always @ (clk, reset_divider_extern, reset_spec_dev_extern, ready)
begin
        case({ready,
            reset_divider_extern,
            reset_spec_dev_extern})
        3'b000:  begin reset_divider <= 0; end
        3'b001:  begin reset_divider <= 0; end
        3'b010:  begin reset_divider <= 1; end
        3'b011:  begin reset_divider <= 0; end
        3'b100:  begin 
            if(to_first_state) begin
                reset_divider <= 0;
            end
            else begin
                reset_divider <= 1;
            end      
        end
        3'b101:  begin reset_divider <= 0; end
        3'b110:  begin reset_divider <= 1; end
        3'b111:  begin reset_divider <= 0; end
        endcase
end

always @ (posedge clk)
begin
        if(tmp_d1_filt != d1_filt | tmp_d2_filt != d2_filt | tmp_rst_to_first_state != rst_to_first_state) begin
		case(automat_state)
        	2'b00:  begin 
			to_first_state <= 0;
			automat_state <= 2'b11;
			end
		2'b10:  begin 
			to_first_state <= 0;
			automat_state <= 2'b01;
			end
		2'b01:  begin 
			to_first_state <= 0;
			automat_state <= 2'b11;
			end
		2'b11:  begin 
				if(rst_spec_dev_flag == 1'b0) 
					begin
					to_first_state <= 1;
					automat_state <= 2'b10;
					end 
				else   
					automat_state <= 2'b01; 
			end       
                endcase  
        end
         
	tmp_d1_filt <= d1_filt;      
	tmp_d2_filt <= d2_filt;      
	tmp_rst_to_first_state <= rst_to_first_state;
end

always @ (posedge clk)
begin
	if(tmp_reset_spec_dev_extern != reset_spec_dev_extern | tmp_rst_rst_spec_dev_flag != rst_rst_spec_dev_flag)
	begin
		case(automat_state2)
		2'b00:  begin 
			rst_spec_dev_flag <= 0;
			automat_state2 <= 2'b01;
			end
		2'b01:  begin 
			rst_spec_dev_flag <= 0;
			automat_state2 <= 2'b11;
			end
		2'b11:  begin 
			rst_spec_dev_flag <= 1;
			automat_state2 <= 2'b01;
			end
		endcase
	end	
	
	tmp_reset_spec_dev_extern <= reset_spec_dev_extern;      
	tmp_rst_rst_spec_dev_flag <= rst_rst_spec_dev_flag;  
end

divider divider1(clk,reset_divider,clk_divided);

always @ (posedge clk_divided)
begin
	if (!reset_spec_dev_extern)
		case (Y)
		0: 	begin
				A <= d1_filt;
			 	B <= d2_filt;
			 	S1 <= 0;
			 	S2 <= 0; 
			 	S3 <= 0;
			 	ready <= 0;
			 	rst_to_first_state <= 1;
			 	Y <= 1;
		 	end
		1: 	begin
			     	rst_to_first_state <= 0;
			     	rst_rst_spec_dev_flag <= 0;
				
			     	if (to_first_state) begin 
			        	Y <= 0;
			     	end   
			        else begin
				        S2 <= A << 2;
				        S1 <= A^B;
				        if(A<=9) Y <= 2;
				        else Y <= 10;
			        end
		 	end
		2: 	begin 
			    	if (to_first_state) begin 
			        	Y <= 0;
			     	end  
			    	else begin
			    	     	S3 <= B >> 3; 
			    		Y <= 3;
			    	end
		 	end  
		3: 	begin
			    	if (to_first_state) begin 
			        	Y <= 0;
			     	end  
			     	else begin
				        S3 <= S1 << 3;
				        S2 <= S2 + S3;
				        Y <= 4;
			     	end    
		 	end
		4: 	begin
			    	if (to_first_state) begin 
			        	Y <= 0;
			     	end  
			     	else begin
			         	S1 <= B << 2;
			         	S3 <= S3 + S1;
			         	Y <= 5;
			     	end    
		 	end
		5: 	begin 
			    	if (to_first_state) begin 
			        	Y <= 0;
			     	end  
			     	else begin
			        	S3 <= S3 + S2;
			        	Y <= 6;
			     	end
		   	end
		6: 	begin 
			    	if (to_first_state) begin 
			        	Y <= 0;
			     	end  
			     	else begin
			        	S1 <= S1 + B;
			        	Y <= 7;
			     	end
		    	end
		7: 	begin 
			    	if (to_first_state) begin 
			        	Y <= 0;
			     	end  
			     	else begin
			        	S1 <= A + S1;
			        	Y <= 8;
			      	end
		    	end
		8: 	begin 
		        	if (to_first_state) begin 
		        		Y <= 0;
			     	end  
			     	else begin
			        	S1 <= ~S1;
			        	Y <= 9;
			     	end   
		    	end
		9: 	begin 
		    		if (to_first_state) begin 
		        		Y <= 0;
		     		end  
		     		else begin
		        		S1 <= S1^S3;
		        		ready <= 1;
		        		Y <= 0;
		     		end   
		    	end
		10: 	begin
		    		if (to_first_state) begin 
		        		Y <= 0;
		     		end  
		     		else begin
		         		B <= B << 1;
		         		A <= A + B;
		         		Y <= 11;
		     		end    
		 	end
		11: 	begin
			        if (to_first_state) begin 
			        	Y <= 0;
			     	end  
			     	else begin
			         	A <= A >> 3;
			         	B <= B & S2;
			         	Y <= 12;
			     	end
		 	end
		12: 	begin 
			    	if (to_first_state) begin 
			        	Y <= 0;
			     	end  
			     	else begin
			        	B <= ~B;
			        	Y <= 13;
			     	end
		    	end
		 13: 	begin
		    		if (to_first_state) begin 
		        		Y <= 0;
		     		end  
		     		else begin
		        		S1 <= B | S1;
		        		Y <= 14;
		      		end  
		    	end
		 14: 	begin
		    		if (to_first_state) begin 
		        		Y <= 0;
		     		end  
		     		else begin
		        		S1 <= A + S1;
		        		ready <= 1;
		        		Y <= 0;
		     		end   
		    	end  
		endcase
	else
	begin
		A <=0; B <= 0; S1 <= 0;
		S2 <= 0; S3 <= 0;
		Y <= 0; ready <= 0;
		rst_rst_spec_dev_flag <= 1;
	end
end

endmodule

`timescale 1ns / 1ps
module divider(
    input clk,
    input reset,
    output reg clk_divided
    );
    
    reg [31:0] counter;
    
    always @ (posedge clk)
    begin
        if(!reset) begin
            counter <= counter + 1;
            if(counter == 25000000) begin
                clk_divided <= ~clk_divided;
                counter <= 0;
            end    
        end 
        else begin
            counter <= 0; 
            clk_divided <= 0;
        end
    end

endmodule

/*
 * Debounce Filter Module
 */  

module debounce_filter #(
    parameter CNTR_WIDTH = 10,
    parameter D_WIDTH = 4
)(
    input      clock,
    input      reset,
    input      [0:D_WIDTH-1] button,
    output reg [0:D_WIDTH-1] pressed
);

// 2-Flop synchroniser to transfer button signal to clock
// domain and avoid concurrency issues.
reg [D_WIDTH:0] buttonSync;
always @ (posedge clock or posedge reset) begin
    if (reset) begin
        buttonSync <= 2'b0;
    end else begin
        buttonSync <= {buttonSync[0], button};
    end
end

// Debounce Filter logic
// Requires state be stable for 2**CNTR_WIDTH cycles before
// output state is changed. 
reg [0:D_WIDTH-1] stable;
reg [CNTR_WIDTH-1:0] filter;

always @ (posedge clock or posedge reset) begin
    if (reset) begin
        filter <= 1'b0;
    end else if (stable) begin
        // Reset filter timer while stable
        filter <= 1'b0;
    end else begin
        // Otherwise let it run.
        filter <= filter + 1'b1;
    end
end

always @ (posedge clock or posedge reset) begin
    if (reset) begin
        stable      <= 'h0;
        pressed     <= 'h0;
    end else if (stable) begin
        // Button is stable, check if it has changed
        if (buttonSync != pressed) begin
            // An edge is detected, no longer stable.
            stable  <= 'h0;
        end
    end else begin
        // Button might be changing, or it might be noise
        if (buttonSync == pressed) begin
            // Returned to its old state, so assume noise.
            stable  <= 'hF;
        end else if (filter == {(CNTR_WIDTH){1'b1}}) begin
            // Counter reached top, stable for long enough to
            // update the button state.
            pressed <= buttonSync;
            stable  <= 'hF;
        end
    end
end

endmodule
