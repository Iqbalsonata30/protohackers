// Prime Time
//
//  Accept TCP Connection
//  Whenever receive a conforming request, send back a correct response and wait for another request
//  Whenever you receive a malformed request, send back a single malformed response, and disconnect the client.
//  Handle at least 5 Connection
//
//  Example Response
//  {"method":"isPrime","prime":false}
//

const std = @import("std");
const posix = std.posix;
const net = std.net;

pub fn main() !void {
    const sock_addr = net.Ip4Address.init([4]u8{ 0, 0, 0, 0 }, 1234);
    const sock_addr_len = @sizeOf(posix.sockaddr.in);

    const sock_fd = posix.socket(posix.AF.INET, posix.SOCK.STREAM, 0) catch |err| {
        std.debug.print("failed to create socket : {?}\n", .{err});
        return;
    };
    defer posix.close(sock_fd);

    posix.bind(sock_fd, @ptrCast(&sock_addr), sock_addr_len) catch |err| {
        std.debug.print("error bind socket : {?}\n", .{err});
        return;
    };
    posix.listen(sock_fd, 5) catch |err| {
        std.debug.print("error listen socket : {?}\n", .{err});
        return;
    };

    var peer_socket = net.Ip4Address.init([4]u8{ 0, 0, 0, 0 }, 1234);
    var peer_socket_len: u32 = @sizeOf(@TypeOf(peer_socket));

    var conn: posix.socket_t = try posix.accept(sock_fd, @ptrCast(&peer_socket), &peer_socket_len, 0);
    defer posix.close(conn);

    while (conn > 0) : (conn = try posix.accept(sock_fd, @ptrCast(&peer_socket), &peer_socket_len, 0)) {
        std.debug.print("address:{any} is connecting\n", .{peer_socket});
    }
}
