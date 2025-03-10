const regs = @import("registers.zig");

pub fn main() void {
    systemInit();

    // Enable GPIOB port
    regs.RCC.AHB2ENR.modify(.{ .GPIOBEN = 1 });

    // Set pin 2 mode to general purpose output
    regs.GPIOB.MODER.modify(.{
        .MODER0 = 0b01, 
        .MODER1 = 0b01, 
        .MODER2 = 0b01, 
        .MODER3 = 0b01, 
        .MODER4 = 0b01, 
        .MODER5 = 0b01, 
        .MODER6 = 0b01, 
        .MODER7 = 0b01, 
        .MODER8 = 0b01, 
        .MODER9 = 0b01, 
        .MODER10 = 0b01, 
        .MODER11 = 0b01, 
        .MODER12 = 0b01, 
        .MODER13 = 0b01, 
        .MODER14 = 0b01, 
        .MODER15 = 0b01, 
    });

    // Set pin 2
    regs.GPIOB.BSRR.modify(.{ .BS2 = 1 });

    while (true) {
        // Read the LED state
        var leds_state = regs.GPIOB.ODR.read_raw();
        // Set the LED output to the negation of the currrent output
        regs.GPIOB.ODR.write_raw(~leds_state);

        // Sleep for some time
        var i: u32 = 0;
        while (i < 600000) {
            asm volatile ("nop");
            i += 1;
        }
    }
}

fn systemInit() void {
    // This init does these things:
    // - Enables the FPU coprocessor
    // - Sets the external oscillator to achieve a clock frequency of 168MHz
    // - Sets the correct PLL prescalers for that clock frequency
    // - Enables the flash data and instruction cache and sets the correct latency for 168MHz

    // Enable FPU coprocessor
    // WARN: currently not supported in qemu, comment if testing it there
    regs.FPU_CPACR.CPACR.modify(.{ .CP = 0b11 });

    // Enable HSI
    regs.RCC.CR.modify(.{ .HSION = 1 });

    // Wait for HSI ready
    while (regs.RCC.CR.read().HSIRDY != 1) {}

    // Select HSI as clock source
    // regs.RCC.CFGR.modify(.{ .SW0 = 0, .SW1 = 0 });

    // Enable external high-speed oscillator (HSE)
    regs.RCC.CR.modify(.{ .HSEON = 1 });

    // Wait for HSE ready
    while (regs.RCC.CR.read().HSERDY != 1) {}

    // Set prescalers for 168 MHz: HPRE = 0, PPRE1 = DIV_2, PPRE2 = DIV_4
    regs.RCC.CFGR.modify(.{ .HPRE = 0, .PPRE1 = 0b101, .PPRE2 = 0b100 });

    // Disable PLL before changing its configuration
    regs.RCC.CR.modify(.{ .PLLON = 0 });

    // Set PLL prescalers and HSE clock source
    // TODO: change the svd to expose prescalers as packed numbers instead of single bits
    regs.RCC.PLLCFGR.modify(.{
        .PLLSRC = 1,
        // PLLM = 8 = 0b001000
        .PLLM = 4,
        // PLLN = 336 = 0b101010000
        .PLLN = 120,
        // PLLP = 2 = 0b10
        .PLLP = 1,
        // PLLQ = 7 = 0b111
        .PLLQ = 2,
    });

    // Enable PLL
    regs.RCC.CR.modify(.{ .PLLON = 1 });

    // Wait for PLL ready
    while (regs.RCC.CR.read().PLLRDY != 1) {}

    // Enable flash data and instruction cache and set flash latency to 5 wait states
    regs.FLASH.ACR.modify(.{ .DCEN = 1, .ICEN = 1, .LATENCY = 5 });

    // Select PLL as clock source
    regs.RCC.CFGR.modify(.{ .SW = 2 });

    // Wait for PLL selected as clock source
    var cfgr = regs.RCC.CFGR.read();
    while (cfgr.SWS != 1) : (cfgr = regs.RCC.CFGR.read()) {}

    // Disable HSI
    regs.RCC.CR.modify(.{ .HSION = 0 });
}