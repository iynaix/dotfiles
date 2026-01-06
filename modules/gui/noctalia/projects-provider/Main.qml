import QtQuick
import Quickshell.Io
import qs.Services.UI

Item {
  property var pluginApi: null

  IpcHandler {
    target: "plugin:projects"
    function toggle() {
      pluginApi.withCurrentScreen(screen => {
        var launcherPanel = PanelService.getPanel("launcherPanel", screen);
        if (!launcherPanel)
          return;
        var searchText = launcherPanel.searchText || "";
        var isInProjectsMode = searchText.startsWith(">pj") || searchText.startsWith(">projects ");
        if (!launcherPanel.isPanelOpen) {
          launcherPanel.open();
          launcherPanel.setSearchText(">pj ");
        } else if (isInProjectsMode) {
          launcherPanel.close();
        } else {
          launcherPanel.setSearchText(">pj ");
        }
      });
    }
  }
}
