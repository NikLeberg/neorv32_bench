-- =============================================================================
-- File:                    bus_pkg.vhd
--
-- Package:                 bus_pkg
--
-- Description:             Package for bus interface checks.
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

PACKAGE bus_pkg IS
    -- Check if the addressed register conforms to the selected mode.
    --  r/w: register is read and writable, what has been written can be read
    --  r/-: register can only be read, what has been written is ignored
    --  0/-: register always reads as zero, writes are ignored
    --  r/c: register can be read, writing zero resets it
    PROCEDURE bus_check (
        SIGNAL clk    : IN STD_ULOGIC;
        SIGNAL req    : OUT bus_req_t;
        SIGNAL rsp    : IN bus_rsp_t;
        CONSTANT addr : IN STD_ULOGIC_VECTOR(31 DOWNTO 0);
        CONSTANT mode : IN STRING := "r/w"
    );

    -- Check if the addressed register after writing the specified data, reads
    -- the expected data.
    PROCEDURE bus_check (
        SIGNAL clk    : IN STD_ULOGIC;
        SIGNAL req    : OUT bus_req_t;
        SIGNAL rsp    : IN bus_rsp_t;
        CONSTANT addr : IN STD_ULOGIC_VECTOR(31 DOWNTO 0);
        CONSTANT wr   : IN STD_ULOGIC_VECTOR(31 DOWNTO 0); -- data to write
        CONSTANT rd   : IN STD_ULOGIC_VECTOR(31 DOWNTO 0)  -- expected data to read
    );

    -- Idle bus request.
    CONSTANT idle_req : bus_req_t := (
        addr => (OTHERS => '0'), data => (OTHERS => '0'), ben => (OTHERS => '0'),
        stb => '0', rw => '0', src => '0', priv => '0', debug => '0',
        amo => '0', amoop => (OTHERS => '0'), fence => '0'
    );
END PACKAGE;

