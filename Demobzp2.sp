#pragma semicolon 1
#include <sourcemod>
#include <bzip2>
#include<pugsetup>

Handle g_hCvarBzip = INVALID_HANDLE;

int g_iBzip2 = 9;

char g_sDemoPath[PLATFORM_MAX_PATH];

bool g_bRecording = false;

public OnPluginStart() {

	g_hCvarBzip = CreateConVar("sm_tautodemoupload_bzip2", "5", "Compression level. If set > 0 demos will be compressed before uploading. (Requires bzip2 extension.)");
	
	HookConVarChange(g_hCvarBzip, Cvar_Changed);
	AutoExecConfig(true, "Demobzp2");
	AddCommandListener(CommandListener_Record, "tv_record");
	AddCommandListener(CommandListener_StopRecord, "tv_stoprecord");
}

public OnConfigsExecuted() {
	g_iBzip2 = GetConVarBool(g_hCvarBzip);
}

public Cvar_Changed(Handle:convar, const String:oldValue[], const String:newValue[]) {
	OnConfigsExecuted();
}


public OnMapStart() 
{
	g_bRecording = false;
}

public Action CommandListener_Record(client, const String:command[], argc) {
	
	if(g_bRecording)return;

	GetCmdArg(1, g_sDemoPath, sizeof(g_sDemoPath));

	if(!StrEqual(g_sDemoPath, "")) {
		g_bRecording = true;
	}

	// Append missing .dem
	if(strlen(g_sDemoPath) < 4 || strncmp(g_sDemoPath[strlen(g_sDemoPath)-4], ".dem", 4, false) != 0) 
	{
		Format(g_sDemoPath, sizeof(g_sDemoPath), "%s.dem", g_sDemoPath);
	}
}

public void PugSetup_OnLive()
{
	CreateTimer(2.0, PrintDemo);
}

public Action PrintDemo(Handle timer) 
{
	PrintToChatAll("[\x05NEKO\x01] \x07 GOTV \x01开始录制\n: \x03%s\x01",g_sDemoPath);
}

public void PugSetup_OnMatchOver(bool hasDemo, const char[] demoFileName)
{
	PrintToChatAll("[\x05NEKO\x01] \x07 GOTV \x01结束录制,当前demo保存为:\n \x06%s\x01",demoFileName);
}

public Action CommandListener_StopRecord(client, const String:command[], argc) {
	
	if(g_bRecording) {
		new Handle:hDataPack = CreateDataPack();
		CreateDataTimer(5.0, Timer_UploadDemo, hDataPack);
		WritePackString(hDataPack, g_sDemoPath);
		Format(g_sDemoPath, sizeof(g_sDemoPath), "");
	}

	g_bRecording = false;
}

public Action Timer_UploadDemo(Handle timer, Handle hDataPack) 
{
	ResetPack(hDataPack);
	
	char sDemoPath[PLATFORM_MAX_PATH];
	char sBzipPath[PLATFORM_MAX_PATH];
	
	ReadPackString(hDataPack, sDemoPath, sizeof(sDemoPath));
	
	Format(sBzipPath, sizeof(sBzipPath), "%s.bz2", sDemoPath);
	
	BZ2_CompressFile(sDemoPath, sBzipPath, g_iBzip2, CompressionComplete);
	
}

public CompressionComplete(BZ_Error:iError, String:inFile[], String:outFile[], any:data) 
{
	if(iError == BZ_OK) {
		LogMessage("%s compressed to %s", inFile, outFile);
		
		if(StrEqual(outFile[strlen(outFile)-4], ".bz2")) 
		{
			char sLocalNoCompressFile[PLATFORM_MAX_PATH];
			strcopy(sLocalNoCompressFile, strlen(outFile)-3, outFile);
			if(DeleteFile(sLocalNoCompressFile))
			{
				LogMessage("DeleteFile %s", sLocalNoCompressFile);
			}
			else
			{
				LogMessage("DeleteError %s", sLocalNoCompressFile);
			}
		}
	} else {
		LogBZ2Error(iError);
	}
	
}
