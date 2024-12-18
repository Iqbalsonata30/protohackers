const std = @import("std");
const posix = std.posix;
const net = std.net;
const testing = std.testing;
const json = std.json;
const Allocator = std.mem.Allocator;

pub fn main() !void {
    const sock_addr = net.Ip4Address.init([4]u8{ 0, 0, 0, 0 }, 1234);

    const sock_addr_len = @sizeOf(posix.sockaddr.in);
    const sock_fd = posix.socket(posix.AF.INET, posix.SOCK.STREAM, 0) catch |err| {
        std.debug.print("failed to create socket : {?}\n", .{err});
        return;
    };
    defer posix.close(sock_fd);

    try posix.setsockopt(sock_fd, posix.SOCK.STREAM, posix.SO.REUSEADDR, &std.mem.toBytes(@as(c_int, 1)));

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
    var conn = try posix.accept(sock_fd, @ptrCast(&peer_socket), &peer_socket_len, 0);

    while (conn > 0) : (conn = try posix.accept(sock_fd, @ptrCast(&peer_socket), &peer_socket_len, 0)) {
        std.debug.print("address:{any} is connecting\n", .{peer_socket});

        var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
        defer arena.deinit();
        const allocator = arena.allocator();

        var thread = try std.Thread.spawn(.{}, worker, .{ conn, allocator });
        defer thread.join();
    }
}

fn worker(conn: posix.socket_t, allocator: Allocator) !void {
    var buffer: [1024 * 1024]u8 = undefined;
    const buf_size: usize = 1024 * 1024;

    const message_malformed = "your request is malformed\n";
    var data_received = try readRequest(conn, &buffer, buf_size);

    while (data_received > 0) : (data_received = try readRequest(conn, &buffer, buf_size)) {
        std.debug.print("data received: {d}\n", .{data_received});
        const message = buffer[0..data_received];
        const parsed = json.parseFromSliceLeaky(json.Value, allocator, message, .{}) catch |e| {
            _ = try posix.send(conn, message_malformed, 0);
            std.debug.print("malformed request : {s}", .{message});
            std.debug.print("error parsed json : {?}\n", .{e});
            continue;
        };

        const method = parsed.object.get("method").?.string;
        if (!std.mem.eql(u8, method, "isPrime")) {
            _ = try posix.send(conn, message_malformed, 0);
            continue;
        }
        if (parsed.object.get("number")) |v| {
            if (v != .integer) {
                _ = try posix.send(conn, message_malformed, 0);
                continue;
            } else {
                const is_prime = isPrime(v.integer);
                const json_response = Response{
                    .method = method,
                    .prime = is_prime,
                };
                const parsed_json = try json.stringifyAlloc(allocator, json_response, .{});
                const response = try std.fmt.allocPrint(allocator, "{s}\n", .{parsed_json});
                const sent_message = try posix.send(conn, response, 0);
                std.debug.print("received message:{s}", .{message});
                std.debug.print("sent message: {s}\n", .{response[0..sent_message]});
            }
        }
        std.mem.copyBackwards(u8, &buffer, buffer[data_received..]);
    }
    if (data_received < 0) {
        std.debug.print("failed read message\n", .{});
        return;
    } else if (data_received == 0) {
        std.debug.print("client disconnect\n", .{});
        return;
    }

    defer posix.close(conn);
}

fn readRequest(conn: posix.socket_t, buf: []u8, bufsize: usize) !usize {
    if (bufsize == 0) {
        return error.BufferCapacityIsNotEnough;
    }

    var bytes_read: usize = 0;
    var char: [1]u8 = undefined;
    while (bytes_read < bufsize - 1) {
        const res = try std.posix.recv(conn, &char, 0);
        if (res == 0) {
            break;
        }

        const c = char[0];
        buf[bytes_read] = c;
        bytes_read += 1;
        if (c == '\n') {
            break;
        }
    }
    return bytes_read;
}

const Response = struct {
    method: []const u8,
    prime: bool,
};

fn isPrime(num: i64) bool {
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
        .{
            .input = 9,
            .output = false,
        },
    };

    for (test_cases) |tc| {
        const res = isPrime(tc.input);
        try testing.expect(res == tc.output);
    }
}
