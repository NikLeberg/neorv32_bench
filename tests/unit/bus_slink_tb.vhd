-- =============================================================================
-- File:                    bus_slink_tb.vhd
--
-- Entity:                  bus_slink_tb
--
-- Description:             Testbench for bus interface of the SLINK entity.
--
-- Author:                  Niklaus Leuenberger <@NikLeberg>
--
-- SPDX-License-Identifier: MIT
--
-- Version:                 0.1
--
-- Changes:                 0.1, 2025-04-19, NikLeberg
--                              initial version
-- =============================================================================

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

LIBRARY neorv32;
USE neorv32.neorv32_package.ALL;

USE work.bus_pkg.ALL;

ENTITY bus_slink_tb IS
END ENTITY bus_slink_tb;

ARCHITECTURE arch OF bus_slink_tb IS
    CONSTANT CLK_PERIOD : DELAY_LENGTH := 20 ns; -- 50 MHz
    SIGNAL clk          : STD_ULOGIC   := '1';
    SIGNAL rstn         : STD_ULOGIC   := '0';
    SIGNAL done         : STD_ULOGIC   := '0'; -- flag end of tests

    SIGNAL bus_req : bus_req_t := idle_req;
    SIGNAL bus_rsp : bus_rsp_t;
BEGIN

    -- Clock until done = 1, reset with first two clocks.
    clk  <= '0' WHEN done = '1' ELSE NOT clk AFTER 0.5 * CLK_PERIOD;
    rstn <= '0', '1' AFTER 2 * CLK_PERIOD;

    dut : ENTITY neorv32.neorv32_slink
        GENERIC MAP(
            SLINK_RX_FIFO => 1,
            SLINK_TX_FIFO => 1
        )
        PORT MAP(
            clk_i            => clk,
            rstn_i           => rstn,
            bus_req_i        => bus_req,
            bus_rsp_o        => bus_rsp,
            rx_irq_o         => OPEN,
            tx_irq_o         => OPEN,
            slink_rx_data_i => (OTHERS => '0'),
            slink_rx_src_i => (OTHERS => '0'),
            slink_rx_valid_i => '0',
            slink_rx_last_i  => '0',
            slink_rx_ready_o => OPEN,
            slink_tx_data_o  => OPEN,
            slink_tx_dst_o   => OPEN,
            slink_tx_valid_o => OPEN,
            slink_tx_last_o  => OPEN,
            slink_tx_ready_i => '0'
        );

    test : PROCESS IS
    BEGIN
        WAIT UNTIL rising_edge(rstn);
        WAIT UNTIL rising_edge(clk);

        --                                 address      write         read
        bus_check(clk, bus_req, bus_rsp, x"ffec0000", x"ffff_ffff", x"003f_0901"); -- control
        bus_check(clk, bus_req, bus_rsp, x"ffec0004", x"ffff_ffff", x"0000_000f"); -- route
        bus_check(clk, bus_req, bus_rsp, x"ffec0008", x"ffff_ffff", x"----_----"); -- data
        bus_check(clk, bus_req, bus_rsp, x"ffec000c", x"ffff_ffff", x"----_----"); -- data last

        REPORT "Test OK";
        done <= '1';
    END PROCESS test;

END ARCHITECTURE arch;
