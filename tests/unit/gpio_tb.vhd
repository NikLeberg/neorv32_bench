-- =============================================================================
-- File:                    gpio_tb.vhd
--
-- Entity:                  gpio_tb
--
-- Description:             Testbench for GPIO entity.
--
-- Author:                  Niklaus Leuenberger <@NikLeberg>
--
-- SPDX-License-Identifier: MIT
--
-- Version:                 0.1
--
-- Changes:                 0.1, 2025-04-18, NikLeberg
--                              initial version
-- =============================================================================

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

LIBRARY neorv32;
USE neorv32.neorv32_package.ALL;

USE work.bus_pkg.ALL;

ENTITY gpio_tb IS
END ENTITY gpio_tb;

ARCHITECTURE arch OF gpio_tb IS
    CONSTANT CLK_PERIOD : DELAY_LENGTH := 20 ns; -- 50 MHz
    CONSTANT TIMEOUT    : DELAY_LENGTH := 50 * CLK_PERIOD;
    CONSTANT IRQ_DELAY  : DELAY_LENGTH := 4 * CLK_PERIOD;
    SIGNAL clk          : STD_ULOGIC   := '1';
    SIGNAL rstn         : STD_ULOGIC   := '0';
    SIGNAL done         : STD_ULOGIC   := '0'; -- flag end of tests

    SIGNAL gpio_o, gpio_i : STD_ULOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL bus_req        : bus_req_t := idle_req;
    SIGNAL bus_rsp        : bus_rsp_t;
    SIGNAL irq            : STD_ULOGIC;
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
            gpio_o    => gpio_o,
            gpio_i    => gpio_i,
            cpu_irq_o => irq
        );

    test : PROCESS IS
        --
        PROCEDURE write (
            addr  : NATURAL RANGE 0 TO 7;
            value : STD_ULOGIC_VECTOR(31 DOWNTO 0)
        ) IS BEGIN
            WAIT UNTIL rising_edge(clk);
            bus_req.addr <= STD_ULOGIC_VECTOR(to_unsigned(addr, 30) & "00");
            bus_req.data <= value;
            bus_req.rw   <= '1';
            bus_req.stb  <= '1';
            WAIT UNTIL rising_edge(clk);
            bus_req.stb <= '0';
            WAIT UNTIL rising_edge(clk);
            ASSERT bus_rsp.ack = '1' REPORT "slave did not ack" SEVERITY failure;
        END PROCEDURE write;
        --
        PROCEDURE read (
            addr : NATURAL RANGE 0 TO 7
        ) IS BEGIN
            WAIT UNTIL rising_edge(clk);
            bus_req.addr <= STD_ULOGIC_VECTOR(to_unsigned(addr, 30) & "00");
            bus_req.rw   <= '0';
            bus_req.stb  <= '1';
            WAIT UNTIL rising_edge(clk);
            bus_req.stb <= '0';
            WAIT UNTIL rising_edge(clk);
            ASSERT bus_rsp.ack = '1' REPORT "slave did not ack" SEVERITY failure;
        END PROCEDURE read;
        --
        PROCEDURE reset_irqs IS BEGIN
            gpio_i <= (OTHERS => '0');
            write(6, (OTHERS  => '0')); -- disable
            write(7, (OTHERS  => '0')); -- reset pending
            IF irq /= '0' THEN
                WAIT UNTIL irq = '0' FOR TIMEOUT;
                ASSERT irq = '0' REPORT "could not reset irqs" SEVERITY failure;
            END IF;
        END PROCEDURE reset_irqs;
        --
        VARIABLE val : STD_ULOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');
    BEGIN
        WAIT UNTIL rising_edge(rstn);
        WAIT UNTIL rising_edge(clk);

        -- read all inputs at once
        gpio_i <= x"ffff_ffff";
        read(0);
        ASSERT bus_rsp.data = x"ffff_ffff"
        REPORT "could not read inputs [high]" SEVERITY failure;
        gpio_i <= x"0000_0000";
        read(0);
        ASSERT bus_rsp.data = x"0000_0000"
        REPORT "could not read inputs [low]" SEVERITY failure;

        -- write all outputs at once
        write(1, x"ffff_ffff");
        ASSERT gpio_o = x"ffff_ffff"
        REPORT "could not write outputs [high]" SEVERITY failure;
        write(1, x"0000_0000");
        ASSERT gpio_o = x"0000_0000"
        REPORT "could not write outputs [low]" SEVERITY failure;

        FOR i IN 0 TO 31 LOOP
            -- read single input
            gpio_i(i) <= '1';
            read(0);
            ASSERT bus_rsp.data(i) = '1'
            REPORT "could not read input " & INTEGER'image(i) & " [high]" SEVERITY failure;
            gpio_i(i) <= '0';
            read(0);
            ASSERT bus_rsp.data(i) = '0'
            REPORT "could not read input " & INTEGER'image(i) & " [low]" SEVERITY failure;

            -- write single output
            val(i) := '1';
            write(1, val);
            ASSERT gpio_o(i) = '1'
            REPORT "could not write output " & INTEGER'image(i) & " [high]" SEVERITY failure;
            val(i) := '0';
            write(1, val);
            ASSERT gpio_o(i) = '0'
            REPORT "could not write output " & INTEGER'image(i) & " [low]" SEVERITY failure;

            reset_irqs;

            -- low level irq
            write(4, (OTHERS => '0')); -- type
            write(5, (OTHERS => '0')); -- polarity
            write(6, (OTHERS => '0')); -- disable
            gpio_i(i) <= '0';
            WAIT FOR IRQ_DELAY;
            WAIT UNTIL rising_edge(clk);
            ASSERT irq = '0'
            REPORT "triggered disabled irq " & INTEGER'image(i) & " [low level]" SEVERITY failure;
            read(7); -- pending?
            ASSERT bus_rsp.data(i) = '0'
            REPORT "disabled irq " & INTEGER'image(i) & " pending [low level]" SEVERITY failure;
            gpio_i(i) <= '1';
            WAIT UNTIL rising_edge(clk);
            val(i) := '1';
            write(6, val); -- enable
            gpio_i(i) <= '0';
            WAIT FOR IRQ_DELAY;
            WAIT UNTIL rising_edge(clk);
            ASSERT irq = '1'
            REPORT "did not trigger irq " & INTEGER'image(i) & " [low level]" SEVERITY failure;
            read(7); -- pending?
            ASSERT bus_rsp.data(i) = '1'
            REPORT "irq " & INTEGER'image(i) & " not pending [low level]" SEVERITY failure;
            write(7, (OTHERS => '0')); -- reset pending
            WAIT FOR IRQ_DELAY;
            WAIT UNTIL rising_edge(clk);
            ASSERT irq = '1'
            REPORT "did not re-trigger irq " & INTEGER'image(i) & " [low level]" SEVERITY failure;
            read(7); -- pending?
            ASSERT bus_rsp.data(i) = '1'
            REPORT "irq " & INTEGER'image(i) & " not pending [low level]" SEVERITY failure;
            write(7, (OTHERS => '0')); -- reset pending
            val(i) := '0';
            write(6, (OTHERS => '0')); -- disable

            reset_irqs;

            -- high level irq
            gpio_i(i) <= '0';
            write(4, (OTHERS => '0')); -- type
            val(i) := '1';
            write(5, val);             -- polarity
            write(6, (OTHERS => '0')); -- disable
            gpio_i(i) <= '1';
            WAIT FOR IRQ_DELAY;
            WAIT UNTIL rising_edge(clk);
            ASSERT irq = '0'
            REPORT "triggered disabled irq " & INTEGER'image(i) & " [high level]" SEVERITY failure;
            read(7); -- pending?
            ASSERT bus_rsp.data(i) = '0'
            REPORT "disabled irq " & INTEGER'image(i) & " pending [high level]" SEVERITY failure;
            gpio_i(i) <= '0';
            WAIT UNTIL rising_edge(clk);
            write(6, val); -- enable
            gpio_i(i) <= '1';
            WAIT FOR IRQ_DELAY;
            WAIT UNTIL rising_edge(clk);
            ASSERT irq = '1'
            REPORT "did not trigger irq " & INTEGER'image(i) & " [high level]" SEVERITY failure;
            read(7); -- pending?
            ASSERT bus_rsp.data(i) = '1'
            REPORT "irq " & INTEGER'image(i) & " not pending [high level]" SEVERITY failure;
            write(7, (OTHERS => '0')); -- reset pending
            WAIT FOR IRQ_DELAY;
            WAIT UNTIL rising_edge(clk);
            ASSERT irq = '1'
            REPORT "did not re-trigger irq " & INTEGER'image(i) & " [high level]" SEVERITY failure;
            read(7); -- pending?
            ASSERT bus_rsp.data(i) = '1'
            REPORT "irq " & INTEGER'image(i) & " not pending [high level]" SEVERITY failure;
            write(7, (OTHERS => '0')); -- reset pending
            val(i) := '0';
            write(6, (OTHERS => '0')); -- disable

            reset_irqs;

            -- falling edge irq
            gpio_i(i) <= '1';
            val(i) := '1';
            write(4, val);             -- type
            write(5, (OTHERS => '0')); -- polarity
            write(6, (OTHERS => '0')); -- disable
            gpio_i(i) <= '0';
            WAIT FOR IRQ_DELAY;
            WAIT UNTIL rising_edge(clk);
            ASSERT irq = '0'
            REPORT "triggered disabled irq " & INTEGER'image(i) & " [falling edge]" SEVERITY failure;
            read(7); -- pending?
            ASSERT bus_rsp.data(i) = '0'
            REPORT "disabled irq " & INTEGER'image(i) & " pending [falling edge]" SEVERITY failure;
            gpio_i(i) <= '1';
            WAIT UNTIL rising_edge(clk);
            write(6, val); -- enable
            gpio_i(i) <= '0';
            WAIT FOR IRQ_DELAY;
            WAIT UNTIL rising_edge(clk);
            ASSERT irq = '1'
            REPORT "did not trigger irq " & INTEGER'image(i) & " [falling edge]" SEVERITY failure;
            read(7); -- pending?
            ASSERT bus_rsp.data(i) = '1'
            REPORT "irq " & INTEGER'image(i) & " not pending [falling edge]" SEVERITY failure;
            write(7, (OTHERS => '0')); -- reset pending
            WAIT FOR IRQ_DELAY;
            WAIT UNTIL rising_edge(clk);
            ASSERT irq /= '1'
            REPORT "did re-trigger irq " & INTEGER'image(i) & " [falling edge]" SEVERITY failure;
            read(7); -- pending?
            ASSERT bus_rsp.data(i) /= '1'
            REPORT "irq " & INTEGER'image(i) & " pending [falling edge]" SEVERITY failure;
            write(7, (OTHERS => '0')); -- reset pending
            val(i) := '0';
            write(6, (OTHERS => '0')); -- disable

            reset_irqs;

            -- rising edge irq
            gpio_i(i) <= '0';
            val(i) := '1';
            write(4, val);             -- type
            write(5, val);             -- polarity
            write(6, (OTHERS => '0')); -- disable
            gpio_i(i) <= '1';
            WAIT FOR IRQ_DELAY;
            WAIT UNTIL rising_edge(clk);
            ASSERT irq = '0'
            REPORT "triggered disabled irq " & INTEGER'image(i) & " [rising edge]" SEVERITY failure;
            read(7); -- pending?
            ASSERT bus_rsp.data(i) = '0'
            REPORT "disabled irq " & INTEGER'image(i) & " pending [rising edge]" SEVERITY failure;
            gpio_i(i) <= '0';
            WAIT UNTIL rising_edge(clk);
            write(6, val); -- enable
            gpio_i(i) <= '1';
            WAIT FOR IRQ_DELAY;
            WAIT UNTIL rising_edge(clk);
            ASSERT irq = '1'
            REPORT "did not trigger irq " & INTEGER'image(i) & " [rising edge]" SEVERITY failure;
            read(7); -- pending?
            ASSERT bus_rsp.data(i) = '1'
            REPORT "irq " & INTEGER'image(i) & " not pending [rising edge]" SEVERITY failure;
            write(7, (OTHERS => '0')); -- reset pending
            WAIT FOR IRQ_DELAY;
            WAIT UNTIL rising_edge(clk);
            ASSERT irq /= '1'
            REPORT "did re-trigger irq " & INTEGER'image(i) & " [rising edge]" SEVERITY failure;
            read(7); -- pending?
            ASSERT bus_rsp.data(i) /= '1'
            REPORT "irq " & INTEGER'image(i) & " pending [rising edge]" SEVERITY failure;
            write(7, (OTHERS => '0')); -- reset pending
            val(i) := '0';
            write(6, (OTHERS => '0')); -- disable

        END LOOP;

        REPORT "Test OK";
        done <= '1';
    END PROCESS test;

END ARCHITECTURE arch;
