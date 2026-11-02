`timescale 1ns / 1ps
module tb_nexys;
    reg  clk_100MHz = 0, btnC = 1, btnU = 0;
    reg  [3:0] sw = 0;
    wire [15:0] led;

    integer i, errors;
    reg [11:0] expected [0:15];

    nexys_top uut (
        .clk_100MHz(clk_100MHz), .btnC(btnC), .btnU(btnU),
        .sw(sw), .led(led)
    );

    always #5 clk_100MHz = ~clk_100MHz;

    initial begin
        // expected results C(0,0) to C(3,3), row by row
        expected[0]=20;   expected[1]=15;  expected[2]=12;  expected[3]=7;
        expected[4]=48;   expected[5]=39;  expected[6]=32;  expected[7]=23;
        expected[8]=76;   expected[9]=63;  expected[10]=52; expected[11]=39;
        expected[12]=104; expected[13]=87; expected[14]=72; expected[15]=55;

        errors = 0;
        #100 btnC = 0;          // release reset
        #100 btnU = 1;          // press start
        #100 btnU = 0;          // release start

        wait (led[15] === 1'b1);   // led 15 = done
        #20;

        for (i = 0; i < 16; i = i + 1) begin
            sw = i;
            #20;
            if (led[11:0] !== expected[i]) begin
                errors = errors + 1;
                $display("MISMATCH sw=%0d: led=%0d expected=%0d", i, led[11:0], expected[i]);
            end else
                $display("sw=%0d  led=%0d  OK", i, led[11:0]);
        end

        if (errors == 0) $display(">>> PASS: board wrapper shows all 16 results correctly <<<");
        else             $display(">>> FAIL: %0d wrong results <<<", errors);
        $finish;
    end

    initial begin
        #20000;
        $display("TIMEOUT");
        $finish;
    end
endmodule
