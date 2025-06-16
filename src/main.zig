const std = @import("std");

const print = std.debug.print;

/// Enables Raw Mode Input to terminal
pub fn buffer_off(stdin: std.fs.File) !void {
    var terminal = std.posix.tcgetattr(stdin.handle) catch |err| {
        die(err);
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
        die(err);
    };
}

/// Disables Raw Mode Input to terminal
pub fn buffer_on(stdin: std.fs.File) !void {
    var terminal = std.posix.tcgetattr(stdin.handle) catch |err| {
        die(err);
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
        die(err);
    };
}

/// Prints error and exits progam
pub fn die(message: anyerror) noreturn {
    std.log.err("{any}", .{message});
    std.process.exit(1);
}

pub fn main() !void {
    const stdin = std.io.getStdIn();
    try buffer_off(stdin);
    defer buffer_on(stdin) catch {};

    while (true) {
        const char = try stdin.reader().readByte();
        if (char == 'q') {
            break;
        }
        if (std.ascii.isControl(char)) {
            print("{d}\r\n", .{char});
        } else {
            print("{c}\r\n", .{char});
        }
    }
    try buffer_on(stdin);
}
