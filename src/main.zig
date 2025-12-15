const std = @import("std");
const zl = @import("zig_libraries");
const Rng = zl.rng.Rng;
const Vec = zl.vec.Vec;
const Str = zl.str.Str;
const print = zl.io.print;

var gpa = std.heap.GeneralPurposeAllocator(.{}) {};
const Allocator = gpa.allocator();
const AllowChars = "()0123456789.+-*/"; // validation
const Digits = "0123456789."; // calculate
const Operators = "+-*/"; // anywhere

pub fn main() !void {
    defer if (gpa.deinit() == .leak) unreachable;
    defer zl.io.cout.flush() catch unreachable;

    const Args = try std.process.argsAlloc(Allocator);
    defer std.process.argsFree(Allocator, Args);
    if (Args.len != 2) { return error.InvaildArguments; }

    var buffer = Str.init(Allocator); defer buffer.deinit();
    try buffer.appendSlice(Args[Args.len - 1]);

    try removeWhitespace(&buffer);
    try removeOverlapedFloatingPoint(&buffer);
    if (buffer.items.len == 0) { return error.InvaildArguments; }
    validation(buffer.items) catch |e| {
        std.debug.print(
            \\
            \\Linux/Mac:
            \\    ./Calculator <Formula>
            \\
            \\Windows:
            \\    ./Calculator.exe <Formula>
            \\
            \\Example:
            \\    ./Calculator "((10 * (520 +35) - 11/3.3) + 25)/5.5"
            \\    ./Calculator.exe "((10 * (520 +35) - 11/3.3) + 25)/5.5"
            \\
            \\
            , .{},
        );
        return e;
    };
    print("{d}\n", .{ try calculate(buffer.items) });
}

pub fn removeWhitespace(str: *Str) !void {
    var s = str.items;
    var l: usize = 0;
    var i = Rng(usize).init(0, s.len);
    while (i.next()) |r| {
        if (!std.ascii.isWhitespace(s[r])) {
            s[l] = s[r];
            l += 1;
        }
    }
    try str.resize(l);
}

pub fn removeOverlapedFloatingPoint(str: *Str) !void {
    var s = str.items;
    var l: usize = 0;
    var i = Rng(usize).init(0, s.len);
    var b: bool = false;
    while (i.next()) |r| {
        if (s[r] == '.') {
            if (b) { continue; }
            b = true;
        } else if (std.mem.indexOfScalar(u8, Operators, s[r]) != null) {
            b = false;
        }
        s[l] = s[r];
        l += 1;
    }
    try str.resize(l);
}

pub fn validation(formula: []const u8) !void {
    // allow character check
    for (0 .. formula.len) |i| {
        if (std.mem.indexOfScalar(u8, AllowChars, formula[i]) == null) {
            return error.NotAllowedCharacterIncluded;
        }
    }

    // bracket check (maybe performance will be decrease)
    var bracketStack: i32 = 0;
    for (0 .. formula.len) |i| {
        bracketStack += switch (formula[i]) {
            '(' => 1,
            ')' => -1,
            else => 0,
        };
        if (bracketStack < 0) { return error.NotExactlyMatchParentheses; }
    }
    if (bracketStack != 0) { return error.NotExactlyMatchParentheses; }

    // formula check
    for (1 .. formula.len) |i| {
        switch (formula[i - 1]) {
            '(' => if (formula[i] == ')' or
                    std.mem.indexOfScalar(u8, Operators, formula[i]) != null) {
                return error.AbnormalFormula;
            },
            ')' => if (formula[i] == '(' or
                    std.mem.indexOfScalar(u8, Digits, formula[i]) != null) {
                return error.AbnormalFormula;
            },
            else => if (std.mem.indexOfScalar(u8, Digits, formula[i - 1]) != null) {
                if (formula[i] == '(') {
                    return error.AbnormalFormula;
                }
            } else if (std.mem.indexOfScalar(u8, Operators, formula[i - 1]) != null) {
                if (formula[i] == ')' or
                        std.mem.indexOfScalar(u8, Operators, formula[i]) != null) {
                    return error.AbnormalFormula;
                }
            },
        }
    }
    if (formula.len == 0 or
            std.mem.indexOfScalar(u8, Operators, formula[0]) != null or
            std.mem.indexOfScalar(u8, Operators, formula[formula.len - 1]) != null) {
        return error.AbnormalFormula;
    }
}

pub fn calculate(formula: []const u8) !f64 {
    // split elements
    var operands = Vec(f64).init(Allocator); defer operands.deinit();
    var operators = Vec(u8).init(Allocator); defer operators.deinit();
    var bracketStack: i32 = 0;
    var l: usize = undefined;
    var l2: ?usize = null;
    for (0 .. formula.len) |i| {
        switch (formula[i]) {
            '(' => {
                if (bracketStack == 0) { l = i + 1; }
                bracketStack += 1;
            },
            ')' => {
                bracketStack -= 1;
                if (bracketStack == 0) {
                    try operands.push(try calculate(formula[l .. i]));
                }
            },
            else => if (bracketStack == 0) {
                if (std.mem.indexOfScalar(u8, Operators, formula[i]) != null) {
                    try operators.push(formula[i]);
                    if (l2 != null) {
                        try operands.push(try std.fmt.parseFloat(f64, formula[l2.? .. i]));
                        l2 = null;
                    }
                } else if (l2 == null) {
                    l2 = i;
                }
                if (i == formula.len - 1) {
                    if (l2 != null) {
                        try operands.push(try std.fmt.parseFloat(f64, formula[l2.? .. ]));
                        l2 = null;
                    }
                }
            },
        }
    }

    // *, /
    var i: usize = 0;
    while (i < operators.items.len) {
        switch (operators.items[i]) {
            '*' => operands.items[i] *= operands.items[i + 1],
            '/' => operands.items[i] /= operands.items[i + 1],
            else => {
                i += 1;
                continue;
            },
        }
        // low performance
        _ = try operands.remove(i + 1);
        _ = try operators.remove(i);
    }

    // +, -
    i = 0;
    while (i < operators.items.len) {
        switch (operators.items[i]) {
            '+' => operands.items[i] += operands.items[i + 1],
            '-' => operands.items[i] -= operands.items[i + 1],
            else => {
                i += 1;
                continue;
            },
        }
        // low performance
        _ = try operands.remove(i + 1);
        _ = try operators.remove(i);
    }

    return operands.back() orelse error.NothingResults;
}
