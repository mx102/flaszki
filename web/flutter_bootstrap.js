{{flutter_js}}
{{flutter_build_config}}

// PRD §8 / ADR 0002: use wasm on Firefox and Safari too when supported;
// otherwise Flutter falls back to the bundled dart2js build.
_flutter.loader.load({
  config: {
    wasmAllowList: { gecko: true, webkit: true },
  },
});
