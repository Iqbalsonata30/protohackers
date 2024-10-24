// Prime Time
//
//  Accept TCP Connection
//  Whenever receive a conforming request, send back a correct response and wait for another request
//  Whenever you receive a malformed request, send back a single malformed response, and disconnect the client.
//  Handle at least 5 Connection
//
//  The client have to send json
//  {"method":string, "prime":number}
//  method only contain isPrime and prime field must contain a valid number.
//
//  the server should response  like this
//  Example Response
//  {"method":"isPrime","prime":bool}
//

const std = @import("std");
const posix = std.posix;
const net = std.net;
const testing = std.testing;

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

/// the number is prime if the value can be divided by 1 or itself
fn isPrime(num: i32) bool {
    if (num <= 1) {
        return false;
    }
    var i: i32 = 2;
    while (i * i <= num) : (i += 1) {
        if (@mod(num, i) == 0) return false;
    }
    return true;
}

test isPrime {
    const TestCase = struct {
        input: i32,
        output: bool,
    };

    const test_cases = [_]TestCase{
        .{
            .input = 123,
            .output = false,
        },
        .{
            .input = 2,
            .output = true,
        },
    };

    for (test_cases) |tc| {
        const res = isPrime(tc.input);
        try testing.expect(res == tc.output);
    }
}
