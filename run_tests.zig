const std = @import("std");

const TestCaseExpectation = struct { file_path: []const u8, expected_exit_code: u8, in_stderr: ?[]const u8 = null };
const test_cases = [_]TestCaseExpectation{.{ .file_path = "src/interface.1.test.zig", .expected_exit_code = 1, .in_stderr = "The return params for `some` do not match. Expected `void`. Found `u32`." }};

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    for (test_cases) |test_case| {
        var cmd = std.process.Child.init(&.{ "zig", "test", test_case.file_path }, allocator);
        cmd.stderr_behavior = .Pipe;

        try cmd.spawn();
        const status = try cmd.wait();

        var success = (status == .Exited) and (status.Exited == test_case.expected_exit_code);

        if (test_case.in_stderr) |in_stderr| {
            const stderr = try cmd.stderr.?.reader().readAllAlloc(allocator, 10000);
            defer allocator.free(stderr);
            success = success and std.mem.containsAtLeast(u8, stderr, 1, in_stderr);
        }

        try std.testing.expect(success);
    }
}
