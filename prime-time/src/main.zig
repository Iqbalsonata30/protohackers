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
const mem = std.mem;

const IPv4 = extern struct {
    sa: posix.sockaddr.in,

    pub fn init(addr: [4]u8, port: u16) IPv4 {
        return IPv4{ .sa = .{
            .port = mem.nativeToBig(u16, port),
            .addr = @as(*align(1) const u32, @ptrCast(&addr)).*,
        } };
    }

    pub fn format(self: IPv4, comptime fmt: []const u8, options: std.fmt.FormatOptions, out_stream: anytype) !void {
        if (fmt.len != 0) std.fmt.invalidFmtError(fmt, self);
        _ = options;
        const bytes = @as(*const [4]u8, @ptrCast(&self.sa.addr));
        try std.fmt.format(out_stream, "{}.{}.{}.{}:{}", .{
            bytes[0],
            bytes[1],
            bytes[2],
            bytes[3],
            mem.bigToNative(u16, self.sa.port),
        });
    }
};

pub fn main() !void {
    const sock_addr = IPv4.init([4]u8{ 0, 0, 0, 0 }, 1234);
    const sock_addr_len = @sizeOf(posix.sockaddr.in);

    const sock_fd = try posix.socket(posix.AF.INET, posix.SOCK.STREAM, 0);
    defer posix.close(sock_fd);

    _ = try posix.bind(sock_fd, @ptrCast(&sock_addr), sock_addr_len);
    _ = try posix.listen(sock_fd, 5);

    var peer_socket = IPv4.init([4]u8{ 0, 0, 0, 0 }, 1234);
    var peer_socket_len: u32 = @sizeOf(@TypeOf(peer_socket));

    var conn: posix.socket_t = try posix.accept(sock_fd, @ptrCast(&peer_socket), &peer_socket_len, 0);
    defer posix.close(conn);

    while (conn > 0) : (conn = try posix.accept(sock_fd, @ptrCast(&peer_socket), &peer_socket_len, 0)) {
        std.debug.print("address:{any} is connecting\n", .{peer_socket});
    }
}
