`timescale 1ns/1ps
module tb ;

///interface 
SSP_if SSP_vif();
// dut
bit [15:0] DATA;
bit [15:0] WDATA;
bit [15:0] RDATA;

// Cờ bật mock trong TC1 (để chạy khi chưa có RTL)
bit tc1_mock_en = 1'b0;
// ===== Declarations must precede statements =====
// Type để chứa kỳ vọng default (struct thường vì có string)
typedef struct {
    logic [11:2] addr;
    logic [15:0] exp;
    logic [15:0] mask;
    bit          chk;
    string       name;
} reg_exp_t;

// Bảng default của ARM PrimeCell SSP (PL022) – addr là word-address [11:2]
reg_exp_t value_table[] = '{
    '{10'h000, 16'h0000, 16'hFFFF, 1, "SSPCR0"},
    '{10'h001, 16'h0000, 16'h000F, 1, "SSPCR1"},
    '{10'h002, 16'h0000, 16'h0000, 0, "SSPDR" },  // don't-care on reset
    '{10'h003, 16'h0003, 16'h001F, 1, "SSPSR" },  // TFE=1, TNF=1
    '{10'h004, 16'h0000, 16'h00FF, 1, "SSPCPSR"},
    '{10'h005, 16'h0000, 16'h000F, 1, "SSPIMSC"},
    '{10'h006, 16'h0008, 16'h000F, 1, "SSPRIS" },
    '{10'h007, 16'h0000, 16'h000F, 1, "SSPMIS" },
    '{10'h008, 16'h0000, 16'h0003, 1, "SSPICR" },  // WO: read 0, valid [1:0]
    '{10'h009, 16'h0000, 16'h0003, 1, "SSPDMACR"},
    '{10'h3F8, 16'h0022, 16'h00FF, 1, "PeriphID0"},
    '{10'h3F9, 16'h0010, 16'h00FF, 1, "PeriphID1"},
    '{10'h3FA, 16'h0034, 16'h00FF, 1, "PeriphID2"},
    '{10'h3FB, 16'h0000, 16'h00FF, 1, "PeriphID3"},
    '{10'h3FC, 16'h000D, 16'h00FF, 1, "CellID0"},
    '{10'h3FD, 16'h00F0, 16'h00FF, 1, "CellID1"},
    '{10'h3FE, 16'h0005, 16'h00FF, 1, "CellID2"},
    '{10'h3FF, 16'h00B1, 16'h00FF, 1, "CellID3"}
};

// PCLK INTI
initial begin
    SSP_vif.PCLK = 0;
    forever #10 SSP_vif.PCLK = ~SSP_vif.PCLK ;
end
// PRESETn
initial begin
    SSP_vif.PRESETn = 0;
    repeat(2) @(posedge SSP_vif.PCLK);
    #1ps; SSP_vif.PRESETn = 1;
end

// internal reset
initial begin
  SSP_vif.nSSPRST = 0;
  repeat(2) @(posedge SSP_vif.PCLK);
  #1ps SSP_vif.nSSPRST = 1;
end


// TEST 
initial begin
    // test_case 1 - default_value check 
    test_case_1();
    // test_case 2 - read_write_value check
    test_case_2();
    // test_case 3
    #1000
    $finish;
end

//byte address = word address << 2 
// Force/Release PRDATA đúng theo địa chỉ khi thực hiện APB READ trong TC1.
always @(posedge SSP_vif.PCLK) begin
  if (tc1_mock_en && SSP_vif.PSEL && SSP_vif.PENABLE && !SSP_vif.PWRITE) begin
    unique case (SSP_vif.PADDR)  // works if PADDR is word index [11:2]
       // ---- Core registers (offset 0x00..0x24) ----
      10'h000: force SSP_vif.PRDATA = 32'(16'h0000); // SSPCR0
      10'h001: force SSP_vif.PRDATA = 32'(16'h0000); // SSPCR1
      10'h002: force SSP_vif.PRDATA = 32'(16'h0000); // SSPDR  (TC1 skip, nhưng mock cho 0)
      10'h003: force SSP_vif.PRDATA = 32'(16'h0003); // SSPSR  (TFE=1,TNF=1)
      10'h004: force SSP_vif.PRDATA = 32'(16'h0000); // SSPCPSR
      10'h005: force SSP_vif.PRDATA = 32'(16'h0000); // SSPIMSC
      10'h006: force SSP_vif.PRDATA = 32'(16'h0008); // SSPRIS
      10'h007: force SSP_vif.PRDATA = 32'(16'h0000); // SSPMIS
      10'h008: force SSP_vif.PRDATA = 32'(16'h0000); // SSPICR (WO -> read 0)
      10'h009: force SSP_vif.PRDATA = 32'(16'h0000); // SSPDMACR

      // ---- ID block (offset 0xFE0..0xFFC -> word 0x3F8..0x3FF) ----
      10'h3F8: force SSP_vif.PRDATA = 32'(16'h0022); // PeriphID0 @ 0xFE0
      10'h3F9: force SSP_vif.PRDATA = 32'(16'h0010); // PeriphID1 @ 0xFE4
      10'h3FA: force SSP_vif.PRDATA = 32'(16'h0034); // PeriphID2 @ 0xFE8
      10'h3FB: force SSP_vif.PRDATA = 32'(16'h0000); // PeriphID3 @ 0xFEC
      10'h3FC: force SSP_vif.PRDATA = 32'(16'h000D); // CellID0   @ 0xFF0
      10'h3FD: force SSP_vif.PRDATA = 32'(16'h00F0); // CellID1   @ 0xFF4
      10'h3FE: force SSP_vif.PRDATA = 32'(16'h0005); // CellID2   @ 0xFF8
      10'h3FF: force SSP_vif.PRDATA = 32'(16'h00B1); // CellID3   @ 0xFFC
        default: begin
          force SSP_vif.PRDATA = 32'h0000_0000; // default
      end
    endcase
  end
end
task test_case_1(); begin
    //default value check

    bit [31:0] rdata32;
    bit [15:0] r16;
    int pass; 
    int fail;  
    pass = 0; 
    fail = 0;

    // 1 = mock, 0 = RTL that
    tc1_mock_en = 1'b0;

    // (đợi reset nhả để tránh đọc giá trị giữa lúc reset)
    wait (SSP_vif.PRESETn === 1'b1);
    wait (SSP_vif.nSSPRST===1'b1);
    repeat(2) @(posedge SSP_vif.PCLK);

    $display("==== [TC1] Default Value Check ====");
  


    for (int i = 0; i < value_table.size(); i++) begin
        if (!value_table[i].chk) continue;
        read(value_table[i].addr, rdata32);
        r16 = rdata32[15:0];
        if ( (r16 & value_table[i].mask) !== value_table[i].exp ) begin
            $display("[FAIL] %-10s addr=0x%0h exp=0x%04h mask=0x%04h got=0x%04h",
                     value_table[i].name, {value_table[i].addr, 2'b00}, value_table[i].exp, value_table[i].mask, r16);
            fail++;
        end else begin
            $display("[PASS] %-10s addr=0x%0h val=0x%04h",
                     value_table[i].name, {value_table[i].addr, 2'b00}, r16);
            pass++;
        end
    end
    $display("TC1 summary: PASS=%0d FAIL=%0d", pass, fail);
    tc1_mock_en = 1'b0;
    release SSP_vif.PRDATA;
end endtask

task test_case_2();begin
    //read_write_value check
    for(int i = 0 ;i <= 12;i=i+4) begin
        DATA = $random;
        write(i,WDATA);
        read(i,RDATA);
        $display ("At address : 12'h%0h get data : WDATA = 16'h%0h ---- RDATA = 16'h%0h",i,WDATA,RDATA);
    end
end
endtask
task write(bit [11:2] addr, bit [15:0] data);
        @(posedge SSP_vif.PCLK);
        SSP_vif.PADDR <= addr;
        SSP_vif.PWRITE <= 1'b1;
        SSP_vif.PSEL <= 1'b1;
        SSP_vif.PENABLE <= 1'b0;
        SSP_vif.PWDATA <= data;

        @(posedge SSP_vif.PCLK);
        SSP_vif.PENABLE <= 1'b1;

        @(posedge SSP_vif.PCLK);

        SSP_vif.PSEL <= 1'b0;
        SSP_vif.PENABLE <= 1'b0;
        SSP_vif.PADDR <= '0;
        SSP_vif.PWDATA <= '0;
    endtask

    task read(bit [11:2] addr, output bit [31:0] data);
        @(posedge SSP_vif.PCLK);
        SSP_vif.PADDR <= addr;
        SSP_vif.PWRITE <= 1'b0;
        SSP_vif.PSEL <= 1'b1;
        SSP_vif.PENABLE <= 1'b0;

        @(posedge SSP_vif.PCLK);
        SSP_vif.PENABLE <= 1'b1;

       @(posedge SSP_vif.PCLK);

        data = SSP_vif.PRDATA;

        SSP_vif.PSEL <= 1'b0;
        SSP_vif.PENABLE <= 1'b0;
        SSP_vif.PADDR <= '0;
        SSP_vif.PRDATA <= '0;
    endtask

endmodule
