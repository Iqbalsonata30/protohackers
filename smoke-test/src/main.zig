const std = @import("std");
const posix = std.posix;
const assert = std.debug.assert;
const net = std.net;

pub fn main() !void {
    const localhost = [4]u8{ 127, 0, 0, 1 };
    const server_addr = net.Address.initIp4(localhost, 8080);
    var client_addr = net.Address.initIp4(.{ 0, 0, 0, 0 }, 0);
    var client_addr_len = client_addr.getOsSockLen();

    const socket_fd = try posix.socket(posix.AF.INET, posix.SOCK.STREAM, 0);
    if (socket_fd == -1) {
        std.debug.panic("failed to create socket", .{});
    }
    defer posix.close(socket_fd);

    std.debug.print("server addr: {any}\n ", .{server_addr});
    try posix.bind(socket_fd, @ptrCast(&server_addr), @sizeOf(@TypeOf(server_addr)));
    try posix.listen(socket_fd, @as(u31, 5));

    const client_fd = try posix.accept(socket_fd, @ptrCast(&client_addr), &client_addr_len, 0);
    std.debug.print("client addr: {any}\n client addr len : {d}\n", .{ client_addr, client_addr_len });
    std.debug.print("{any}\n", .{client_fd});
}

// send data to a server and echo the data back
// receive data from a client, send it back unmodified
// 1.Accept TCP Connections
// 2. Handle at least 5 connections
// Implement TCP Echo Service : https://www.rfc-editor.org/rfc/rfc862.htl
