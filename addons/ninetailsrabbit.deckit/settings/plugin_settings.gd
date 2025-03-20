@tool
class_name MyPluginSettings extends RefCounted

const PluginPrefixName: String = "ninetailsrabbit.deckit" ## The folder name
const GitRepositoryName: String = "deckit"

static var PluginName: String = "Deckit"
static var PluginProjectName: String = ProjectSettings.get_setting("application/config/name")
static var PluginBasePath: String = "res://addons/%s" % PluginPrefixName
static var PluginLocalConfigFilePath = "%s/plugin.cfg" % PluginBasePath
static var PluginSettingsBasePath: String = "%s/config/%s" % [PluginProjectName, PluginPrefixName]
static var RemoteReleasesUrl = "https://api.github.com/repos/ninetailsrabbit/%s/releases" % GitRepositoryName
static var PluginTemporaryDirectoryPath = OS.get_user_data_dir() + "/" + PluginPrefixName
static var PluginTemporaryReleaseUpdateDirectoryPath = "%s/update" % PluginTemporaryDirectoryPath
static var PluginTemporaryReleaseFilePath = "%s/%s.zip" % [PluginTemporaryDirectoryPath, PluginPrefixName]
static var PluginDebugDirectoryPath = "res://debug"

#region Plugin Settings
#static var UpdateNotificationSetting: String = PluginSettingsBasePath + "/update_notification_enabled"
#endregion

## Enable to test the updater without need to have a latest release version to trigger it
static var DebugMode: bool = false
