interface SSP_if;
    ///////////////AMBA APB SIGNAL///////////
    logic        PRESETn;
    logic [11:2] PADDR;
    logic        PCLK;
    logic        PENABLE;
    logic [15:0] PRDATA;
    logic        PSEL;
    logic [15:0] PWDATA;
    logic        PWRITE;
    ////////////////////////////////////////

    ///////////On-chip signals//////////////
    // SYSTEMS
    logic        SSPCLK;
    logic        nSSPRST;
    //INTERUPT
    logic        SSPTXINTR;
    logic        SSPRXINTR;
    logic        SSPRORINTR;
    logic        SSPRTINTR;
    logic        SSPINTR;
    ////DMA CONTROL
    logic        SSPTXDMASREQ;
    logic        SSPRXDMASREQ;
    logic        SSPTXDMABREQ;
    logic        SSPRXDMABREQ;
    logic        SSPTXDMACLR;
    logic        SSPRXDMACLR;   
    // SCANE
    logic        SCANENABLE;
    logic        SCANINPCLK;
    logic        SCANOUTPCLK;
    logic        SCANINSSPCLK;
    logic        SCANOUTSSPCLK;    
    ///////////////////////////////////////

    /////////  Signals to pads/////////////
    logic        SSPFSSOUT;
    logic        SSPCLKOUT;
    logic        SSPRXD;
    logic        SSPTXD;
    logic        nSSPCTLOE;
    logic        SSPFSSIN;
    logic        SSPCLKIN;
    logic        nSSPOE;
    //////////////////////////////////////
    
endinterface