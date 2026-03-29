const std = @import("std");
const pynote = @import("pynote");

const UIError = error{ UserCancelled, MissingUILibrary };

pub fn main() !void {
    // Prints to stderr, ignoring potential errors.
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    // const allocator = gpa.allocator();

    var dialog_buffer: [4096]u8 = undefined;
    const dialog_len = readDialog(&dialog_buffer) catch |err| {
        std.log.err("Dialog error: {}", .{err});
        return;
    };

    if (dialog_len == 0) {
        std.log.info("User cancelled.", .{});
        return;
    }

    var sanitizedBuffer: [4096]u8 = undefined;
    const sanitized_len = sanitizeFilename(dialog_buffer[0..dialog_len], &sanitizedBuffer);

    const text = sanitizedBuffer[0..sanitized_len];

    try sendCommand(text);

    // write to stdout for whatever reason
    try std.fs.File.stdout().writeAll(text);
}

fn readPipe(file: ?std.fs.File, allocator: std.mem.Allocator, label: []const u8) !void {
    const f = file orelse return;
    var buffer = try allocator.alloc(u8, 4096);
    defer allocator.free(buffer);

    const bytes_read = try f.read(buffer);
    if (bytes_read > 0) {
        var fmt_buffer: [2048]u8 = undefined;
        const formatted_slice = try std.fmt.bufPrint(&fmt_buffer, "[{s}]: \n{s}\n", .{ label, buffer[0..bytes_read] });
        std.log.info("{s}", .{formatted_slice});
    } else {
        std.log.info("No {s} output captured.\n", .{label});
    }
}

fn sanitizeFilename(input: []const u8, output: []u8) usize {
    const unsafe_chars = [_]u8{ '/', '\\', ':', '*', '?', '"', '<', '>', '|' };
    var out_idx: usize = 0;

    for (input) |char| {
        var is_unsafe = false;
        for (unsafe_chars) |unsafe| {
            if (char == unsafe) {
                is_unsafe = true;
                break;
            }
        }

        if (is_unsafe) {
            output[out_idx] = '_';
        } else {
            output[out_idx] = char;
        }
        out_idx += 1;

        // Safety check: if output buffer is full, stop (shouldn't happen if sized correctly)
        if (out_idx >= output.len) break;
    }

    return out_idx;
}
fn readDialog(buffer: []u8) !usize {
    const args = [_][]const u8{ "kdialog", "--inputbox", "Fleeting note:", "", "--geometry", "500x300" };
    var dialog_proc = std.process.Child.init(&args, std.heap.page_allocator);

    dialog_proc.stdout_behavior = .Pipe;
    try dialog_proc.spawn();

    const f = dialog_proc.stdout orelse {
        return UIError.MissingUILibrary;
    };

    const bytes_read = try f.read(buffer);
    if (bytes_read == 0) return 0;

    // Manually trim trailing \n and \r
    var len = bytes_read;
    while (len > 0) {
        const char = buffer[len - 1];
        if (char == '\n' or char == '\r') {
            len -= 1;
        } else {
            break;
        }
    }

    return len;
}

fn sendCommand(text: []const u8) !void {
    const allocator = std.heap.page_allocator;

    var args = std.ArrayList([]const u8){};
    defer args.deinit(allocator);

    try args.append(allocator, "obsidian");
    try args.append(allocator, "quickadd:run");
    try args.append(allocator, "choice=Fleeting");

    const formatted_value = try std.fmt.allocPrint(allocator, "value-value={s}", .{text});
    defer allocator.free(formatted_value);

    try args.append(allocator, formatted_value);

    var child = std.process.Child.init(args.items, allocator);

    child.stdout_behavior = .Pipe;
    child.stderr_behavior = .Pipe;

    try child.spawn();

    // try readPipe(child.stderr, allocator, "STDERR");
    // try readPipe(child.stdout, allocator, "STDOUT");

    const result = try child.wait();

    switch (result) {
        .Exited => |code| {
            if (code == 0) {
                std.log.info("Succes! Note Added.", .{});
            } else {
                std.log.err("Failed with exit code: {}.", .{result.Exited});
            }
        },
        .Signal => |signal| {
            std.log.err("Process was killed by singal: {}", .{signal});
        },
        .Stopped => |signal| {
            std.log.err("Process was stopped by singal: {}", .{signal});
        },
        .Unknown => |_| {
            std.log.err("Unknown error", .{});
        },
    }
}
