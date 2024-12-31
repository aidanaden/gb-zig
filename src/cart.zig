const std = @import("std");
const Allocator = std.mem.Allocator;

const CartHeader = struct {
    entry: []u8,
    logo: []u8,
    // Game title in uppercase ASCII
    title: []u8,
    cgb_flag: u8,
    new_lic_code: LicCode,
    sgb_support: bool,
    cart_type: CartType,
    rom_size: u32,
    ram_size: u8,
    destination: Destination,
    old_lic_code: LicCode,
    version: u8,
    checksum: u8,
    valid_checksum: bool,
    global_checksum: u16,

    const Self = @This();
    pub fn from_bytes(bytes: []u8) Self {
        if (bytes.len != 80) {
            @panic("invalid cart header length");
        }

        var i: usize = 0;
        const entry = bytes[0..4];
        i += 4;

        // Gameboy Logo
        const logo = bytes[i..][0..0x30];
        i += 0x30;

        // Cartridge Title
        const title = bytes[i..][0..15];
        i += 15;

        // CGB Support
        const cgb_flag = bytes[i];
        i += 1;

        // New License Code
        const raw_new_lic_code = std.mem.readInt(u16, bytes[i..][0..2], .big);
        i += 2;
        const new_lic_code = LicCode.from_new_code(raw_new_lic_code);

        // SGB Support
        const sgb_flag = bytes[i];
        const supports_sgb = sgb_flag == 0x03;
        i += 1;

        // Cart Type
        const raw_cart_type = bytes[i];
        i += 1;
        const cart_type = CartType.from_code(raw_cart_type);
        const cart_has_ram = cart_type.has_ram();

        // ROM Size
        const raw_rom_size: u8 = bytes[i];
        i += 1;
        const rom_size = @as(u32, @intCast(32 * (@as(u256, 1) << raw_rom_size)));

        // RAM Size
        const ram_size = bytes[i];
        i += 1;

        if (cart_has_ram == false and ram_size > 0) {
            @panic("ram size should not exist in cart that cannot have ram!");
        }

        // Destination Code
        const dest_code = bytes[i];
        i += 1;
        const destination = Destination.from_code(dest_code);

        // Old License Code
        const raw_lic_code = bytes[i];
        i += 1;
        const old_lic_code = LicCode.from_old_code(raw_lic_code);

        // Cartridge Game Version
        const version = bytes[i];
        i += 1;

        // Expected Header Checksum
        const checksum = bytes[i];
        i += 1;

        // Calculated Header Checksum
        var x: u8 = 0;
        var address: u16 = (0x0134 - 0x100);
        while (address <= (0x014C - 0x100)) : (address += 1) {
            x = x -% bytes[address] -% 1;
        }
        const valid = checksum == (x & 0xFF);
        if (!valid) {
            std.log.err("checksum invalid, calculated: {}, expected: {}", .{ x, checksum });
            @panic("checksum failed");
        }

        // Global Checksum
        const global_checksum: u16 = std.mem.readInt(u16, bytes[i..][0..2], .big);

        return Self{
            .entry = entry,
            .logo = logo,
            .title = title,
            .cgb_flag = cgb_flag,
            .new_lic_code = new_lic_code,
            .sgb_support = supports_sgb,
            .cart_type = cart_type,
            .rom_size = rom_size,
            .ram_size = ram_size,
            .destination = destination,
            .old_lic_code = old_lic_code,
            .version = version,
            .checksum = checksum,
            .valid_checksum = valid,
            .global_checksum = global_checksum,
        };
    }

    pub fn pretty_print(self: *const Self) !void {
        return try std.json.stringify(self, .{}, std.io.getStdOut().writer());
    }
};

pub const Cart = struct {
    filename: []const u8,
    size: usize,
    rom_data: []const u8,
    header: CartHeader,
    allocator: Allocator,

    const Self = @This();
    pub fn init(fname: []const u8, allocator: Allocator) !Self {
        const file = try std.fs.cwd().openFile(fname, .{});
        defer file.close();
        const stat = try file.stat();
        const size = stat.size;
        std.debug.print("ROM file {s} of size: {d}\n", .{ fname, size });

        const reader = file.reader();
        const bytes = try reader.readAllAlloc(allocator, size);

        // Header is found from 0x100 to 0x14F
        const header_bytes: []u8 = bytes[0x100 .. 0x14F + 1];
        const header = CartHeader.from_bytes(header_bytes);

        try header.pretty_print();

        return Self{
            .filename = fname,
            .size = size,
            .rom_data = bytes,
            .allocator = allocator,
            .header = header,
        };
    }
};

