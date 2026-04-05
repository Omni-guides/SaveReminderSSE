Scriptname MCM Hidden

bool Function IsInstalled() Global Native
int Function GetVersionCode() Global Native

int Function GetModSettingInt(string a_modName, string a_settingName) Global Native
bool Function GetModSettingBool(string a_modName, string a_settingName) Global Native
float Function GetModSettingFloat(string a_modName, string a_settingName) Global Native
string Function GetModSettingString(string a_modName, string a_settingName) Global Native

Function SetModSettingInt(string a_modName, string a_settingName, int a_value) Global Native
Function SetModSettingBool(string a_modName, string a_settingName, bool a_value) Global Native
Function SetModSettingFloat(string a_modName, string a_settingName, float a_value) Global Native
Function SetModSettingString(string a_modName, string a_settingName, string a_value) Global Native
