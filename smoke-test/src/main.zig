const std = @import("std");
const posix = std.posix;
const assert = std.debug.assert;
const net = std.net;

pub fn main() !void {
    const localhost = [4]u8{ 127, 0, 0, 1 };
    const server_addr = net.Address.initIp4(localhost, 8080);
    var client_addr = net.Address.initIp4(.{ 0, 0, 0, 0 }, 0);
    var client_addr_len = client_addr.getOsSockLen();
    var buffer: [1024]u8 = undefined;

    const socket_fd = try posix.socket(posix.AF.INET, posix.SOCK.STREAM, 0);
    if (socket_fd == -1) {
        std.debug.panic("failed to create socket", .{});
    }
    defer posix.close(socket_fd);

    std.debug.print("server addr: {any}\n", .{server_addr});
    try posix.bind(socket_fd, @ptrCast(&server_addr), @sizeOf(@TypeOf(server_addr)));
    try posix.listen(socket_fd, @as(u31, 5));

    while (true) {
        const client_fd = try posix.accept(socket_fd, @ptrCast(&client_addr), &client_addr_len, 0);
        defer posix.close(client_fd);
        if (client_fd == -1) {
            std.debug.panic("failed to accept connection", .{});
        }

        const data_received = try posix.recv(client_fd, &buffer, 0);
        if (data_received < 0) {
            std.debug.panic("data has no received", .{});
        }
        const message = buffer[0..data_received];
        std.debug.print("from client : {any}\n", .{client_addr});
        std.debug.print("received message: {s}", .{message});

        const data_sent = try posix.send(client_fd, message, 0);
        if (data_sent < 0) {
            std.debug.panic("failed to send message", .{});
        }
        std.debug.print("sent to client : {any}\n", .{client_addr});
        std.debug.print("sent message : {s}\n", .{message});
    }
}

fn handleConnection() void {}

// send data to a server and echo the data back
// receive data from a client, send it back unmodified
// 1.Accept TCP Connections
// 2. Handle at least 5 connections
// Implement TCP Echo Service : https://www.rfc-editor.org/rfc/rfc862.htl
