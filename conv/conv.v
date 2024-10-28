module  CONV(
	input		clk,
	input		reset,
	output	reg	busy,	
	input		ready,	
			
	output	reg [11:0]	iaddr,
	input	signed [19:0] idata,	
	
	output	 reg cwr,
	output	 reg [11:0]	caddr_wr,
	output	 reg [19:0]	cdata_wr,
	
	output	 reg	crd,
	output	 reg [11:0]	caddr_rd,
	input	 [19:0]	cdata_rd,
	
	output reg 	[2:0] 	csel
	);


	reg [11:0] image_addr;
	reg [11:0] L1_image_addr;
	reg [9:0] L1_write_addr;
	wire [11:0] L1_image_addr1;
	wire [11:0] L1_image_addr2;
	wire [11:0] L1_image_addr3;
	wire [11:0] image_addr1;
	wire [11:0] image_addr2;
	wire [11:0] image_addr3;
	wire [11:0] image_addr4;
	wire [11:0] image_addr5;
	wire [11:0] image_addr6;
	wire [11:0] image_addr7;
	wire [11:0] image_addr8;
	reg [2:0] state , next_state;
	reg [3:0] kernel_count;
	reg signed	[19:0] ker;
	reg signed [19:0] cdata_max;
	reg signed [39:0] gray_data;
	reg signed [39:0] L0_conv_data;
	wire signed [39:0] L0_round_data;
	wire signed [19:0] L0_relu_data;
	wire zero_padding;
	parameter  INIT = 3'b000 ;
	parameter  L0_READ = 3'b001 ;
	parameter  RELU = 3'b010 ;
	parameter  L0_WRITE = 3'b011 ;
	parameter  L1_INIT = 3'b100 ;
	parameter  L1_READ = 3'b101 ;
	parameter  L1_WRITE = 3'b110 ;
	parameter  FINISH = 3'b111 ;
//kernel 0
always @(posedge clk or posedge reset) begin
	if (reset) begin
		state <= INIT;
	end
	else begin
		state <= next_state;
	end
end

