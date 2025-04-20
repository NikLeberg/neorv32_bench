-- =============================================================================
-- File:                    bus_gpio_tb.vhd
--
-- Entity:                  bus_gpio_tb
--
-- Description:             Testbench for bus interface of the GPIO entity.
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

ENTITY bus_gpio_tb IS
END ENTITY bus_gpio_tb;

ARCHITECTURE arch OF bus_gpio_tb IS
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

    dut : ENTITY neorv32.neorv32_gpio
        GENERIC MAP(
            GPIO_NUM => 32
        )
        PORT MAP(
            clk_i     => clk,
            rstn_i    => rstn,
            bus_req_i => bus_req,
            bus_rsp_o => bus_rsp,
            gpio_o    => OPEN,
            gpio_i => (OTHERS => '0'),
            cpu_irq_o => OPEN
        );

    test : PROCESS IS
    BEGIN
        WAIT UNTIL rising_edge(rstn);
        WAIT UNTIL rising_edge(clk);

        bus_check(clk, bus_req, bus_rsp, x"fffc0000", "r/-"); -- inputs
        bus_check(clk, bus_req, bus_rsp, x"fffc0004", "r/w"); -- outpus
        bus_check(clk, bus_req, bus_rsp, x"fffc0008", "0/-"); -- reserved
        bus_check(clk, bus_req, bus_rsp, x"fffc000c", "0/-"); -- reserved
        bus_check(clk, bus_req, bus_rsp, x"fffc0010", "r/w"); -- irq trigger type
        bus_check(clk, bus_req, bus_rsp, x"fffc0014", "r/w"); -- irq trigger polarity
        bus_check(clk, bus_req, bus_rsp, x"fffc0014", "r/w"); -- irq enable
        bus_check(clk, bus_req, bus_rsp, x"fffc001c", "r/c"); -- irq pending

        REPORT "Test OK";
        done <= '1';
    END PROCESS test;

END ARCHITECTURE arch;
