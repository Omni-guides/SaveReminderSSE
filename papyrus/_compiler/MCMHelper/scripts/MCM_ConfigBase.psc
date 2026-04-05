Scriptname MCM_ConfigBase extends SKI_ConfigBase

Function RefreshMenu() Native
Function SetMenuOptions(string a_ID, string[] a_options, string[] a_shortNames = None) Native

int Function GetModSettingInt(string a_settingName) Native
bool Function GetModSettingBool(string a_settingName) Native
float Function GetModSettingFloat(string a_settingName) Native
string Function GetModSettingString(string a_settingName) Native

Function SetModSettingInt(string a_settingName, int a_value) Native
Function SetModSettingBool(string a_settingName, bool a_value) Native
Function SetModSettingFloat(string a_settingName, float a_value) Native
Function SetModSettingString(string a_settingName, string a_value) Native
