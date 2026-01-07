const std = @import("std");
const rlz = @import("raylib_zig");

// Although this function looks imperative, it does not perform the build
// directly and instead it mutates the build graph (`b`) that will be then
// executed by an external runner. The functions in `std.Build` implement a DSL
// for defining build steps and express dependencies between them, allowing the
// build runner to parallelize the build automatically (and the cache system to
// know when a step doesn't need to be re-run).
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const raylib_dep = b.dependency("raylib_zig", .{ .target = target, .optimize = optimize });
    const raylib = raylib_dep.module("raylib");

    const mod = b.addModule("zigwasm", .{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .imports = &.{
            .{ .name = "raylib", .module = raylib },
        },
    });
    mod.link_libc = false;

    const run_step = b.step("run", "Run the app");

    if (target.query.os_tag == .emscripten) {
        const emsdk = rlz.emsdk;
        const wasm = b.addLibrary(.{
            .name = "zigwasm",
            .root_module = mod,
        });
        wasm.entry = .disabled;
        wasm.rdynamic = true;

        const install_dir: std.Build.InstallDir = .{ .custom = "web" };
        const emcc_flags = emsdk.emccDefaultFlags(b.allocator, .{ .optimize = optimize, .asyncify = true });
        var emcc_settings = emsdk.emccDefaultSettings(b.allocator, .{ .optimize = optimize });
        // TODO Full screen is not yet working
        _ = emcc_settings.remove("EXPORTED_RUNTIME_METHODS");
        emcc_settings.put("ERROR_ON_UNDEFINED_SYMBOLS", "0") catch @panic("what");
        const raylib_artifact = raylib_dep.artifact("raylib");
        const emcc_step = emsdk.emccStep(b, raylib_artifact, wasm, .{
            .optimize = optimize,
            .flags = emcc_flags,
            .settings = emcc_settings,
            .install_dir = install_dir,
        });
        b.getInstallStep().dependOn(emcc_step);

        const html_filename = std.fmt.allocPrint(b.allocator, "{s}.html", .{wasm.name}) catch @panic("oh no");
        const emrun_step = emsdk.emrunStep(
            b,
            b.getInstallPath(install_dir, html_filename),
            &.{},
        );

        emrun_step.dependOn(emcc_step);
        run_step.dependOn(emrun_step);

        return;
    } else {
        const exe = b.addExecutable(
            .{
                .name = "zigwasm",
                .root_module = mod,
            },
        );
        const run_cmd = b.addRunArtifact(exe);
        run_step.dependOn(&run_cmd.step);

        run_cmd.step.dependOn(b.getInstallStep());
    }
}
