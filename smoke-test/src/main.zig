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
    var client_fd: posix.socket_t = undefined;
    const server_addr = net.Address.initIp4(.{ 0, 0, 0, 0 }, 9999);

    const srv_fd = try posix.socket(posix.AF.INET, posix.SOCK.STREAM, 0);
    if (srv_fd == -1) {
        std.debug.panic("failed to create socket", .{});
    }
    defer posix.close(srv_fd);

    try posix.setsockopt(srv_fd, posix.SOL.SOCKET, posix.SO.REUSEADDR, &std.mem.toBytes(@as(c_int, 1)));
    if (@hasDecl(posix.SO, "REUSEPORT")) {
        try posix.setsockopt(srv_fd, posix.SOL.SOCKET, posix.SO.REUSEPORT, &std.mem.toBytes(@as(c_int, 1)));
    }

    try posix.bind(srv_fd, &server_addr.any, @sizeOf(@TypeOf(server_addr)));
    try posix.listen(srv_fd, 10);

    var client_addr = net.Address.initIp4(.{ 0, 0, 0, 0 }, 0);
    var client_addr_len: posix.socklen_t = @sizeOf(@TypeOf(client_addr));

    std.debug.print("server running on port {d}\n", .{server_addr.getPort()});
    client_fd = try posix.accept(srv_fd, &client_addr.any, &client_addr_len, 0);
    while (client_fd > 0) : (client_fd = try posix.accept(srv_fd, &client_addr.any, &client_addr_len, 0)) {
        const thread = try std.Thread.spawn(.{}, worker, .{client_fd});
        defer thread.join();
    }
}

fn worker(client_fd: posix.socket_t) !void {
    std.debug.print("worker starting...\n", .{});

    var data_size: usize = 0;
    var buffer: [1024]u8 = undefined;

    data_size = try posix.recv(client_fd, &buffer, 0);
    while (data_size > 0) {
        std.debug.print("size of the data : {d}\n", .{data_size});

        const message = buffer[0..data_size];
        const data_sent = try posix.send(client_fd, message, 0);
        std.debug.assert(data_sent != 0);

        std.debug.print("received message : {s}", .{message});
        std.debug.print("sent message : {s}", .{message});
        data_size = try posix.recv(client_fd, &buffer, 0);
    }

    if (data_size < 0) {
        std.debug.panic("received failed\n", .{});
    } else {
        std.debug.print("client disconnect\n", .{});
    }
    defer posix.close(client_fd);
}
