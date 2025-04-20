/**
 * @file tool.c
 * @author Niklaus Leuenberger <@NikLeberg>
 * @brief Simple neorv32 firmware to write specific value to GPIOs.
 * @version 0.1
 * @date 2025-04-15
 *
 * SPDX-License-Identifier: MIT
 *
 * Changes:
 * Version  Date        Author     Detail
 * 0.1      2025-04-15  NikLeberg  initial version
 *
 */

#include <neorv32.h>

int main(void)
{
    neorv32_gpio_port_set(0xdeadbeef);
    for (;;)
        neorv32_cpu_sleep();
}
