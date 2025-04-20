-- =============================================================================
-- File:                    bus_pwm_tb.vhd
--
-- Entity:                  bus_pwm_tb
--
-- Description:             Testbench for bus interface of the PWM entity.
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

ENTITY bus_pwm_tb IS
END ENTITY bus_pwm_tb;

ARCHITECTURE arch OF bus_pwm_tb IS
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

    dut: entity neorv32.neorv32_pwm
     generic map(
        NUM_CHANNELS => 10
    )
     port map(
        clk_i => clk,
        rstn_i => rstn,
        bus_req_i => bus_req,
        bus_rsp_o => bus_rsp,
        clkgen_en_o => open,
        clkgen_i => (others => '0'),
        pwm_o => open
    );

    test : PROCESS IS
    BEGIN
        WAIT UNTIL rising_edge(rstn);
        WAIT UNTIL rising_edge(clk);

        --                                 address      write         read
        bus_check(clk, bus_req, bus_rsp, x"fff00000", x"ffff_ffff", x"f803_ffff"); -- channel 0
        bus_check(clk, bus_req, bus_rsp, x"fff00004", x"ffff_ffff", x"f803_ffff"); -- channel 1
        bus_check(clk, bus_req, bus_rsp, x"fff00008", x"ffff_ffff", x"f803_ffff"); -- channel 2
        bus_check(clk, bus_req, bus_rsp, x"fff0000c", x"ffff_ffff", x"f803_ffff"); -- channel 3
        bus_check(clk, bus_req, bus_rsp, x"fff00010", x"ffff_ffff", x"f803_ffff"); -- channel 4
        bus_check(clk, bus_req, bus_rsp, x"fff00014", x"ffff_ffff", x"f803_ffff"); -- channel 5
        bus_check(clk, bus_req, bus_rsp, x"fff00018", x"ffff_ffff", x"f803_ffff"); -- channel 6
        bus_check(clk, bus_req, bus_rsp, x"fff0001c", x"ffff_ffff", x"f803_ffff"); -- channel 7
        bus_check(clk, bus_req, bus_rsp, x"fff00020", x"ffff_ffff", x"f803_ffff"); -- channel 8
        bus_check(clk, bus_req, bus_rsp, x"fff00024", x"ffff_ffff", x"f803_ffff"); -- channel 9
        bus_check(clk, bus_req, bus_rsp, x"fff00028", x"ffff_ffff", x"0000_0000"); -- channel 10 (not implemented)
        bus_check(clk, bus_req, bus_rsp, x"fff0002c", x"ffff_ffff", x"0000_0000"); -- channel 11 (not implemented)
        bus_check(clk, bus_req, bus_rsp, x"fff00030", x"ffff_ffff", x"0000_0000"); -- channel 12 (not implemented)
        bus_check(clk, bus_req, bus_rsp, x"fff00034", x"ffff_ffff", x"0000_0000"); -- channel 13 (not implemented)
        bus_check(clk, bus_req, bus_rsp, x"fff00038", x"ffff_ffff", x"0000_0000"); -- channel 14 (not implemented)
        bus_check(clk, bus_req, bus_rsp, x"fff0003c", x"ffff_ffff", x"0000_0000"); -- channel 15 (not implemented)

        REPORT "Test OK";
        done <= '1';
    END PROCESS test;

END ARCHITECTURE arch;
