const rl = @import("raylib");
const builtin = @import("builtin");

pub extern fn emscripten_run_script(script: [*:0]const u8) void;
pub const target = builtin.target;

const std = @import("std");

pub fn main() void {
    var chaCha = std.Random.ChaCha.init("notsecrenotsecrenotsecrenotsecre".*);
    const rng = chaCha.random();
    if (target.os.tag == .emscripten) {
        emscripten_run_script("console.log('Hello from Zig WASM via JS!');");
    }
    std.log.info("Hello!", .{});
    rl.initWindow(800, 600, "raylib zig wasm");
    rl.setTargetFPS(60);

    var i: i32 = 0;
    var n: u6 = 30;
    var pos: i32 = 50;

    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        defer rl.endDrawing();
        rl.clearBackground(rl.Color.brown);
        rl.drawText("Hello!", 20, 20, 64, rl.Color.green);

        rl.drawText("Success", 20 + i, 160, 64, rl.Color.dark_green);
        rl.drawText("Success", i - 750, 160, 64, rl.Color.dark_green);
        i += 2;
        if (i > 700) {
            i = 0;
        }

        rl.drawCircle(pos, 400, 30, rl.Color.blue);
        if (n == 1) {
            pos = rng.intRangeAtMost(i32, 40, 760);
            n = 20;
        } else {
            n -= 1;
        }
    }
}

// Keep this or emscripten won't compile
export fn pthread_kill(_: usize, _: i32) i32 {
    // do nothing, single-threaded environment
    return 0;
}
