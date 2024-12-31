const std = @import("std");
const sdl = @cImport({
    @cInclude("SDL2/SDL.h");
});
const Cart = @import("./cart.zig").Cart;

window: *sdl.SDL_Window,
renderer: *sdl.SDL_Renderer,
texture: *sdl.SDL_Texture,

cart: ?*Cart,

ticks: usize,
paused: bool,
live: bool,

const Self = @This();
pub fn init() !Self {
    const window = sdl.SDL_CreateWindow("Chip8-zig", sdl.SDL_WINDOWPOS_UNDEFINED, sdl.SDL_WINDOWPOS_UNDEFINED, 1024, 512, sdl.SDL_WINDOW_OPENGL) orelse
        {
        sdl.SDL_Log("Unable to create window: %s", sdl.SDL_GetError());
        return error.SDLInitializationFailed;
    };
    const renderer = sdl.SDL_CreateRenderer(window, -1, 0) orelse {
        sdl.SDL_Log("Unable to create renderer: %s", sdl.SDL_GetError());
        return error.SDLInitializationFailed;
    };
    const texture = sdl.SDL_CreateTexture(renderer, sdl.SDL_PIXELFORMAT_RGB888, sdl.SDL_TEXTUREACCESS_STREAMING, 64, 32) orelse {
        sdl.SDL_Log("Unable to create texture: %s", sdl.SDL_GetError());
        return error.SDLInitializationFailed;
    };
    return Self{
        .window = window,
        .renderer = renderer,
        .texture = texture,
        .ticks = 0,
        .paused = false,
        .live = false,
        .cart = null,
    };
}

// Deinit in reverse order of init
pub fn deinit(self: *const Self) void {
    sdl.SDL_DestroyTexture(self.texture);
    sdl.SDL_DestroyRenderer(self.renderer);
    sdl.SDL_DestroyWindow(self.window);
    sdl.SDL_Quit();
}

pub fn load_rom(self: *Self, fname: []const u8, allocator: std.mem.Allocator) !void {
    var cart = try Cart.init(fname, allocator);
    self.cart = &cart;
}

pub fn run(self: *const Self) void {
    self.live = true;
    while (self.live) {
        if (self.paused) {
            sdl.SDL_Delay(10);
            continue;
        }

        // Emulator cycle
        // cpu.cycle();

        var event: sdl.SDL_Event = undefined;
        while (sdl.SDL_PollEvent(&event) != 0) {
            switch (event.type) {
                sdl.SDL_QUIT => {
                    self.live = false;
                },
                sdl.SDL_KEYDOWN => {
                    for (0..16) |_| {
                        // if (event.key.keysym.scancode == KEYMAP[i]) {
                        // cpu.keys[i] = 1;
                        // }
                    }
                },
                sdl.SDL_KEYUP => {
                    for (0..16) |_| {
                        // if (event.key.keysym.scancode == KEYMAP[i]) {
                        // cpu.keys[i] = 0;
                        // }
                    }
                },
                else => {},
            }
        }

        // sdl_context.tick(&cpu);

    }
}

// tick rate of 16ms for 60fps
const TICK_RATE_MS: usize = 60 / 1000;

// pub fn tick(self: *const Self, cpu: *const Chip8) void {
pub fn tick(self: *const Self) void {
    self.ticks += 1;

    // _ = sdl.SDL_RenderClear(self.renderer);
    //
    // // Build texture
    // var bytes: ?[*]u32 = null;
    // var pitch: c_int = 0;
    // _ = sdl.SDL_LockTexture(self.texture, null, @ptrCast(&bytes), &pitch);
    //
    // var y: usize = 0;
    // while (y < GRAPHIC_HEIGHT) : (y += 1) {
    //     var x: usize = 0;
    //     while (x < GRAPHIC_WIDTH) : (x += 1) {
    //         // Graphic pixels are stored row by row in a single array
    //         bytes.?[y * GRAPHIC_WIDTH + x] = if (cpu.graphics[y * GRAPHIC_WIDTH + x] == 1) 0xFFFFFFFF else 0x000000FF;
    //     }
    // }
    // sdl.SDL_UnlockTexture(self.texture);
    //
    // _ = sdl.SDL_RenderCopy(self.renderer, self.texture, null, null);
    // sdl.SDL_RenderPresent(self.renderer);
    //
    // sdl.SDL_Delay(TICK_RATE_MS);
}
