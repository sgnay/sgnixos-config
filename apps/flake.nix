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
    # Goosse AI agent
    goose = {
      url = "github:aaif-goose/goose/v1.49.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # simple translation
    simple-translation = {
      url = "github:sgnay/simple-translation";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # nyaterm A modern remote terminal workspace
    # nyaterm = {
    #   url = "github:sgnay/nyaterm/migration/gpui";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    # 由主 flake 通过 inputs.apps.inputs.nixpkgs.follows 指到主 nixpkgs
    nixpkgs.url = "nixpkgs/nixos-26.05";
  };

  outputs = {
    fcitx5-vinput,
    kache,
    omp,
    rustconn,
    ferrite,
    goose,
    simple-translation,
    ...
  }: {
    # 主 flake 通过该 overlay 注入应用包
    overlays.default = _final: prev: let
      targetSystem = prev.stdenv.hostPlatform.system;
      getDefault = flake: flake.packages.${targetSystem}.default;
    in {
      fcitx5-vinput = getDefault fcitx5-vinput;
      omp = (getDefault omp).overrideAttrs (_oldAttrs: {
        __noSandbox = true;
      });
      rustconn = getDefault rustconn;
      ferrite = getDefault ferrite;
      goose = (getDefault goose).overrideAttrs (_oldAttrs: {
        doCheck = false;
        cargoDeps = prev.rustPlatform.importCargoLock {
          lockFile = "${goose}/Cargo.lock";
          outputHashes = {
            "cudaforge-0.1.6" = "sha256-w0e/mfx08BkphDEFEWxuyxyZu/gHiG0m6RHx+3BLzDY=";
            "agent-client-protocol-2.0.0" = "sha256-62Bc5XLIx38npCkmijutjJOxjfESg3+m/Ih409ELXNQ=";
          };
        };
      });
      kache = getDefault kache;
      simple-translation = getDefault simple-translation;
    };

    # 透传子 flake：主 flake 合并回 inputs 后，
    # 模块中 inputs.omp / inputs.kache / inputs.ferrite 等引用无需改动
    inherit
      fcitx5-vinput
      kache
      omp
      rustconn
      ferrite
      goose
      simple-translation
      ;
  };
}
