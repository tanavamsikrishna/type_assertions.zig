// This file provides a function `run_test` which is capable of running tests on the compilation process itself.
// Therefore capable of running tests on comptime code.
// Note: There is an accepted (for implementation) github issue (https://github.com/ziglang/zig/issues/513)
// which proposes the capability of running tests on the compilation process itself.
// While  it has been getting postponed, the `run_test` fn in this file implements it in its own way
//
// Usage:
//
// const test_cases = [_]TestCaseExpectation{.{
//     .file_path = "src/interface.1.test.zig",
//     .expected_exit_code = 1,
//     .in_stderr = "The return params for `some` do not match. Expected `void`. Found `u32`.",
// }};
//
// pub fn main() !void { // or test "a sample compilation test" {
//     var gpa = std.heap.GeneralPurposeAllocator(.{}){};
//     defer _ = gpa.deinit();
//     const allocator = gpa.allocator();
//
//     for (test_cases) |test_case| {
//         try run_test(allocator, test_case);
//     }
// }
//

const std = @import("std");

pub const TestCaseExpectation = struct {
    file_path: []const u8,
    expected_exit_code: u8,
    in_stderr: ?[]const u8 = null,
    in_stdout: ?[]const u8 = null,
};

pub fn run_test(allocator: std.mem.Allocator, test_case: TestCaseExpectation) !void {
    const result = try std.process.Child.run(.{ .allocator = allocator, .argv = &.{
        "zig",
        "test",
        test_case.file_path,
    } });
    defer allocator.free(result.stderr);
    defer allocator.free(result.stdout);

    var success = (result.term == .Exited) and (result.term.Exited == test_case.expected_exit_code);

    if (test_case.in_stdout) |in_stdout| {
        success = success and std.mem.containsAtLeast(u8, result.stdout, 1, in_stdout);
    }

    if (test_case.in_stderr) |in_stderr| {
        success = success and std.mem.containsAtLeast(u8, result.stderr, 1, in_stderr);
    }

    std.testing.expect(success) catch |err| {
        std.debug.print(
            \\Test case(s) in {s} failed.
            \\===stdout of the test case===
            \\{s}===stderr of the test case===
            \\{s}===end===
            \\
        , .{
            test_case.file_path,
            result.stdout,
            result.stderr,
        });
        return err;
    };
}
