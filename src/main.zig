const std = @import("std");
const c = @cImport({
    @cInclude("mpd/client.h");
});
const clap = @import("clap");
const testing = std.testing;
const testing_alloc = testing.allocator;
const Arr = std.ArrayList;
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const alloc = gpa.allocator();

pub fn main() !void {

    // Create new connection
    const connection = c.mpd_connection_new("/home/paul/.local/share/mpd/socket", 0, 0);
    if (connection) |conn| {
        defer c.mpd_connection_free(conn);

        // Check for connection errors
        if (c.mpd_connection_get_error(conn) != c.MPD_ERROR_SUCCESS) {
            const err_msg = c.mpd_connection_get_error_message(conn);
            std.debug.print("Connection error: {s}\n", .{err_msg});
            return error.ConnectionError;
        }
        // Create predefined playlist
        var playlist = Arr([]const u8).init(alloc);
        try playlist.append("/home/paul/Music/song1.opus");
        try playlist.append("home/paul/Music/song2.opus");
    }

    // Params for CLI
    const params = comptime clap.parseParamsComptime(
        \\-h, --help                Display this help and exit.
        \\-o, --option <OPTION>   An option parameter, which takes a value.
        \\-s, --song <STR>          Takes a directory to the song.
        \\
    );

    const Option = enum { play, pause, stop };
    const parsers = comptime .{
        .OPTION = clap.parsers.enumeration(Option),
        .STR = clap.parsers.string,
    };

    var diag = clap.Diagnostic{};
    var res = clap.parse(clap.Help, &params, parsers, .{
        .diagnostic = &diag,
        .allocator = alloc,
    }) catch |err| {
        diag.report(std.io.getStdErr().writer(), err) catch {};
    };
    defer res.deinit();

    if (res.args.help != 0)
        std.debug.print("--help\n", .{});
    if (res.args.command) |o|
        std.debug.print("--option = {s}\n", .{@tagName(o)});
    if (res.args.song) |s|
        std.debug.print("--song = {s}\n", .{s});
    for (res.positionals[0]) |pos|
        std.debug.print("{s}\n", .{pos});
}

// pub fn get_song_id(conn: c.struct_mpd_connection, id: c_uint) !void {
//     if (c.mpd_status_get_song_id(conn, id)) {
//         return;
//     } else {
//         const err_msg = c.mpd_connection_get_error_message(conn);
//         std.debug.print("Play error: {s}\n", .{err_msg});
//         return error.PlayError;
//     }
// }

pub fn play_song(conn: c.struct_mpd_connection, uri: [*c]const u8) !void {
    // Add song to playlist
    if (c.mpd_run_add(conn, uri)) {
        // Play song
        if (c.mpd_run_play(conn)) {
            return;
        } else {
            const err_msg = c.mpd_connection_get_error_message(conn);
            std.debug.print("Play error: {s}\n", .{err_msg});
            return error.PlayError;
        }
    } else {
        const err_msg = c.mpd_connection_get_error_message(conn);
        std.debug.print("Add error: {s}\n", .{err_msg});
        return error.AddError;
    }
}

pub fn stop_song(conn: c.struct_mpd_connection) !void {
    if (c.mpd_run_stop(conn)) {
        return;
    } else {
        const err_msg = c.mpd_connection_get_error_message(conn);
        std.debug.print("Stop error: {s}\n", .{err_msg});
        return error.StopError;
    }
}

pub fn pause_song(conn: c.struct_mpd_connection) !void {
    if (c.mpd_run_pause(conn)) {
        return;
    } else {
        const err_msg = c.mpd_connection_get_error_message(conn);
        std.debug.print("Pause error: {s}\n", .{err_msg});
        return error.PauseError;
    }
}

// Add Seek
