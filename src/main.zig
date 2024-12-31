const std = @import("std");
const Allocator = std.mem.Allocator;
const Emulator = @import("./emu.zig");

// const KEYMAP: [16]c_int = [_]c_int{
//     sdl.SDL_SCANCODE_X,
//     sdl.SDL_SCANCODE_1,
//     sdl.SDL_SCANCODE_2,
//     sdl.SDL_SCANCODE_3,
//     sdl.SDL_SCANCODE_Q,
//     sdl.SDL_SCANCODE_W,
//     sdl.SDL_SCANCODE_E,
//     sdl.SDL_SCANCODE_A,
//     sdl.SDL_SCANCODE_S,
//     sdl.SDL_SCANCODE_D,
//     sdl.SDL_SCANCODE_Z,
//     sdl.SDL_SCANCODE_C,
//     sdl.SDL_SCANCODE_4,
//     sdl.SDL_SCANCODE_R,
//     sdl.SDL_SCANCODE_F,
//     sdl.SDL_SCANCODE_V,
// };

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var arg_it = try std.process.argsWithAllocator(allocator);
    // We skip the first argument since it's
    // the current executable file path
    _ = arg_it.skip();

    const filename = arg_it.next() orelse {
        std.debug.print("No ROM added!", .{});
        return;
    };

    var emulator = try Emulator.init();
    defer emulator.deinit();

    // Load ROM into cpu
    try emulator.load_rom(filename, allocator);

    // try emulator.run();
}