always@(*)begin
    case (state)
        INIT:begin
			if(ready) next_state =  L0_READ;
            else next_state = INIT;
		end 
        L0_READ :begin
			if(kernel_count == 4'd10) next_state = RELU;
			else next_state = L0_READ;
		end 
		RELU :begin
			next_state = L0_WRITE;
		end 
		L0_WRITE: begin
			if(image_addr == 12'd4095) next_state = L1_INIT;
			else next_state = L0_READ;
		end
		L1_INIT: begin
			 next_state = L1_READ;
		end
		L1_READ: begin
			 if(kernel_count ==  4'd6) next_state = L1_WRITE;
			 else next_state = L1_READ;
		end
		L1_WRITE: begin
			 if(L1_write_addr == 10'd1023) next_state = FINISH;
			 else next_state = L1_READ;
		end
        default: begin
			
		end
    endcase
end
always @(*) begin
    case (state)
        INIT: begin
                busy = 0;
				cwr =  0;
				csel = 3'b000;
				crd = 0;
				
				
        end 
        L0_READ: begin
                busy = 1;
				cwr =  0;
				csel = 3'b000;
				crd = 0; 
				
				
        end
		RELU: begin
				busy = 1;
				cwr =  0;
				csel = 3'b000;
				crd = 0;
				
				
		end
		L0_WRITE: begin
				busy = 1;
				cwr =  1;
				csel = 3'b001;
				crd = 0;
				
				
		end
		L1_INIT:begin
				busy = 1;
				cwr =  0;
				csel = 3'b000;
				crd = 0;
				
		end
		L1_READ:begin
				busy = 1;
				cwr =  0;
				csel = 3'b001;
				crd =  1;
				
		end
		L1_WRITE:begin
				busy = 1;
				cwr =  1;
				csel = 3'b011;
				crd =  0;
				
		end
        FINISH: begin
                busy = 0;
				cwr =  0;
				csel = 3'b000;
				crd = 0;
				
				
        end
        default: begin
			
		end
    endcase
end
//////// iaddr change
always @(posedge clk) begin
	if(state == INIT) begin
		image_addr <= 12'b0;

	end
	else if(state == L0_WRITE ) begin
		image_addr <= image_addr + 1;
	end

end

assign image_addr1 = image_addr-12'b000001000001;
assign image_addr2 = image_addr1+12'b000000000001;
assign image_addr3 = image_addr2+12'b000000000001;

assign image_addr4 = image_addr-12'b000000000001;
assign image_addr5 = image_addr+12'b000000000001;

assign image_addr6 = image_addr+12'b000000111111;
assign image_addr7 = image_addr6+12'b000000000001;
assign image_addr8 = image_addr7+12'b000000000001;

always @(posedge clk ) begin
	case (kernel_count)
		4'd0: 	iaddr <= image_addr;
		4'd1: 	iaddr <= image_addr1;
		4'd2: 	iaddr <= image_addr2;
		4'd3:	iaddr <= image_addr3;
		4'd4:	iaddr <= image_addr4;
		4'd5:	iaddr <= image_addr5;
		4'd6:	iaddr <= image_addr6;
		4'd7:	iaddr <= image_addr7;
		4'd8:	iaddr <= image_addr8;
		default: begin
				
		end
	endcase
end


assign zero_padding = 	 ((image_addr[11:6] == 6'b000000) && (kernel_count==4'd2||kernel_count==4'd3||kernel_count==4'd4))
						||((image_addr[11:6] == 6'b111111) && (kernel_count==4'd7||kernel_count==4'd8||kernel_count==4'd9))
						||((image_addr[5:0] == 6'b000000) && (kernel_count==4'd2||kernel_count==4'd5||kernel_count==4'd7))
						||((image_addr[5:0]	== 6'b111111) && (kernel_count==4'd4||kernel_count==4'd6||kernel_count==4'd9));
always@(*) begin
	if(reset) begin
		ker = 20'HF8F71;
	end
	else begin
		case (kernel_count)
			4'd1:	ker = 20'HF8F71;
			4'd2:	ker = 20'H0A89E;
			4'd3:	ker = 20'H092D5;
			4'd4:	ker = 20'H06D43;
			4'd5:	ker = 20'H01004;
			4'd6:	ker = 20'HF6E54;
			4'd7:	ker = 20'HFA6D7;
			4'd8:	ker = 20'HFC834;
			4'd9:	ker = 20'HFAC19;
			default:ker = 20'H00000;
		endcase
	end
end

always @(posedge clk) begin
	if(state == INIT) begin
		gray_data <= 20'sb0;

	end
	else if(state == L0_READ ) begin
		case (kernel_count)
			4'd1: 	gray_data  <= (zero_padding)?20'sb0:idata*ker;
			4'd2: 	gray_data  <= (zero_padding)?20'sb0:idata*ker;
			4'd3:	gray_data  <= (zero_padding)?20'sb0:idata*ker;
			4'd4:	gray_data  <= (zero_padding)?20'sb0:idata*ker;
			4'd5:	gray_data  <= (zero_padding)?20'sb0:idata*ker;
			4'd6:	gray_data  <= (zero_padding)?20'sb0:idata*ker;
			4'd7:	gray_data  <= (zero_padding)?20'sb0:idata*ker;
			4'd8:	gray_data  <= (zero_padding)?20'sb0:idata*ker; 
			4'd9: 	gray_data  <= (zero_padding)?20'sb0:idata*ker;
			default: begin
				gray_data  <= 20'sb0;
			end
		endcase
		
	end

end



always @(posedge clk) begin
	if(state == INIT || state == RELU || state == L1_WRITE) begin
		kernel_count <= 4'b0;
		
	end
	else if(state == L0_READ ) begin
		kernel_count <= kernel_count + 1;
	end
	else if (state == L1_READ)begin
		kernel_count <= kernel_count + 1;
	end

end


always@(posedge clk or posedge reset) 
begin
	if(reset) begin
		L0_conv_data <= 0;
    end else if (state == L0_WRITE) begin 
        L0_conv_data <= 0;       
    end else begin 
        L0_conv_data <= L0_conv_data + gray_data;
    end
end

assign L0_round_data = (state == RELU && L0_conv_data[15] ) ? 
						(L0_conv_data+40'h0013110000):(L0_conv_data+40'h0013100000);

assign L0_relu_data =  (L0_round_data>0) ? L0_round_data[35:16] :20'b0; 

always @(posedge clk or posedge reset) begin
	if(reset)begin
		cdata_wr <= 0;
	end
	else begin
		case (state)
			INIT:		cdata_wr <= 0;
			L0_READ:	cdata_wr <= 0;
			RELU:		cdata_wr <= L0_relu_data;
			L0_WRITE:	cdata_wr <= cdata_wr;
			L1_INIT:	cdata_wr <= 0;
			L1_READ:	cdata_wr <= (kernel_count == 4'd6)?cdata_max:0;
			L1_WRITE:	cdata_wr <= 0;
			FINISH: 	cdata_wr <= 0;
			default: 	cdata_wr <= 0;
		endcase
	end
end

always @(posedge clk or posedge reset) begin
	if(reset)begin
		caddr_wr <= 0;
	end
	else begin
		case (state)
			INIT:		caddr_wr <= image_addr;
			L0_READ:	caddr_wr <= image_addr;
			RELU:		caddr_wr <= image_addr;
			L0_WRITE:	caddr_wr <= image_addr;
			L1_INIT:	caddr_wr <= L1_write_addr;
			L1_READ:	caddr_wr <= L1_write_addr;
			L1_WRITE:	caddr_wr <= L1_write_addr;
			FINISH: 	caddr_wr <= 0;
			default: 	begin
				
			end
		endcase
	end
end

always @(posedge clk or posedge reset) begin
	if (reset) begin
		L1_image_addr <=12'b0; 
	end
	else if(state == L1_WRITE) begin
		if(L1_image_addr[5:0] == 6'b111110)
			L1_image_addr <= L1_image_addr +12'b000001000010;
		else 
			L1_image_addr <= L1_image_addr +12'b000000000010;	
	end
end


assign L1_image_addr1 = L1_image_addr + 12'd1;
assign L1_image_addr2 = L1_image_addr + 12'd64;
assign L1_image_addr3 = L1_image_addr + 12'd65;


always @(posedge clk or posedge reset) begin
	if (reset) begin
		L1_write_addr <= 10'b0;
	end
	else if (state == L1_WRITE)begin
		L1_write_addr <= L1_write_addr +1;
	end
end
always@(posedge clk or posedge reset) begin
	if(reset) begin
		caddr_rd = 12'b0;
	end
	else if (state == L1_READ)begin
		case (kernel_count)
			4'd1:	caddr_rd  <= L1_image_addr;
			4'd2:	caddr_rd  <= L1_image_addr1;
			4'd3:	caddr_rd  <= L1_image_addr2;
			4'd4:	caddr_rd  <= L1_image_addr3;
			default: caddr_rd <=  12'b0;
		endcase
	end
end

always@(posedge clk or posedge reset)begin
	if(reset) begin
		cdata_max <= 20'b0;
	end
	else if(state == L1_READ)begin
		case (kernel_count)
			4'd0:  	cdata_max  <= 20'b0;
			4'd1:  	cdata_max  <= 20'b0;
			4'd2:	cdata_max  <= (cdata_max >= cdata_rd)?cdata_max:cdata_rd;
			4'd3:	cdata_max  <= (cdata_max >= cdata_rd)?cdata_max:cdata_rd;
			4'd4:	cdata_max  <= (cdata_max >= cdata_rd)?cdata_max:cdata_rd;
			4'd5:	cdata_max  <= (cdata_max >= cdata_rd)?cdata_max:cdata_rd;
			default: begin
				
			end
		endcase
	end
end

endmodule
