const std = @import("std");

var gpa = std.heap.GeneralPurposeAllocator(.{}) {}; 
const allocator = gpa.allocator();
const allowChars = "()0123456789.+-*/"; // validation
const digits = "0123456789."; // calculate
const operators = "+-*/"; // anywhere

pub fn main() !void {
  defer _ = gpa.deinit();
  const reader = std.io.getStdIn().reader();
  const writer = std.io.getStdOut().writer();
  var buffer: [1 << 16]u8 = undefined;
  var len: usize = try reader.readAll(&buffer);

  len = removeWhitespace(buffer[0 .. len]);
  len = removeOverlapedFloatingPoint(buffer[0 .. len]);
  validation(buffer[0 .. len]) catch |e| {
    try writer.print(
      \\
      \\usage:
      \\    ./Calculator < formula.txt
      \\
      \\or Linux/Mac:
      \\    ./Calculator
      \\    <Formula>
      \\    <ctrl+D>
      \\
      \\or Windows:
      \\    ./Calculator.exe
      \\    <Formula><ctrl+Z><Ent>
      \\
      \\
      , .{},
    );
    return e;
  };
  try writer.print("{d}\n", .{ try calculate(buffer[0 .. len]) });
}

pub fn removeWhitespace(str: []u8) usize {
  var l: usize = 0;
  var r: usize = 0;
  while (r < str.len) : (r += 1) {
    if (!std.ascii.isWhitespace(str[r])) {
      str[l] = str[r];
      l += 1;
    }
  }
  return l;
}

pub fn removeOverlapedFloatingPoint(str: []u8) usize {
  var b: bool = false;
  var l: usize = 0;
  var r: usize = 0;
  while (r < str.len) : (r += 1) {
    if (str[r] == '.') {
      if (b) { continue; }
      b = true;
    } else if (std.mem.indexOfScalar(u8, operators, str[r]) != null) {
      b = false;
    }
    str[l] = str[r];
    l += 1;
  }
  return l;
}

pub fn validation(formula: []const u8) !void {
  // allow character check
  for (0 .. formula.len) |i| {
    if (std.mem.indexOfScalar(u8, allowChars, formula[i]) == null) {
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
          std.mem.indexOfScalar(u8, operators, formula[i]) != null) {
        return error.AbnormalFormula;
      },
      ')' => if (formula[i] == '(' or
          std.mem.indexOfScalar(u8, digits, formula[i]) != null) {
        return error.AbnormalFormula;
      },
      else => if (std.mem.indexOfScalar(u8, digits, formula[i - 1]) != null) {
        if (formula[i] == '(') { return error.AbnormalFormula; }
      } else if (std.mem.indexOfScalar(u8, operators, formula[i - 1]) != null) {
        if (formula[i] == ')' or
            std.mem.indexOfScalar(u8, operators, formula[i]) != null) {
          return error.AbnormalFormula;
        }
      },
    }
  }
  if (formula.len == 0 or
      std.mem.indexOfScalar(u8, operators, formula[0]) != null or
      std.mem.indexOfScalar(u8, operators, formula[formula.len - 1]) != null) {
    return error.AbnormalFormula;
  }
}

pub fn calculate(formula: []const u8) !f64 {
  // split elements
  var operands = std.ArrayList(f64).init(allocator); defer operands.deinit();
  var operators_ = std.ArrayList(u8).init(allocator); defer operators_.deinit();
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
          try operands.append(try calculate(formula[l .. i]));
        }
      },
      else => if (bracketStack == 0) {
        if (std.mem.indexOfScalar(u8, operators, formula[i]) != null) {
          try operators_.append(formula[i]);
          if (l2 != null) {
            try operands.append(try std.fmt.parseFloat(f64, formula[l2.? .. i]));
            l2 = null;
          }
        } else if (l2 == null) {
          l2 = i;
        }
        if (i == formula.len - 1) {
          if (l2 != null) {
            try operands.append(try std.fmt.parseFloat(f64, formula[l2.? .. ]));
            l2 = null;
          }
        }
      },
    }
  }

  // *, /
  var i: usize = 0;
  while (i < operators_.items.len) {
    switch (operators_.items[i]) {
      '*' => operands.items[i] *= operands.items[i + 1],
      '/' => operands.items[i] /= operands.items[i + 1],
      else => {
        i += 1;
        continue;
      },
    }
    _ = operands.orderedRemove(i + 1);
    _ = operators_.orderedRemove(i);
  }
  // +, -
  i = 0;
  while (i < operators_.items.len) {
    switch (operators_.items[i]) {
      '+' => operands.items[i] += operands.items[i + 1],
      '-' => operands.items[i] -= operands.items[i + 1],
      else => {
        i += 1;
        continue;
      },
    }
    _ = operands.orderedRemove(i + 1);
    _ = operators_.orderedRemove(i);
  }
  return operands.items[0];
}
