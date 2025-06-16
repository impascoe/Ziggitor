const std = @import("std");


const print = std.debug.print;

pub fn ctrlKey(comptime key: u8) u8 {
    return key & 0x1f;
}

/// Enables Raw Mode Input to terminal
pub fn bufferOff(stdin: std.fs.File) !void {
    var terminal = std.posix.tcgetattr(stdin.handle) catch |err| {
        die(stdin, err);
    };
    terminal.cflag.CSIZE = .CS8;
    terminal.iflag = .{
        .BRKINT = false,
        .INPCK = false,
        .ISTRIP = false,
        .IXON = false,
        .ICRNL = false,
    };
    terminal.lflag = .{
        .ICANON = false,
        .ECHO = false,
        .ISIG = false,
        .IEXTEN = false,
    };
    terminal.oflag.OPOST = false;

    std.posix.tcsetattr(stdin.handle, .NOW, terminal) catch |err| {
        die(stdin, err);
    };
}

/// Disables Raw Mode Input to terminal
pub fn bufferOn(stdin: std.fs.File) !void {
    var terminal = std.posix.tcgetattr(stdin.handle) catch |err| {
        die(stdin, err);
    };
    terminal.cflag.CSIZE = .CS5;
    terminal.iflag = .{
        .BRKINT = true,
        .INPCK = true,
        .ISTRIP = true,
        .IXON = true,
        .ICRNL = true,
    };
    terminal.lflag = .{
        .ICANON = true,
        .ECHO = true,
        .ISIG = true,
        .IEXTEN = true,
    };
    terminal.oflag.OPOST = true;
    std.posix.tcsetattr(stdin.handle, .NOW, terminal) catch |err| {
        die(stdin, err);
    };
}

/// Prints error and exits progam
pub fn die(stdin: std.fs.File, message: anyerror) noreturn {
    refreshScreen(stdin) catch {};
    std.log.err("{any}", .{message});
    std.process.exit(1);
}

pub fn readKey(stdin: std.fs.File) !u8 {
    return try stdin.reader().readByte();
}

pub fn drawRows() !void {
    const rows = 24;
    const stdout = std.io.getStdOut();

    var i: u16 = 0;
    while (i < rows) : (i += 1) {
        _ = try std.posix.write(stdout.handle, "~");
        if (i < rows - 1) {
            _ = try std.posix.write(stdout.handle, "\r\n");
        }
    }
}

pub fn processKeypress(stdin: std.fs.File) !void {
    const char = try readKey(stdin);
    switch (char) {
        ctrlKey('q') => {
            std.process.exit(0);
        },
        else => {
        },
    }
}

pub fn refreshScreen(stdin: std.fs.File) !void {
    _ = try std.posix.write(stdin.handle, "\x1b[2J");
    _ = try std.posix.write(stdin.handle, "\x1b[H");
    try drawRows();
    _ = try std.posix.write(stdin.handle, "\x1b[H");
}

pub fn main() !void {
    const stdin = std.io.getStdIn();
    try bufferOff(stdin);
    defer bufferOn(stdin) catch {};

    while (true) {
        try refreshScreen(stdin);
        try processKeypress(stdin);
    }
    try bufferOn(stdin);
}
