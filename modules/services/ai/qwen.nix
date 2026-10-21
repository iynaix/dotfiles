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
    # https://augmentedmind.substack.com/p/the-16gb-threshold
    "Qwen3.8_27B_GSQ-RCO-IQ3_S" = {
      hf-repo = "ISTA-DASLab/Qwen3.8-27B-GSQ-RCO-GGUF";
      hf-file = "Qwen3.8-27B-GSQ-RCO-IQ3_S-mtp.gguf";
      alias = "Qwen3.8_27B_GSQ-RCO-IQ3_S";

      ctx-size = 65536;
      n-gpu-layers = 99;
      spec-type = "draft-mtp";
      spec-draft-n-max = 2;
      cache-type-k = "q4_0";
      cache-type-v = "q4_0";
      flash-attn = "on";
      jinja = true;
      temp = "1.0";
      top-p = "0.95";
      top-k = "20";
      min-p = "0.00";
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
