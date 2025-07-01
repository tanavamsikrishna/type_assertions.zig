const std = @import("std");

const TestCaseExpectation = struct {
    file_path: []const u8,
    expected_exit_code: u8,
    in_stderr: ?[]const u8 = null,
};
const test_cases = [_]TestCaseExpectation{.{
    .file_path = "src/interface.1.test.zig",
    .expected_exit_code = 1,
    .in_stderr = "The return params for `some` do not match. Expected `void`. Found `u32`.",
}};

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    for (test_cases) |test_case| {
        const result = try std.process.Child.run(.{ .allocator = allocator, .argv = &.{ "zig", "test", test_case.file_path } });

        var success = (result.term == .Exited) and (result.term.Exited == test_case.expected_exit_code);

        if (test_case.in_stderr) |in_stderr| {
            success = success and std.mem.containsAtLeast(u8, result.stderr, 1, in_stderr);
        }

        std.testing.expect(success) catch |err| {
            std.debug.print("Test case(s) in {s} failed.\n=======\n{s}\n======\n", .{
                test_case.file_path,
                result.stderr,
            });
            return err;
        };
    }
}
