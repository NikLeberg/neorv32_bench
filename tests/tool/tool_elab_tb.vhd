-- =============================================================================
-- File:                    tool_elab_tb.vhd
--
-- Entity:                  tool_elab_tb
--
-- Description:             Elaboration test for tools. Instantiates a NEORV32
--                          core. The test passes if the elaboration step is
--                          successful.
--
-- Author:                  Niklaus Leuenberger <@NikLeberg>
--
-- SPDX-License-Identifier: MIT
--
-- Version:                 0.1
--
-- Changes:                 0.1, 2025-04-14, NikLeberg
--                              initial version
-- =============================================================================

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

LIBRARY neorv32;
USE neorv32.neorv32_package.ALL;

ENTITY tool_elab_tb IS
    GENERIC (
        CLK_PERIOD : DELAY_LENGTH
    );
    PORT (
        clk_i  : IN STD_ULOGIC;
        rstn_i : IN STD_ULOGIC;
        gpio_o : OUT STD_ULOGIC_VECTOR(31 DOWNTO 0)
    );
END ENTITY tool_elab_tb;

ARCHITECTURE arch OF tool_elab_tb IS
    CONSTANT XMEM_BASE        : STD_ULOGIC_VECTOR(31 DOWNTO 0) := x"0000_0000";
    CONSTANT XMEM_SIZE        : NATURAL                        := 64;
    SIGNAL xbus_req, xmem_req : xbus_req_t;
    SIGNAL xbus_rsp, xmem_rsp : xbus_rsp_t;
    SIGNAL xbus_idle          : xbus_rsp_t := (
        data => (OTHERS => '0'), ack => '0', err => '0'
    );
BEGIN
    neorv32_top_inst : ENTITY neorv32.neorv32_top
        GENERIC MAP(
            CLOCK_FREQUENCY   => (1 sec) / CLK_PERIOD,
            BOOT_MODE_SELECT  => 1,
            BOOT_ADDR_CUSTOM  => XMEM_BASE,
            XBUS_EN           => true,
            IO_GPIO_NUM       => 32
        )
        PORT MAP(
            clk_i      => clk_i,
            rstn_i     => rstn_i,
            xbus_adr_o => xbus_req.addr,
            xbus_dat_o => xbus_req.data,
            xbus_tag_o => xbus_req.tag,
            xbus_we_o  => xbus_req.we,
            xbus_sel_o => xbus_req.sel,
            xbus_stb_o => xbus_req.stb,
            xbus_cyc_o => xbus_req.cyc,
            xbus_dat_i => xbus_rsp.data,
            xbus_ack_i => xbus_rsp.ack,
            xbus_err_i => xbus_rsp.err,
            gpio_o     => gpio_o
        );

    xgate_inst : ENTITY neorv32.xbus_gateway
        GENERIC MAP(
            DEV_0_EN   => true,
            DEV_0_SIZE => XMEM_SIZE,
            DEV_0_BASE => XMEM_BASE
        )
        PORT MAP(
            clk_i       => clk_i,
            rstn_i      => rstn_i,
            host_req_i  => xbus_req,
            host_rsp_o  => xbus_rsp,
            dev_0_req_o => xmem_req,
            dev_0_rsp_i => xmem_rsp,
            dev_1_rsp_i => xbus_idle,
            dev_2_rsp_i => xbus_idle,
            dev_3_rsp_i => xbus_idle
        );

    xmem_inst : ENTITY neorv32.xbus_memory
        GENERIC MAP(
            MEM_SIZE => XMEM_SIZE,
            MEM_FILE => "neorv32_firmware.hex"
        )
        PORT MAP(
            clk_i      => clk_i,
            rstn_i     => rstn_i,
            xbus_req_i => xmem_req,
            xbus_rsp_o => xmem_rsp
        );

END ARCHITECTURE arch;
