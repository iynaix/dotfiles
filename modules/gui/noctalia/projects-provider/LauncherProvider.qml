import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

Item {
  id: root

  // Plugin API provided by PluginService
  property var pluginApi: null

  // Provider metadata
  property string name: "Projects"
  property var launcher: null
  property bool handleSearch: false
  property string supportedLayouts: "list"
  property bool supportsAutoPaste: false

  // Projects
  readonly property string projectDir: "%PROJECT_DIR%" // actual value will be substituted in by nix
  property var projects: ({})
  property bool loaded: false
  property bool loading: false

  // Load projects on init
  function init() {
    if (pluginApi && pluginApi.pluginDir && !loading && !loaded) {
      loading = true;
      projectsScanner.running = true;
    }
  }

  Process {
    id: projectsScanner
    command: [
      "sh", "-c",
      "find '" + projectDir + "' -mindepth 1 -maxdepth 1 -type d | sort -f"
    ]
    running: false
    stdout: StdioCollector {}

    onExited: function (exitCode) {
      loading = false;
      loaded = true;

      if (exitCode !== 0) {
        Logger.e("ProjectsProvider", "Scan failed with code: " + exitCode);
        return;
      }

      var output = String(stdout.text || "");
      var projectDirs = output.trim().split('\n').forEach(function (dir) {
        var proj = dir.replace(projectDir, "");
        proj = proj.replace(/^\/+/g, ""); // replace leading slashes

        if (proj.length > 0) {
          root.projects[proj] = dir;
        };
      });

      Logger.i("ProjectsProvider", "Projects loaded,", Object.keys(root.projects).length, "entries");
    }
  }

  // Check if this provider handles the command
  function handleCommand(searchText) {
    return searchText.startsWith(">pj") || searchText.startsWith(">projects ");
  }

  // Return available commands when user types ">"
  function commands() {
    return [{
      "name": ">pj",
      "description": "Browse and open projects in the editor",
      "icon": "edit",
      "isTablerIcon": true,
      "isImage": false,
      "onActivate": function() {
        launcher.setSearchText(">pj ");
      }
    }];
  }

  // Get search results
  function getResults(searchText) {
    if (!searchText.startsWith(">pj") && !searchText.startsWith(">projects")) {
      return [];
    }

    if (loading) {
      return [{
        "name": "Loading...",
        "description": "Loading projects...",
        "icon": "refresh",
        "isTablerIcon": true,
        "isImage": false,
        "onActivate": function() {}
      }];
    }

    if (!loaded) {
      return [{
        "name": "Projects not loaded",
        "description": "Try reopening the launcher",
        "icon": "alert-circle",
        "isTablerIcon": true,
        "isImage": false,
        "onActivate": function() {
          root.init();
        }
      }];
    }

    var query = searchText.replace(/^>pj/, "").replace(/^>projects/, "").trim();
    var queryRegex = new RegExp(query.split("").join(".*"), "i");
    var results = [];

    var keys = Object.keys(projects);
    var count = 0;

    // show up to 100 results
    for (var k = 0; k < keys.length && count < 100; k++) {
      var project = keys[k];
      var directory = projects[project];

      if (query === "" || queryRegex.test(project)) {
        results.push(formatProjectEntry(project, directory));
        count++;
      }
    }

    return results;
  }

  // Format a project entry for the results list
  function formatProjectEntry(project, directory) {
    return {
      "name": project,
      "description": null,
      "icon": "folder",
      "isTablerIcon": true,
      "isImage": false,
      "hideIcon": false,         // No icon needed in list view
      "singleLine": true,
      "onActivate": function() {
        Quickshell.execDetached(["sh", "-c", "codium '" + directory + "'"]);
        launcher.close();
      }
    };
  }
}
