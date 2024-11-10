// 1. Accept TCP Connections -> passed
// 2. Handle at least 5 connections -> passed
// 3. Receive message and send it back unmodified. ->passed
//
// What is TCP Echo Service : https://www.rfc-editor.org/rfc/rfc862.htl

const std = @import("std");
const posix = std.posix;
const assert = std.debug.assert;
const net = std.net;

pub fn main() !void {
    const address = try net.Address.resolveIp("0.0.0.0", 1234);

    const listener = try posix.socket(posix.AF.INET, posix.SOCK.STREAM, 0);
    defer posix.close(listener);

    try posix.setsockopt(listener, posix.SOL.SOCKET, posix.SO.REUSEADDR, &std.mem.toBytes(@as(c_int, 1)));
    posix.bind(listener, @ptrCast(&address), address.getOsSockLen()) catch |err| {
        std.debug.print("failed to bind socket : {?}\n", .{err});
        return err;
    };

    posix.listen(listener, 128) catch |err| {
        std.debug.print("failed to listen socket : {?}\n", .{err});
        return err;
    };

    while (true) {
        var buf: [1024]u8 = undefined;
        var client_address: net.Address = undefined;
        var client_address_len: posix.socklen_t = @sizeOf(posix.sockaddr.in);

        const conn = posix.accept(listener, @ptrCast(&client_address), &client_address_len, 0) catch |err| {
            std.debug.print("failed to accept connection : {?}\n", .{err});
            continue;
        };
        defer posix.close(conn);

        std.debug.print("{any} is connecting\n", .{client_address});
        echoMsg(conn, &buf) catch |err| switch (err) {
            error.Closed => {
                std.debug.print("client diconnected\n", .{});
                continue;
            },
            else => {
                std.debug.print("failed to read connection : {?}\n", .{err});
                continue;
            },
        };
    }
}

fn echoMsg(socket: posix.socket_t, buf: []u8) !void {
    var read = try posix.read(socket, buf);
    while (read > 0) : (read = try posix.read(socket, buf)) {
        const msg = buf[0..read];
        try writeMsg(socket, msg);
    }

    if (read == 0) {
        return error.Closed;
    }
}

fn writeMsg(socket: posix.socket_t, msg: []u8) !void {
    var pos: usize = 0;
    while (pos < msg.len) {
        const written = try posix.write(socket, msg[pos..]);
        if (written == 0) {
            return error.Closed;
        }
        pos += written;
    }
}
