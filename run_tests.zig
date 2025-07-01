const std = @import("std");
const type_assertions = @import("src/root.zig");

const TestCaseExpectation = type_assertions.compile_assertions.TestCaseExpectation;
const run_test = type_assertions.compile_assertions.run_test;

const test_cases = [_]TestCaseExpectation{.{
    .file_path = "src/interface.1.test.zig",
    .expected_exit_code = 1,
    .in_stderr = "The return params for `some` do not match. Expected `void`. Found `u32`.",
}};

pub fn main() !void {
    var gpa = std.heap.DebugAllocator(.{}).init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    for (test_cases) |test_case| {
        try run_test(allocator, test_case);
    }
}