const LicCode = enum {
    None,
    @"Nintendo R&D1",
    Capcom,
    @"Hudson Soft",
    @"b-ai",
    kss,
    pow,
    @"PCM Complete",
    @"san-x",
    @"Kemco Japan",
    seta,
    Viacom,
    Nintendo,
    Bandai,
    Hector,
    Taito,
    Hudson,
    Banpresto,
    UbiSoft,
    Atlus,
    Malibu,
    angel,
    @"Bullet-Proof",
    irem,
    Absolute,
    Acclaim,
    Activision,
    @"American sammy",
    Konami,
    @"Hi tech entertainment",
    LJN,
    Matchbox,
    Mattel,
    @"Milton Bradley",
    Titus,
    Virgin,
    LucasArts,
    Ocean,
    @"Electronic Arts",
    Infogrames,
    Interplay,
    Broderbund,
    sculptured,
    sci,
    THQ,
    Accolade,
    misawa,
    lozc,
    @"Tokuma Shoten Intermedia",
    @"Tsukuda Original",
    Chunsoft,
    @"Video system",
    @"Ocean/Acclaim",
    Varie,
    @"Yonezawa/s’pal",
    Kaneko,
    @"Pack in soft",
    @"Konami (Yu-Gi-Oh!)",
    @"HOT-B",
    Jaleco,
    @"Coconuts Japan",
    @"Elite Systems",
    @"ITC Entertainment",
    Yanoman,
    @"Japan Clary",
    @"Virgin Games Ltd",
    @"San-X",
    Kemco,
    @"SETA Corporation",
    HectorSoft,
    @"Entertainment Interactive",
    Gremlin,
    @"Malibu Interactive",
    Angel,
    @"Spectrum HoloByte",
    Irem,
    @"US Gold",
    @"Sammy USA Corporation",
    GameTek,
    @"Park Place",
    @"Milton Bradley Company",
    Mindscape,
    Romstar,
    @"Naxat Soft",
    Tradewest,
    @"Titus Interactive",
    @"Ocean Software",
    @"Electro Brain",
    @"Interplay Entertainment",
    @"Sculptured Software",
    @"The Sales Curve Limited",
    @"Triffix Entertainment",
    MicroProse,
    @"Misawa Entertainment",
    @"LOZC G",
    @"Tokuma Shoten",
    @"Bullet-Proof Software",
    @"Vic Tokai Corp",
    @"Ape Inc",
    @"I'Max",
    @"Chunsoft Co",
    @"Video System",
    @"Tsubaraya Productions",
    @"Yonezawa/S'Pal",
    Arc,
    @"Nihon Bussan",
    Tecmo,
    Imagineer,
    Nova,
    @"Hori Electric",
    Kawada,
    Takara,
    @"Technos Japan",
    @"Toei Animation",
    Toho,
    Namco,
    @"Acclaim Entertainment",
    Nexsoft,
    @"Square Enix",
    @"HAL Laboratory",
    SNK,
    @"Pony Canyon",
    @"Culture Brain",
    Sunsoft,
    @"Sony Imagesoft",
    @"Sammy Corporation",
    Square,
    @"Data East",
    @"Tonkin House",
    Koei,
    UFL,
    @"Ultra Games",
    @"VAP,Inc",
    @"Use Corporation",
    SOFEL,
    Quest,
    @"Sigma Enterprises",
    @"ASK Kodansha Co",
    @"Copya System",
    Tomy,
    @"Nippon Computer Systems",
    @"Human Ent.",
    Altron,
    @"Towa Chiki",
    Yutaka,
    Epoch,
    Athena,
    @"Asmik Ace Entertainment",
    Natsume,
    @"King Records",
    @"Epic/Sony Records",
    IGS,
    @"A Wave",
    @"Extreme Entertainment",

    Unknown,

    const Self = @This();
    pub fn from_new_code(code: u16) Self {
        return switch (code) {
            0x00 => Self.None,
            0x01 => Self.@"Nintendo R&D1",
            0x08 => Self.Capcom,
            0x13 => Self.@"Electronic Arts",
            0x18 => Self.@"Hudson Soft",
            0x19 => Self.@"b-ai",
            0x20 => Self.kss,
            0x22 => Self.pow,
            0x24 => Self.@"PCM Complete",
            0x25 => Self.@"san-x",
            0x28 => Self.@"Kemco Japan",
            0x29 => Self.seta,
            0x30 => Self.Viacom,
            0x31 => Self.Nintendo,
            0x32 => Self.Bandai,
            0x33 => Self.@"Ocean/Acclaim",
            0x34 => Self.Konami,
            0x35 => Self.Hector,
            0x37 => Self.Taito,
            0x38 => Self.Hudson,
            0x39 => Self.Banpresto,
            0x41 => Self.UbiSoft,
            0x42 => Self.Atlus,
            0x44 => Self.Malibu,
            0x46 => Self.angel,
            0x47 => Self.@"Bullet-Proof",
            0x49 => Self.irem,
            0x50 => Self.Absolute,
            0x51 => Self.Acclaim,
            0x52 => Self.Activision,
            0x53 => Self.@"American sammy",
            0x54 => Self.Konami,
            0x55 => Self.@"Hi tech entertainment",
            0x56 => Self.LJN,
            0x57 => Self.Matchbox,
            0x58 => Self.Mattel,
            0x59 => Self.@"Milton Bradley",
            0x60 => Self.Titus,
            0x61 => Self.Virgin,
            0x64 => Self.LucasArts,
            0x67 => Self.Ocean,
            0x69 => Self.@"Electronic Arts",
            0x70 => Self.Infogrames,
            0x71 => Self.Interplay,
            0x72 => Self.Broderbund,
            0x73 => Self.sculptured,
            0x75 => Self.sci,
            0x78 => Self.THQ,
            0x79 => Self.Accolade,
            0x80 => Self.misawa,
            0x83 => Self.lozc,
            0x86 => Self.@"Tokuma Shoten Intermedia",
            0x87 => Self.@"Tsukuda Original",
            0x91 => Self.Chunsoft,
            0x92 => Self.@"Video system",
            0x93 => Self.@"Ocean/Acclaim",
            0x95 => Self.Varie,
            0x96 => Self.@"Yonezawa/s’pal",
            0x97 => Self.Kaneko,
            0x99 => Self.@"Pack in soft",
            0xA4 => Self.@"Konami (Yu-Gi-Oh!)",
            else => Self.Unknown,
        };
    }

    // TODO: update old_lic_code
    pub fn from_old_code(code: u8) Self {
        return switch (code) {
            0x00 => Self.None,
            0x01 => Self.Nintendo,
            0x08 => Self.Capcom,
            0x09 => Self.@"HOT-B",
            0x0A => Self.Jaleco,
            0x0B => Self.@"Coconut Japan",
            0x0C => Self.@"Elite Systems",
            0x18 => Self.@"Hudson Soft",
            0x19 => Self.@"b-ai",
            0x20 => Self.kss,
            0x22 => Self.pow,
            0x24 => Self.@"PCM Complete",
            0x25 => Self.@"san-x",
            0x28 => Self.@"Kemco Japan",
            0x29 => Self.seta,
            0x30 => Self.Viacom,
            0x31 => Self.Nintendo,
            0x32 => Self.Bandai,
            0x33 => Self.@"Ocean/Acclaim",
            0x34 => Self.Konami,
            0x35 => Self.Hector,
            0x37 => Self.Taito,
            0x38 => Self.Hudson,
            0x39 => Self.Banpresto,
            0x41 => Self.UbiSoft,
            0x42 => Self.Atlus,
            0x44 => Self.Malibu,
            0x46 => Self.angel,
            0x47 => Self.@"Bullet-Proof",
            0x49 => Self.irem,
            0x50 => Self.Absolute,
            0x51 => Self.Acclaim,
            0x52 => Self.Activision,
            0x53 => Self.@"American sammy",
            0x54 => Self.Konami,
            0x55 => Self.@"Hi tech entertainment",
            0x56 => Self.LJN,
            0x57 => Self.Matchbox,
            0x58 => Self.Mattel,
            0x59 => Self.@"Milton Bradley",
            0x60 => Self.Titus,
            0x61 => Self.Virgin,
            0x64 => Self.LucasArts,
            0x67 => Self.Ocean,
            0x69 => Self.@"Electronic Arts",
            0x70 => Self.Infogrames,
            0x71 => Self.Interplay,
            0x72 => Self.Broderbund,
            0x73 => Self.sculptured,
            0x75 => Self.sci,
            0x78 => Self.THQ,
            0x79 => Self.Accolade,
            0x80 => Self.misawa,
            0x83 => Self.lozc,
            0x86 => Self.@"Tokuma Shoten Intermedia",
            0x87 => Self.@"Tsukuda Original",
            0x91 => Self.Chunsoft,
            0x92 => Self.@"Video system",
            0x93 => Self.@"Ocean/Acclaim",
            0x95 => Self.Varie,
            0x96 => Self.@"Yonezawa/s’pal",
            0x97 => Self.Kaneko,
            0x99 => Self.@"Pack in soft",
            0xA4 => Self.@"Konami (Yu-Gi-Oh!)",
            else => Self.Unknown,
        };
    }
};

