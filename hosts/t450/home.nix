_: {
  custom = {
    monitors = [
      {
        name = "eDP-1";
        width = 1600;
        height = 900;
        workspaces = [
          1
          2
          3
          4
          5
          6
          7
          8
          9
          10
        ];
      }
    ];

    deadbeef.enable = true;
    rclip.enable = true;
    terminal.size = 12;

    persist = {
      home.directories = [
        "Downloads"
        "Music"
      ];
    };
  };
}
