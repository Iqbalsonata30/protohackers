const std = @import("std");
const posix = std.posix;
const assert = std.debug.assert;

pub fn main() !void {
    const localhost: [4]u8 = .{ 127, 0, 0, 1 };
    const s_addr = posix.sockaddr.in{
        .port = 8080,
        .addr = @bitCast(localhost),
    };

    const socket_fd = try posix.socket(posix.AF.INET, posix.SOCK.STREAM, 0);
    if (socket_fd == -1) {
        std.debug.panic("failed to create socket", .{});
    }
    defer posix.close(socket_fd);

    try posix.bind(socket_fd, @ptrCast(&s_addr), @sizeOf(@TypeOf(s_addr)));


}
// send data to a server and echo the data back
// receive data from a client, send it back unmodified
// 1.Accept TCP Connections
// 2. Handle at least 5 connections
// Implement TCP Echo Service : https://www.rfc-editor.org/rfc/rfc862.htl