const CartType = enum {
    ROM_ONLY,
    MBC1,
    @"MBC1+RAM",
    @"MBC1+RAM+BATTERY",
    @"0x04 ???",
    MBC2,
    @"MBC2+BATTERY",
    @"0x07 ???",
    @"ROM+RAM",
    @"ROM+RAM+BATTERY",
    @"0x0A ???",
    MMM01,
    @"MMM01+RAM",
    @"MMM01+RAM+BATTERY",
    @"0x0E ???",
    @"MBC3+TIMER+BATTERY",
    @"MBC3+TIMER+RAM+BATTERY",
    MBC3,
    @"MBC3+RAM",
    @"MBC3+RAM+BATTERY",
    @"0x14 ???",
    @"0x15 ???",
    @"0x16 ???",
    @"0x17 ???",
    @"0x18 ???",
    MBC5,
    @"MBC5+RAM",
    @"MBC5+RAM+BATTERY",
    @"MBC5+RUMBLE",
    @"MBC5+RUMBLE+RAM",
    @"MBC5+RUMBLE+RAM+BATTERY",
    @"0x1F ???",
    MBC6,
    @"0x21 ???",
    @"MBC7+SENSOR+RUMBLE+RAM+BATTERY",
    @"POCKET CAMERA",
    @"BANDAI TAMA5",
    HuC3,
    @"HuC1+RAM+BATTERY",
    Unknown,

    const Self = @This();
    pub fn from_code(code: u8) Self {
        return switch (code) {
            0x00 => Self.ROM_ONLY,
            0x01 => Self.MBC1,
            0x02 => Self.@"MBC1+RAM",
            0x03 => Self.@"MBC1+RAM+BATTERY",
            0x05 => Self.MBC2,
            0x06 => Self.@"MBC2+BATTERY",
            0x08 => Self.@"ROM+RAM",
            0x09 => Self.@"ROM+RAM+BATTERY",
            0x0B => Self.MMM01,
            0x0C => Self.@"MMM01+RAM",
            0x0D => Self.@"MMM01+RAM+BATTERY",
            0x0F => Self.@"MBC3+TIMER+BATTERY",
            0x10 => Self.@"MBC3+TIMER+RAM+BATTERY",
            0x11 => Self.MBC3,
            0x12 => Self.@"MBC3+RAM",
            0x13 => Self.@"MBC3+RAM+BATTERY",
            0x19 => Self.MBC5,
            0x1A => Self.@"MBC5+RAM",
            0x1B => Self.@"MBC5+RAM+BATTERY",
            0x1C => Self.@"MBC5+RUMBLE",
            0x1D => Self.@"MBC5+RUMBLE+RAM",
            0x1E => Self.@"MBC5+RUMBLE+RAM+BATTERY",
            0x20 => Self.MBC6,
            0x22 => Self.@"MBC7+SENSOR+RUMBLE+RAM+BATTERY",
            0xFC => Self.@"POCKET CAMERA",
            0xFD => Self.@"BANDAI TAMA5",
            0xFE => Self.HuC3,
            0xFF => Self.@"HuC1+RAM+BATTERY",
            else => Self.Unknown,
        };
    }

    pub fn has_ram(self: *const Self) bool {
        const name: []const u8 = @tagName(self.*);
        return std.mem.containsAtLeast(u8, name, 1, "RAM");
    }
};

const Destination = enum {
    OverseasOnly,
    JapanAndOverseas,
    const Self = @This();
    pub fn from_code(code: u8) Self {
        return if (code == 0x00) Self.JapanAndOverseas else Self.OverseasOnly;
    }
};
