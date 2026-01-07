
[https://benediktschlager.github.io/zigwasm/](https://benediktschlager.github.io/zigwasm/)

Requires at least zig 0.16.0-dev.1634+b27bdd5af.  

```bash
# Run natively
zig build run

# Run using emscripten 
zig build run -Dtarget=wasm32-emscripten
```
