{
  description = "应用类 flake 集合（omp / goose / kache / ...）— 与主配置的基础设施 input 解耦";

  inputs = {
    # 语音输入法
    fcitx5-vinput = {
      url = "github:xifan2333/fcitx5-vinput";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Kache, Rust/C++ 编译缓存加速
    kache = {
      url = "github:kunobi-ninja/kache/stable";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # oh-my-pi, AI Coding agent
    omp = {
      url = "github:can1357/oh-my-pi";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # RustConn, connection manager
    rustconn = {
      url = "github:totoshko88/RustConn";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Ferrite, text editor for Markdown
    ferrite = {
      url = "github:OlaProeis/Ferrite";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # simple-ocr, GPUI/Rust OCR app
    simple-ocr = {
      url = "github:sgnay/simple-ocr";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Goosse AI agent
    goose = {
      url = "github:aaif-goose/goose/v1.55.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # simple translation
    simple-translation = {
      url = "github:sgnay/simple-translation";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # AI-native workspace for local shells oxideterm
    oxideterm = {
      url = "github:AnalyseDeCircuit/oxideterm/v2.2.2";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # nyaterm A modern remote terminal workspace
    nyaterm = {
      url = "github:sgnay/nix-nyaterm/v1.3.2";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # 由主 flake 通过 inputs.apps.inputs.nixpkgs.follows 指到主 nixpkgs
    nixpkgs.url = "nixpkgs/nixos-26.05";
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    ...
  }: let
    # 除 self/nixpkgs 外，所有 input 均为应用类 flake
    appFlakes = builtins.removeAttrs inputs [
      "self"
      "nixpkgs"
    ];
  in {
    # 主 flake 通过该 overlay 注入应用包
    overlays.default = _final: prev: let
      targetSystem = prev.stdenv.hostPlatform.system;
      getDefault = flake: flake.packages.${targetSystem}.default;
      plain = builtins.mapAttrs (_: getDefault) appFlakes;
    in
      plain
      // {
        omp = (getDefault appFlakes.omp).overrideAttrs (_o: {
          __noSandbox = true;
        });
        # unit_prune 的 atime 探针测试依赖 Linux relatime 行为，在 Nix 沙箱内不成立
        kache = (getDefault appFlakes.kache).overrideAttrs (o: {
          checkFlags =
            o.checkFlags
            ++ [
              "--skip=unit_prune::tests::probes_whether_reads_move_an_armed_access_time"
            ];
        });
        goose = (getDefault appFlakes.goose).overrideAttrs (_o: {
          doCheck = false;
          cargoDeps = prev.rustPlatform.importCargoLock {
            lockFile = "${appFlakes.goose}/Cargo.lock";
            # v1.55.0 起 agent-client-protocol 改为 crates.io 源，git 依赖只剩 cudaforge
            outputHashes = {
              "cudaforge-0.1.6" = "sha256-w0e/mfx08BkphDEFEWxuyxyZu/gHiG0m6RHx+3BLzDY=";
            };
          };
        });
      };

    # 透传全部应用 flake，主 flake 直接合并回 inputs，模块引用无需改动
    inherit appFlakes;
  };
}
