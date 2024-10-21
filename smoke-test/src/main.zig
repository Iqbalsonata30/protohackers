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
    std.debug.print("server addr: {any}\n", .{server_addr});

    var client_addr = net.Address.initIp4(.{ 0, 0, 0, 0 }, 0);
    var client_addr_len: posix.socklen_t = @sizeOf(@TypeOf(client_addr));
    client_fd = try posix.accept(srv_fd, @ptrCast(&client_addr), &client_addr_len, 0);
    defer posix.close(client_fd);
    while (true) {
        if (client_fd == -1) {
            std.debug.panic("failed to accept connection", .{});
        }
        const thread = try std.Thread.spawn(.{}, worker, .{client_fd});
        defer thread.join();
    }
}

fn worker(client_fd: posix.socket_t) !void {
    var m = std.Thread.Mutex{};
    var data_size: usize = 0;
    var buffer: [1024]u8 = undefined;
    data_size = try posix.recv(client_fd, &buffer, 0);
    while (data_size > 0) : (data_size = try posix.recv(client_fd, &buffer, 0)) {
        m.lock();
        defer m.unlock();
        const data_sent = try posix.send(client_fd, &buffer, 0);
        std.debug.print("sent message : {any}\n", .{data_sent});
    }
    defer posix.close(client_fd);
}

// send data to a server and echo the data back
// receive data from a client, send it back unmodified
// 1. Accept TCP Connections
// 2. Handle at least 5 connections
//
// Implement TCP Echo Service : https://www.rfc-editor.org/rfc/rfc862.htl
//
//
// next find way to handle 5 simultaneos connections
// why i need thread, if i met the end of bytes, i kill the connection,
//