PACKAGE BODY bus_pkg IS
    CONSTANT TIMEOUT : DELAY_LENGTH := 100 ns;

    FUNCTION build_rpt (
        rw   : CHARACTER;
        addr : STD_ULOGIC_VECTOR(31 DOWNTO 0);
        msg  : STRING
    ) RETURN STRING IS
    BEGIN
        CASE rw IS
            WHEN 'r' =>
                RETURN "read from 0x" & to_hstring(addr) & " " & msg;
            WHEN 'w' =>
                RETURN "write to 0x" & to_hstring(addr) & " " & msg;
            WHEN OTHERS =>
                REPORT "invalid mode" SEVERITY failure;
                RETURN "";
        END CASE;
    END FUNCTION build_rpt;

    FUNCTION build_rpt (
        rw   : CHARACTER;
        addr : STD_ULOGIC_VECTOR(31 DOWNTO 0);
        exp  : STD_ULOGIC_VECTOR(31 DOWNTO 0);
        got  : STD_ULOGIC_VECTOR(31 DOWNTO 0)
    ) RETURN STRING IS
    BEGIN
        RETURN build_rpt(rw, addr, "expected 0x" & to_hstring(exp) & " but got 0x" & to_hstring(got));
    END FUNCTION build_rpt;

    PROCEDURE read (
        SIGNAL clk    : IN STD_ULOGIC;
        SIGNAL req    : OUT bus_req_t;
        SIGNAL rsp    : IN bus_rsp_t;
        CONSTANT addr : IN STD_ULOGIC_VECTOR(31 DOWNTO 0)
    ) IS
    BEGIN
        WAIT UNTIL rising_edge(clk);
        req      <= idle_req;
        req.addr <= addr;
        req.ben  <= (OTHERS => '1');
        req.stb  <= '1';
        WAIT UNTIL rising_edge(clk);
        req.stb <= '0';
        WAIT UNTIL rsp.ack = '1' OR rsp.err = '1' FOR TIMEOUT;
        ASSERT rsp.ack = '1' AND rsp.err = '0'
        REPORT build_rpt('r', addr, "did not ack or terminated with error") SEVERITY failure;
    END PROCEDURE read;

    PROCEDURE write (
        SIGNAL clk    : IN STD_ULOGIC;
        SIGNAL req    : OUT bus_req_t;
        SIGNAL rsp    : IN bus_rsp_t;
        CONSTANT addr : IN STD_ULOGIC_VECTOR(31 DOWNTO 0);
        CONSTANT data : IN STD_ULOGIC_VECTOR(31 DOWNTO 0)
    ) IS
    BEGIN
        WAIT UNTIL rising_edge(clk);
        req      <= idle_req;
        req.addr <= addr;
        req.data <= data;
        req.ben  <= (OTHERS => '1');
        req.rw   <= '1';
        req.stb  <= '1';
        WAIT UNTIL rising_edge(clk);
        req.stb <= '0';
        WAIT UNTIL rsp.ack = '1' OR rsp.err = '1' FOR TIMEOUT;
        ASSERT rsp.ack = '1' AND rsp.err = '0'
        REPORT build_rpt('w', addr, "did not ack or terminated with error") SEVERITY failure;
    END PROCEDURE write;

    PROCEDURE bus_check (
        SIGNAL clk    : IN STD_ULOGIC;
        SIGNAL req    : OUT bus_req_t;
        SIGNAL rsp    : IN bus_rsp_t;
        CONSTANT addr : IN STD_ULOGIC_VECTOR(31 DOWNTO 0);
        CONSTANT mode : IN STRING := "r/w"
    ) IS
    BEGIN
        WAIT UNTIL rising_edge(clk);
        WAIT FOR 1 ns;
        ASSERT rsp.ack = '0'
        REPORT "slave holds ack" SEVERITY failure;
        ASSERT rsp.err = '0'
        REPORT "slave holds err" SEVERITY failure;

        read(clk, req, rsp, addr);
        CASE (mode) IS
            WHEN "r/w" | "r/-" | "r/c" =>
                NULL; -- can't assume any content
            WHEN "0/-" =>
                ASSERT rsp.data = x"0000_0000"
                REPORT build_rpt('r', addr, x"0000_0000", rsp.data) SEVERITY failure;
            WHEN OTHERS =>
                REPORT "invalid mode" SEVERITY failure;
        END CASE;

        CASE (mode) IS
            WHEN "r/c" =>
                write(clk, req, rsp, addr, x"0000_0000");
            WHEN OTHERS =>
                write(clk, req, rsp, addr, x"dead_beef");
        END CASE;

        read(clk, req, rsp, addr);
        CASE (mode) IS
            WHEN "r/w" =>
                ASSERT rsp.data = x"dead_beef"
                REPORT build_rpt('r', addr, x"dead_beef", rsp.data) SEVERITY failure;
            WHEN "r/-" | "r/c" | "0/-" =>
                ASSERT rsp.data = x"0000_0000"
                REPORT build_rpt('r', addr, x"0000_0000", rsp.data) SEVERITY failure;
            WHEN OTHERS =>
                REPORT "invalid mode" SEVERITY failure;
        END CASE;
    END PROCEDURE bus_check;

    PROCEDURE bus_check (
        SIGNAL clk    : IN STD_ULOGIC;
        SIGNAL req    : OUT bus_req_t;
        SIGNAL rsp    : IN bus_rsp_t;
        CONSTANT addr : IN STD_ULOGIC_VECTOR(31 DOWNTO 0);
        CONSTANT wr   : IN STD_ULOGIC_VECTOR(31 DOWNTO 0); -- data to write
        CONSTANT rd   : IN STD_ULOGIC_VECTOR(31 DOWNTO 0)  -- expected data to read
    ) IS
    BEGIN
        write(clk, req, rsp, addr, wr);
        read(clk, req, rsp, addr);
        ASSERT std_match(rsp.data, rd)
        REPORT build_rpt('r', addr, rd, rsp.data) SEVERITY failure;
    END PROCEDURE bus_check;
END PACKAGE BODY;
