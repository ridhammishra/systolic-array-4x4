`timescale 1ns/1ps

module tb_versa_top;
    reg        CLK100MHZ = 0;
    reg        CPU_RESETN = 0;
    reg        BTNC = 0;
    reg  [4:0] SW = 0;
    wire [15:0] LED;

    versa_top #(.DEBOUNCE(4)) dut (        // short debounce for simulation
        .CLK100MHZ(CLK100MHZ), .CPU_RESETN(CPU_RESETN),
        .BTNC(BTNC), .SW(SW), .LED(LED)
    );

    always #5 CLK100MHZ = ~CLK100MHZ;      // 100 MHz

    reg [7:0] res [0:15];
    integer i;

    task run_test(input m);
        begin
            SW[0] = m;
            BTNC = 1; repeat (10) @(posedge CLK100MHZ);
            BTNC = 0;
            wait (!LED[0]);                // leaves previous DONE / still idle
            wait (LED[0]);                 // DONE
            repeat (2) @(posedge CLK100MHZ);
            for (i = 0; i < 16; i = i + 1) begin
                SW[4:1] = i;
                #1;
                res[i] = LED[15:8];
            end
            $display("\n--- %s MODE ---", m ? "SPARSE" : "DENSE");
            $display("   %4d %4d %4d %4d", res[0],  res[1],  res[2],  res[3]);
            $display("   %4d %4d %4d %4d", res[4],  res[5],  res[6],  res[7]);
            $display("   %4d %4d %4d %4d", res[8],  res[9],  res[10], res[11]);
            $display("   %4d %4d %4d %4d", res[12], res[13], res[14], res[15]);
            $display("   LED DONE=%b  PASS=%b  FAIL=%b  ==> %s",
                     LED[0], LED[1], LED[2], LED[1] ? "PASS" : "FAIL");
        end
    endtask

    initial begin
        repeat (5) @(posedge CLK100MHZ);
        CPU_RESETN = 1;
        repeat (5) @(posedge CLK100MHZ);

        run_test(0);       // dense
        run_test(1);       // sparse
        $finish;
    end
endmodule
