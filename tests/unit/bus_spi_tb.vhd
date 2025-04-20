-- =============================================================================
-- File:                    bus_spi_tb.vhd
--
-- Entity:                  bus_spi_tb
--
-- Description:             Testbench for bus interface of the SPI entity.
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

ENTITY bus_spi_tb IS
END ENTITY bus_spi_tb;

ARCHITECTURE arch OF bus_spi_tb IS
    CONSTANT CLK_PERIOD : DELAY_LENGTH := 20 ns; -- 50 MHz
    CONSTANT TIMEOUT    : DELAY_LENGTH := 50 * CLK_PERIOD;
    SIGNAL clk          : STD_ULOGIC   := '1';
    SIGNAL rstn         : STD_ULOGIC   := '0';
    SIGNAL done         : STD_ULOGIC   := '0'; -- flag end of tests

    SIGNAL bus_req : bus_req_t := idle_req;
    SIGNAL bus_rsp : bus_rsp_t;
BEGIN

    -- Clock until done = 1, reset with first two clocks.
    clk  <= '0' WHEN done = '1' ELSE NOT clk AFTER 0.5 * CLK_PERIOD;
    rstn <= '0', '1' AFTER 2 * CLK_PERIOD;

    dut : ENTITY neorv32.neorv32_spi
        GENERIC MAP(
            IO_SPI_FIFO => 1
        )
        PORT MAP(
            clk_i       => clk,
            rstn_i      => rstn,
            bus_req_i   => bus_req,
            bus_rsp_o   => bus_rsp,
            clkgen_en_o => OPEN,
            clkgen_i => (OTHERS => '0'),
            spi_clk_o   => OPEN,
            spi_dat_o   => OPEN,
            spi_dat_i   => '0',
            spi_csn_o   => OPEN,
            irq_o       => OPEN
        );

    test : PROCESS IS
    BEGIN
        WAIT UNTIL rising_edge(rstn);
        WAIT UNTIL rising_edge(clk);

        --                                 address      write         read
        bus_check(clk, bus_req, bus_rsp, x"fff80000", x"ffff_ffff", x"00f6_07ff"); -- control
        bus_check(clk, bus_req, bus_rsp, x"fff80004", x"7fff_ffff", x"0000_00--"); -- data

        REPORT "Test OK";
        done <= '1';
    END PROCESS test;

END ARCHITECTURE arch;
