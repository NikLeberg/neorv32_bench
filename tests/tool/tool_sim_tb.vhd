-- =============================================================================
-- File:                    tool_sim_tb.vhd
--
-- Entity:                  tool_sim_tb
--
-- Description:             Simulation test for tools. Instantiates a tool
--                          entity and enforces that after some time the    
--                          simulation reaches the expected value for the GPIO
--                          output.
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

ENTITY tool_sim_tb IS
END ENTITY tool_sim_tb;

ARCHITECTURE arch OF tool_sim_tb IS
    CONSTANT CLK_PERIOD : DELAY_LENGTH := 20 ns; -- 50 MHz
    CONSTANT TIMEOUT    : DELAY_LENGTH := 50 * CLK_PERIOD;
    SIGNAL clk          : STD_ULOGIC   := '1';
    SIGNAL rstn         : STD_ULOGIC   := '0';
    SIGNAL done         : STD_ULOGIC   := '0'; -- flag end of tests
    SIGNAL gpio         : STD_ULOGIC_VECTOR(31 DOWNTO 0);
BEGIN

    -- Clock until done = 1, reset with first two clocks.
    clk  <= '0' WHEN done = '1' ELSE NOT clk AFTER 0.5 * CLK_PERIOD;
    rstn <= '0', '1' AFTER 2 * CLK_PERIOD;

    dut : ENTITY work.tool_elab_tb
        GENERIC MAP(
            CLK_PERIOD => CLK_PERIOD
        )
        PORT MAP(
            clk_i  => clk,
            rstn_i => rstn,
            gpio_o => gpio
        );

    test : PROCESS IS
    BEGIN
        WAIT UNTIL rising_edge(rstn);
        WAIT UNTIL rising_edge(clk);

        ASSERT gpio = x"0000_0000" REPORT "gpio != 0" SEVERITY failure;
        WAIT ON gpio FOR TIMEOUT;
        ASSERT gpio = x"dead_beef" REPORT "unexpected value" SEVERITY failure;

        REPORT "Test OK";
        done <= '1';
    END PROCESS test;

END ARCHITECTURE arch;
