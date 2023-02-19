/**
 *****************************************************************************
 * @author      xqyjlj
 * @file        APM32F103xE.lds
 * @brief       linker script for APM32F103xE Device
 *
 *****************************************************************************
 * @attention
 * Licensed under the Apache License, Version 2.0 (the "License");
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * Copyright (C) 2022-2023 xqyjlj<xqyjlj@126.com>
 *
 *****************************************************************************
 * Change Logs:
 * Date           Author       Notes
 * ------------   ----------   -----------------------------------------------
 * 2023-01-02     xqyjlj       initial version
 */

ENTRY(Reset_Handler)

_system_stack_size = 0x400; /* system stack size */

MEMORY
{
    FLASH (rx)  : ORIGIN = 0x08000000, LENGTH = 512K
    RAM (xrw)   : ORIGIN = 0x20000000, LENGTH = 128k
}

SECTIONS
{
    .isr_vector :
    {
        . = ALIGN(4);
        __isr_vector_start = .;
        KEEP(*(.isr_vector))    /* isr vector table */
        . = ALIGN(4);
        __isr_vector_end = .;
    } >FLASH

    .text :
    {
        . = ALIGN(4);
        _stext = .;
        __text_start = .;
        *(.text)                /* remaining code */
        *(.text.*)              /* remaining code */ 
        *(.rodata)              /* read-only data */
        *(.rodata*)             /* read-only data */
        *(.glue_7)              /* glue arm to thumb code */
        *(.glue_7t)             /* glue thumb to arm code */
        *(.eh_frame)            /* unwind the stack */
        *(.gnu.linkonce.t*)

        KEEP (*(.init))
        KEEP (*(.fini))

        . = ALIGN(4);
        _etext = .;
        __text_end = .;
    } >FLASH

    .ARM.extab :
    {
        __extab_start = .;
        *(.ARM.extab* .gnu.linkonce.armextab.*)
        __extab_end = .;
    } >FLASH

    .ARM.exidx :
    {
        __exidx_start = .;
        *(.ARM.exidx*)
        __exidx_end = .;
    } >FLASH

    /**************************************************************/

    _sidata = LOADADDR(.data);
    .data :
    {
        . = ALIGN(4);
        _sdata = .;
        __data_start = .;
        *(.data)
        *(.data*)
        *(.gnu.linkonce.d*)

        PROVIDE(__dtors_start__ = .);
        KEEP(*(SORT(.dtors.*)))
        KEEP(*(.dtors))
        PROVIDE(__dtors_end__ = .);

        . = ALIGN(4);
        _edata = .;
        __data_end = .;
    } >RAM AT> FLASH

    .system_stack :
    {
        . = ALIGN(4);
        _sstack = .;
        __system_stack_start = .;
        . = . + _system_stack_size;
        . = ALIGN(4);
        _estack = .;
        __system_stack_end = .;
    } >RAM

    .bss :
    {
        . = ALIGN(4);
        _sbss = .;
        __bss_start = .;
        *(.bss)
        *(.bss.*)
        *(COMMON)

        . = ALIGN(4);
        _ebss = .;
        __bss_end = .;
    } >RAM

    /DISCARD/ :
    {
        libc.a ( * )
        libm.a ( * )
        libgcc.a ( * )
    }

    .ARM.attributes 0 :{ *(.ARM.attributes) }
}
