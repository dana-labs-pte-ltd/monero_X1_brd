module random_math(
                input wire              clk,
                input wire              reset_n,
                input wire              start,//start 

                input wire [31:0]       in_r0_0,
                input wire [31:0]       in_r0_1,
                input wire [31:0]       in_r0_2,
                input wire [31:0]       in_r0_3,
                input wire [31:0]       in_r0_4,
                input wire [31:0]       in_r0_5,
                input wire [31:0]       in_r0_6,
                input wire [31:0]       in_r0_7,
                input wire [31:0]       in_r0_8,
                
                output reg  [6:0]       random_ram_addr,
                input wire  [55:0]      random_ram_rdata,
 
                output reg              random_ack,
                output wire  [31:0]     out_r0_0,
                output wire  [31:0]     out_r0_1,
                output wire  [31:0]     out_r0_2,
                output wire  [31:0]     out_r0_3
                ); 

reg     [31:0]  r0 [0:8];

wire    [7:0]   op_code = random_ram_rdata[55:48];
wire    [7:0]   dst_index = random_ram_rdata[47:40];
wire    [7:0]   src_index = random_ram_rdata[39:32];
wire    [31:0]  op_data = random_ram_rdata[31:0];

(*mark_debug = "true"*)reg     [2:0]   cs_state;
(*mark_debug = "true"*)reg     [2:0]   ns_state;

parameter s_idle = 3'b001;
parameter s_run = 3'b010;
parameter s_ret = 3'b100;

parameter MUL   = 0;	// a*b
parameter ADD   = 1;	// a+b + C, C is an unsigned 32-bit constant
parameter SUB   = 2;	// a-b
parameter ROR   = 3;	// rotate right "a" by "b & 31" bits
parameter ROL   = 4;	// rotate left "a" by "b & 31" bits
parameter XOR   = 5;	// a^b
parameter RET   = 6;	// finish execution

//reg [31:0]    shift_0;
//reg [31:0]    shift_1;
//assign shift_0 = r0[src_index] & 5'h1f;
//assign shift_1 = 32-r0[src_index] & 5'h1f;//(32-shift_0) & 5'h1f;

assign out_r0_0 =r0[0];
assign out_r0_1 =r0[1];
assign out_r0_2 =r0[2];
assign out_r0_3 =r0[3];

//the output random_ack signal
always@(posedge clk or negedge reset_n)
begin
    if(~reset_n)begin
        random_ack <= 1'b0;
        random_ram_addr <= 7'h0;
    end
    else begin
        if(ns_state == s_ret)begin
            random_ack <= 1'b1;
        end else begin
            random_ack <= 1'b0;
        end
        if(ns_state == s_run) begin
            random_ram_addr <= random_ram_addr + 1;
        end
        else if(ns_state == s_idle) begin
            random_ram_addr <= 7'h0;
        end
    end
end

//cs state 
always@(posedge clk or negedge reset_n)
begin
    if(~reset_n)begin
        cs_state <= s_idle;
    end
    else begin
        cs_state <= ns_state;
    end
end

//ns state
always@(*)
begin
    ns_state = cs_state;
    case(cs_state)
    s_idle:begin
        if(start) begin
            ns_state = s_run;
        end
    end
    
    s_run:begin
        if(op_code == RET) begin
            ns_state = s_ret;
        end
    end
    
    s_ret:begin
        ns_state = s_idle;
    end

    default:ns_state = s_idle;
    endcase
end

//operation
always@(posedge clk or negedge reset_n)
begin
    if(~reset_n)begin
        r0[0]   <=  32'h0;
        r0[1]   <=  32'h0;
        r0[2]   <=  32'h0;
        r0[3]   <=  32'h0;
        r0[4]   <=  32'h0;
        r0[5]   <=  32'h0;
        r0[6]   <=  32'h0;
        r0[7]   <=  32'h0;
        r0[8]   <=  32'h0;
    end
    else begin
        if(cs_state == s_idle)begin
            r0[0] <= in_r0_0;
            r0[1] <= in_r0_1;
            r0[2] <= in_r0_2;
            r0[3] <= in_r0_3;
            r0[4] <= in_r0_4;
            r0[5] <= in_r0_5;
            r0[6] <= in_r0_6;
            r0[7] <= in_r0_7;
            r0[8] <= in_r0_8;
        end else if(cs_state == s_run) begin
            case(op_code)
            MUL:begin
                r0[dst_index] <= r0[dst_index] * r0[src_index];
            end
            ADD:begin
                r0[dst_index] <= r0[dst_index] + r0[src_index] + op_data;
            end
            SUB:begin
                r0[dst_index] <= r0[dst_index] - r0[src_index];
            end
            ROR:begin
                r0[dst_index] <= (r0[dst_index] >> (r0[src_index] & 5'h1f)) | (r0[dst_index] << (32 - (r0[src_index] & 5'h1f)));
            end
            ROL:begin
                r0[dst_index] <= (r0[dst_index] << (r0[src_index] &5'h1f)) | (r0[dst_index] >> (32 - (r0[src_index] & 5'h1f)));
            end
            XOR:begin
                r0[dst_index] <= r0[dst_index] ^ r0[src_index];
            end
                
            endcase
        end
    end
end

endmodule
