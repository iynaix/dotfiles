{
  config =
    {
      config,
      lib,
      ...
    }:
    {
      options = {
        custom.ai = {
          modelsDir = lib.mkOption {
            type = lib.types.path;
            description = "Models directory.";
            default = "/var/lib/llama-models";
          };

          modelsPreset = lib.mkOption {
            type = lib.types.nullOr (lib.types.attrsOf lib.types.attrs);
            default = null;
            description = ''
              Models preset configuration as a Nix attribute set.
              This is converted to an INI file and passed to llama-server via --model-preset.
              See llama-server documentation for available options.
            '';
            example = lib.literalExpression ''
              {
                "Qwen3-Coder-Next" = {
                  hf-repo = "unsloth/Qwen3-Coder-Next-GGUF";
                  hf-file = "Qwen3-Coder-Next-UD-Q4_K_XL.gguf";
                  alias = "unsloth/Qwen3-Coder-Next";
                  fit = "on";
                  seed = "3407";
                  temp = "1.0";
                  top-p = "0.95";
                  min-p = "0.01";
                  top-k = "40";
                  jinja = "on";
                };
              }
            '';
          };

          port = lib.mkOption {
            type = lib.types.port;
            default = 9070;
            description = "Port for Open WebUI";
          };

          qwen_27b.enable = lib.mkEnableOption "Local Qwen 27b model";
        };
      };

      config = {
        custom.persist = lib.mkIf config.custom.ai.qwen_27b.enable {
          root.cache.directories = [
            "var/lib/llama-models"
          ];
        };
      };
    };
}
