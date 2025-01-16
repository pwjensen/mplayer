const std = @import("std");
const c = @cImport({
    @cInclude("mpd/client.h");
});

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

        // Plays next song in playlist
        if (c.mpd_run_add(conn, "/home/paul/Music/song.opus")) {
            if (c.mpd_run_stop(conn)) {
                return;
            } else {
                const err_msg = c.mpd_connection_get_error_message(conn);
                std.debug.print("Play error: {s}\n", .{err_msg});
                return error.PlayError;
            }
        } else {
            const err_msg = c.mpd_connection_get_error_message(conn);
            std.debug.print("Add error: {s}\n", .{err_msg});
            return error.PlayError;
        }
    }
}
