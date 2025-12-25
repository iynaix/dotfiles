{
  appLauncher = {
    customLaunchPrefix = "";
    customLaunchPrefixEnabled = false;
    enableClipPreview = true;
    enableClipboardHistory = true;
    iconMode = "tabler";
    pinnedExecs = [

    ];
    position = "center";
    showCategories = false;
    sortByMostUsed = true;
    terminalCommand = "xterm -e";
    useApp2Unit = false;
    viewMode = "list";
  };
  audio = {
    cavaFrameRate = 30;
    externalMixer = "pwvucontrol || pavucontrol";
    mprisBlacklist = [

    ];
    preferredPlayer = "";
    visualizerType = "linear";
    volumeOverdrive = false;
    volumeStep = 1;
  };
  bar = {
    capsuleOpacity = 1;
    density = "default";
    exclusive = true;
    floating = false;
    marginHorizontal = 0.25;
    marginVertical = 0.25;
    monitors = [

    ];
    outerCorners = false;
    position = "top";
    showCapsule = false;
    showOutline = false;
    transparent = true;
    widgets = {
      center = [
        {
          characterCount = 2;
          colorizeIcons = false;
          enableScrollWheel = true;
          followFocusedScreen = false;
          hideUnoccupied = false;
          id = "Workspace";
          labelMode = "name";
          showApplications = false;
          showLabelsOnlyWhenOccupied = true;
        }
      ];
      left = [
        {
          colorizeDistroLogo = false;
          colorizeSystemIcon = "primary";
          customIconPath = "";
          enableColorization = true;
          icon = "noctalia";
          id = "ControlCenter";
          useDistroLogo = true;
        }
        {
          hideMode = "hidden";
          hideWhenIdle = false;
          id = "MediaMini";
          maxWidth = 145;
          scrollingMode = "hover";
          showAlbumArt = false;
          showArtistFirst = true;
          showProgressRing = true;
          showVisualizer = false;
          useFixedWidth = false;
          visualizerType = "linear";
        }
      ];
      right = [
        {
          displayMode = "alwaysShow";
          id = "Volume";
        }
        {
          customFont = "";
          formatHorizontal = "HH:mm ddd, MMM dd";
          formatVertical = "HH mm - dd MM";
          id = "Clock";
          useCustomFont = false;
          usePrimaryColor = true;
        }
      ];
    };
  };
  brightness = {
    brightnessStep = 1;
    enableDdcSupport = false;
    enforceMinimum = true;
  };
  calendar = {
    cards = [
      {
        enabled = true;
        id = "calendar-header-card";
      }
      {
        enabled = true;
        id = "calendar-month-card";
      }
      {
        enabled = true;
        id = "timer-card";
      }
      {
        enabled = true;
        id = "weather-card";
      }
    ];
  };
  colorSchemes = {
    darkMode = true;
    generateTemplatesForPredefined = true;
    manualSunrise = "06:30";
    manualSunset = "18:30";
    matugenSchemeType = "scheme-content";
    predefinedScheme = "Noctalia (default)";
    schedulingMode = "off";
    useWallpaperColors = true;
  };
  controlCenter = {
    cards = [
      {
        enabled = true;
        id = "profile-card";
      }
      {
        enabled = true;
        id = "shortcuts-card";
      }
      {
        enabled = true;
        id = "audio-card";
      }
      {
        enabled = false;
        id = "brightness-card";
      }
      {
        enabled = false;
        id = "weather-card";
      }
      {
        enabled = true;
        id = "media-sysmon-card";
      }
    ];
    position = "close_to_bar_button";
    shortcuts = {
      left = [
        {
          id = "WiFi";
        }
        {
          id = "Bluetooth";
        }
        {
          id = "ScreenRecorder";
        }
        {
          id = "WallpaperSelector";
        }
      ];
      right = [
        {
          id = "Notifications";
        }
        {
          id = "PowerProfile";
        }
        {
          id = "KeepAwake";
        }
      ];
    };
  };
  desktopWidgets = {
    enabled = false;
    gridSnap = false;
    monitorWidgets = [
      {
        name = "DP-1";
        widgets = [
          {
            clockStyle = "digital";
            format = "HH:mm\\nd MMMM yyyy";
            id = "Clock";
            scale = 0.5;
            showBackground = true;
            useCustomFont = false;
            usePrimaryColor = false;
            x = 50;
            y = 50;
          }
        ];
      }
    ];
  };
  dock = {
    animationSpeed = 1;
    backgroundOpacity = 1;
    colorizeIcons = false;
    deadOpacity = 0.6;
    displayMode = "auto_hide";
    enabled = false;
    floatingRatio = 1;
    inactiveIndicators = false;
    monitors = [

    ];
    onlySameOutput = true;
    pinnedApps = [

    ];
    pinnedStatic = false;
    size = 1;
  };
  general = {
    allowPanelsOnScreenWithoutBar = true;
    animationDisabled = false;
    animationSpeed = 1;
    avatarImage = "/home/iynaix/.face";
    boxRadiusRatio = 1;
    compactLockScreen = false;
    dimmerOpacity = 0.2;
    enableShadows = true;
    forceBlackScreenCorners = false;
    iRadiusRatio = 1;
    language = "";
    lockOnSuspend = true;
    radiusRatio = 1;
    scaleRatio = 1;
    screenRadiusRatio = 1;
    shadowDirection = "bottom_right";
    shadowOffsetX = 2;
    shadowOffsetY = 3;
    showHibernateOnLockScreen = false;
    showScreenCorners = false;
    showSessionButtonsOnLockScreen = true;
  };
  hooks = {
    darkModeChange = "";
    enabled = false;
    performanceModeDisabled = "";
    performanceModeEnabled = "";
    screenLock = "";
    screenUnlock = "";
    wallpaperChange = "";
  };
  location = {
    analogClockInCalendar = false;
    firstDayOfWeek = -1;
    name = "Singapore";
    showCalendarEvents = true;
    showCalendarWeather = true;
    showWeekNumberInCalendar = false;
    use12hourFormat = false;
    useFahrenheit = false;
    weatherEnabled = true;
    weatherShowEffects = true;
  };
  network = {
    wifiEnabled = false;
  };
  nightLight = {
    autoSchedule = true;
    dayTemp = "6500";
    enabled = false;
    forced = false;
    manualSunrise = "06:30";
    manualSunset = "18:30";
    nightTemp = "4000";
  };
  notifications = {
    backgroundOpacity = 1;
    criticalUrgencyDuration = 15;
    enableKeyboardLayoutToast = true;
    enabled = true;
    location = "top_right";
    lowUrgencyDuration = 3;
    monitors = [

    ];
    normalUrgencyDuration = 8;
    overlayLayer = true;
    respectExpireTimeout = false;
    sounds = {
      criticalSoundFile = "";
      enabled = false;
      excludedApps = "discord,firefox,chrome,chromium,edge";
      lowSoundFile = "";
      normalSoundFile = "";
      separateSounds = false;
      volume = 0.5;
    };
  };
  osd = {
    autoHideMs = 2000;
    backgroundOpacity = 1;
    enabled = true;
    enabledTypes = [
      0
      1
      2
      4
    ];
    location = "top_right";
    monitors = [

    ];
    overlayLayer = true;
  };
  screenRecorder = {
    audioCodec = "opus";
    audioSource = "default_output";
    colorRange = "limited";
    directory = "/home/iynaix/Videos";
    frameRate = 60;
    quality = "very_high";
    showCursor = true;
    videoCodec = "h264";
    videoSource = "portal";
  };
  sessionMenu = {
    countdownDuration = 3000;
    enableCountdown = true;
    largeButtonsStyle = true;
    position = "center";
    powerOptions = [
      {
        action = "reboot";
        command = "";
        countdownEnabled = true;
        enabled = true;
      }
      {
        action = "shutdown";
        command = "";
        countdownEnabled = true;
        enabled = true;
      }
      {
        action = "lock";
        command = "";
        countdownEnabled = true;
        enabled = true;
      }
      {
        action = "suspend";
        command = "";
        countdownEnabled = false;
        enabled = true;
      }
      {
        action = "hibernate";
        command = "";
        countdownEnabled = false;
        enabled = true;
      }
      {
        action = "logout";
        command = "";
        countdownEnabled = true;
        enabled = true;
      }
    ];
    showHeader = true;
  };
  settingsVersion = 32;
  systemMonitor = {
    cpuCriticalThreshold = 90;
    cpuPollingInterval = 3000;
    cpuWarningThreshold = 80;
    criticalColor = "";
    diskCriticalThreshold = 90;
    diskPollingInterval = 3000;
    diskWarningThreshold = 80;
    enableDgpuMonitoring = false;
    gpuCriticalThreshold = 90;
    gpuPollingInterval = 3000;
    gpuWarningThreshold = 80;
    memCriticalThreshold = 90;
    memPollingInterval = 3000;
    memWarningThreshold = 80;
    networkPollingInterval = 3000;
    tempCriticalThreshold = 90;
    tempPollingInterval = 3000;
    tempWarningThreshold = 80;
    useCustomColors = false;
    warningColor = "";
  };
  templates = {
    alacritty = false;
    cava = false;
    code = false;
    discord = false;
    emacs = false;
    enableUserTemplates = false;
    foot = false;
    fuzzel = false;
    ghostty = false;
    gtk = false;
    helix = false;
    hyprland = false;
    kcolorscheme = false;
    kitty = false;
    mango = false;
    niri = false;
    pywalfox = false;
    qt = false;
    spicetify = false;
    telegram = false;
    vicinae = false;
    walker = false;
    wezterm = false;
    yazi = false;
    zed = false;
  };
  ui = {
    bluetoothDetailsViewMode = "grid";
    bluetoothHideUnnamedDevices = false;
    fontDefault = "Geist";
    fontDefaultScale = 1;
    fontFixed = "JetBrainsMono Nerd Font";
    fontFixedScale = 1;
    panelBackgroundOpacity = 0.85;
    panelsAttachedToBar = true;
    settingsPanelMode = "centered";
    tooltipsEnabled = true;
    wifiDetailsViewMode = "grid";
  };
  wallpaper = {
    directory = "/home/iynaix/Pictures/Wallpapers";
    enableMultiMonitorDirectories = false;
    enabled = true;
    fillColor = "#000000";
    fillMode = "crop";
    hideWallpaperFilenames = false;
    monitorDirectories = [

    ];
    overviewEnabled = false;
    panelPosition = "follow_bar";
    randomEnabled = false;
    randomIntervalSec = 300;
    recursiveSearch = false;
    setWallpaperOnAllMonitors = true;
    transitionDuration = 1500;
    transitionEdgeSmoothness = 0.05;
    transitionType = "random";
    useWallhaven = false;
    wallhavenCategories = "111";
    wallhavenOrder = "desc";
    wallhavenPurity = "100";
    wallhavenQuery = "";
    wallhavenRatios = "";
    wallhavenResolutionHeight = "";
    wallhavenResolutionMode = "atleast";
    wallhavenResolutionWidth = "";
    wallhavenSorting = "relevance";
  };
}
