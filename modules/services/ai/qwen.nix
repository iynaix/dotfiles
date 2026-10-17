{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.custom.ai;
in
lib.mkIf cfg.qwen_27b.enable {
  custom.ai.modelsPreset = {
    # https://huggingface.co/ukisai/Swift-1.5-Qwen3.8-27B-GSQ-RCO-GGUF
    # https://www.reddit.com/r/LocalLLM/comments/1x14c5u/success_with_qwen38_27b_gsqrcoiq3_s_on_16gb_vram/
    "Qwen3.8_27B_GSQ-RCO-IQ3_S" = {
      hf-repo = "ukisai/Swift-1.5-Qwen3.8-27B-GSQ-RCO-GGUF";
      hf-file = "Swift-1.5-Qwen3.8-27B-GSQ-RCO-IQ3_S-mtp.gguf";
      alias = "Qwen3.8_27B_GSQ-RCO-IQ3_S";

      ctx-size = 131072;
      n-gpu-layers = "all";
      reasoning-effort = "medium";
      reasoning-format = "deepseek";
      reasoning-preserve = true;
      cache-type-k = "q4_0";
      cache-type-v = "q4_0";
      jinja = true;
      batch-size = 512;
      ubatch-size = 512;
      flash-attn = "on";
      threads = 6;
      threads-batch = 6;
      parallel = 1;
      no-mmproj = true;
    };
  };

  services.llama-cpp = {
    enable = true;
    package = pkgs.llama-cpp-rocm;

    settings = {
      host = "127.0.0.1";
      inherit (cfg) port;

      sleep-idle-seconds = 600;

      models-dir = cfg.modelsDir;
      models-preset = pkgs.writeText "llama-models.ini" (lib.generators.toINI { } cfg.modelsPreset);
    };
  };
}
