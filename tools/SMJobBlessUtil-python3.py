import sys
import os
import getopt
import subprocess
import plistlib
import operator
import platform

class UsageException (Exception):
    """
    Raised when the progam detects a usage issue; the top-level code catches this
    and prints a usage message.
    """
    pass

class CheckException (Exception):
    """
    Raised when the "check" subcommand detects a problem; the top-level code catches
    this and prints a nice error message.
    """
    def __init__(self, message, path=None):
        self.message = message
        self.path = path

def checkCodeSignature(programPath, programType):
    """Checks the code signature of the referenced program."""

    args = [
        "codesign",
        "-v",
        "-v",
        programPath
    ]
    try:
        subprocess.check_call(args, stderr=open("/dev/null"))
    except subprocess.CalledProcessError as e:
        raise CheckException("%s code signature invalid" % programType, programPath)

def readDesignatedRequirement(programPath, programType):
    """Returns the designated requirement of the program as a string."""
    args = [
        "codesign",
        "-d",
        "-r",
        "-",
        programPath
    ]
    try:
        req = subprocess.check_output(args, stderr=open("/dev/null"), encoding="utf-8")
    except subprocess.CalledProcessError as e:
        raise CheckException("%s designated requirement unreadable" % programType, programPath)

    reqLines = req.splitlines()
    if len(reqLines) != 1 or not req.startswith("designated => "):
        raise CheckException("%s designated requirement malformed" % programType, programPath)
    return reqLines[0][len("designated => "):]

def readInfoPlistFromPath(infoPath):
    """Reads an "Info.plist" file from the specified path."""
    try:
        with open(infoPath, 'rb') as fp:
            info = plistlib.load(fp)
    except:
        raise CheckException("'Info.plist' not readable", infoPath)
    if not isinstance(info, dict):
        raise CheckException("'Info.plist' root must be a dictionary", infoPath)
    return info

def readPlistFromToolSection(toolPath, segmentName, sectionName):
    """Reads a dictionary property list from the specified section within the specified executable."""

    args = [
        "otool",
        "-V",
        "-arch",
        platform.machine(),
        "-s",
        segmentName,
        sectionName,
        toolPath
    ]
    try:
        plistDump = subprocess.check_output(args, encoding="utf-8")
    except subprocess.CalledProcessError as e:
        raise CheckException("tool %s / %s section unreadable" % (segmentName, sectionName), toolPath)

    plistLines = plistDump.strip().splitlines(keepends=True)

    if len(plistLines) < 3:
        raise CheckException("tool %s / %s section dump malformed (1)" % (segmentName, sectionName), toolPath)

    header = plistLines[1].strip()

    if not header.endswith("(%s,%s) section" % (segmentName, sectionName)):
        raise CheckException("tool %s / %s section dump malformed (2)" % (segmentName, sectionName), toolPath)

    del plistLines[0:2]

    try:

        if header.startswith('Contents of'):
            data = []
            for line in plistLines:
                parts = line.split('|')
                assert len(parts) == 3
                columns = parts[0].split()
                assert len(columns) >= 2
                del columns[0]
                for hexStr in columns:
                    data.append(int(hexStr, 16))
            data = bytes(data)
        else:
            data = bytes("".join(plistLines), encoding="utf-8")

        plist = plistlib.loads(data)
    except:
        raise CheckException("tool %s / %s section dump malformed (3)" % (segmentName, sectionName), toolPath)

    if not isinstance(plist, dict):
        raise CheckException("tool %s / %s property list root must be a dictionary" % (segmentName, sectionName), toolPath)

    return plist

def checkStep1(appPath):
    """Checks that the app and the tool are both correctly code signed."""

    if not os.path.isdir(appPath):
        raise CheckException("app not found", appPath)

    checkCodeSignature(appPath, "app")

    toolDirPath = os.path.join(appPath, "Contents", "Library", "LaunchServices")
    if not os.path.isdir(toolDirPath):
        raise CheckException("tool directory not found", toolDirPath)

    toolPathList = []
    for toolName in os.listdir(toolDirPath):
        if toolName != ".DS_Store":
            toolPath = os.path.join(toolDirPath, toolName)
            if not os.path.isfile(toolPath):
                raise CheckException("tool directory contains a directory", toolPath)
            checkCodeSignature(toolPath, "tool")
            toolPathList.append(toolPath)

    if len(toolPathList) == 0:
        raise CheckException("no tools found", toolDirPath)

    return toolPathList

def checkStep2(appPath, toolPathList):
    """Checks the SMPrivilegedExecutables entry in the app's "Info.plist"."""

    toolNameToReqMap = dict()
    for toolPath in toolPathList:
        req = readDesignatedRequirement(toolPath, "tool")
        toolNameToReqMap[os.path.basename(toolPath)] = req

    infoPath = os.path.join(appPath, "Contents", "Info.plist")
    info = readInfoPlistFromPath(infoPath)
    if "SMPrivilegedExecutables" not in info:
        raise CheckException("'SMPrivilegedExecutables' not found", infoPath)
    infoToolDict = info["SMPrivilegedExecutables"]
    if not isinstance(infoToolDict, dict):
        raise CheckException("'SMPrivilegedExecutables' must be a dictionary", infoPath)

    if sorted(infoToolDict.keys()) != sorted(toolNameToReqMap.keys()):
        raise CheckException("'SMPrivilegedExecutables' and tools in 'Contents/Library/LaunchServices' don't match")

    for toolName in infoToolDict:
        if infoToolDict[toolName] != toolNameToReqMap[toolName]:
            raise CheckException("tool designated requirement (%s) doesn't match entry in 'SMPrivilegedExecutables' (%s)" % (toolNameToReqMap[toolName], infoToolDict[toolName]))

def checkStep3(appPath, toolPathList):
    """Checks the "Info.plist" embedded in each helper tool."""

    appReq = readDesignatedRequirement(appPath, "app")

    for toolPath in toolPathList:
        info = readPlistFromToolSection(toolPath, "__TEXT", "__info_plist")

        if "CFBundleInfoDictionaryVersion" not in info or info["CFBundleInfoDictionaryVersion"] != "6.0":
            raise CheckException("'CFBundleInfoDictionaryVersion' in tool __TEXT / __info_plist section must be '6.0'", toolPath)

        if "CFBundleIdentifier" not in info or info["CFBundleIdentifier"] != os.path.basename(toolPath):
            raise CheckException("'CFBundleIdentifier' in tool __TEXT / __info_plist section must match tool name", toolPath)

        if "SMAuthorizedClients" not in info:
            raise CheckException("'SMAuthorizedClients' in tool __TEXT / __info_plist section not found", toolPath)
        infoClientList = info["SMAuthorizedClients"]
        if not isinstance(infoClientList, list):
            raise CheckException("'SMAuthorizedClients' in tool __TEXT / __info_plist section must be an array", toolPath)
        if len(infoClientList) != 1:
            raise CheckException("'SMAuthorizedClients' in tool __TEXT / __info_plist section must have one entry", toolPath)

        if infoClientList[0] != appReq:
            raise CheckException("app designated requirement (%s) doesn't match entry in 'SMAuthorizedClients' (%s)" % (appReq, infoClientList[0]), toolPath)

def checkStep4(appPath, toolPathList):
    """Checks the "launchd.plist" embedded in each helper tool."""

    for toolPath in toolPathList:
        launchd = readPlistFromToolSection(toolPath, "__TEXT", "__launchd_plist")

        if "Label" not in launchd or launchd["Label"] != os.path.basename(toolPath):
            raise CheckException("'Label' in tool __TEXT / __launchd_plist section must match tool name", toolPath)

def checkStep5(appPath):
    """There's nothing to do here; we effectively checked for this is steps 1 and 2."""
    pass

def check(appPath):
    """Checks the SMJobBless setup of the specified app."""

    toolPathList = checkStep1(appPath)
    checkStep2(appPath, toolPathList)
    checkStep3(appPath, toolPathList)
    checkStep4(appPath, toolPathList)
    checkStep5(appPath)

def setreq(appPath, appInfoPlistPath, toolInfoPlistPaths):
    """
    Reads information from the built app and uses it to set the SMJobBless setup
    in the specified app and tool Info.plist source files.
    """

    if not os.path.isdir(appPath):
        raise CheckException("app not found", appPath)

    if not os.path.isfile(appInfoPlistPath):
        raise CheckException("app 'Info.plist' not found", appInfoPlistPath)
    for toolInfoPlistPath in toolInfoPlistPaths:
        if not os.path.isfile(toolInfoPlistPath):
            raise CheckException("app 'Info.plist' not found", toolInfoPlistPath)

    appReq = readDesignatedRequirement(appPath, "app")

    toolDirPath = os.path.join(appPath, "Contents", "Library", "LaunchServices")
    if not os.path.isdir(toolDirPath):
        raise CheckException("tool directory not found", toolDirPath)

    toolNameToReqMap = {}
    for toolName in os.listdir(toolDirPath):
        req = readDesignatedRequirement(os.path.join(toolDirPath, toolName), "tool")
        toolNameToReqMap[toolName] = req

    if len(toolNameToReqMap) > len(toolInfoPlistPaths):
        raise CheckException("tool directory has more tools (%d) than you've supplied tool 'Info.plist' paths (%d)" % (len(toolNameToReqMap), len(toolInfoPlistPaths)), toolDirPath)
    if len(toolNameToReqMap) < len(toolInfoPlistPaths):
        raise CheckException("tool directory has fewer tools (%d) than you've supplied tool 'Info.plist' paths (%d)" % (len(toolNameToReqMap), len(toolInfoPlistPaths)), toolDirPath)

    appToolDict = {}
    toolInfoPlistPathToToolInfoMap = {}
    for toolInfoPlistPath in toolInfoPlistPaths:
        toolInfo = readInfoPlistFromPath(toolInfoPlistPath)
        toolInfoPlistPathToToolInfoMap[toolInfoPlistPath] = toolInfo
        if "CFBundleIdentifier" not in toolInfo:
            raise CheckException("'CFBundleIdentifier' not found", toolInfoPlistPath)
        bundleID = toolInfo["CFBundleIdentifier"]
        if not isinstance(bundleID, str):
            raise CheckException("'CFBundleIdentifier' must be a string", toolInfoPlistPath)
        appToolDict[bundleID] = toolNameToReqMap[bundleID]

    appInfo = readInfoPlistFromPath(appInfoPlistPath)
    needsUpdate = "SMPrivilegedExecutables" not in appInfo
    if not needsUpdate:
        oldAppToolDict = appInfo["SMPrivilegedExecutables"]
        if not isinstance(oldAppToolDict, dict):
            raise CheckException("'SMPrivilegedExecutables' must be a dictionary", appInfoPlistPath)
        appToolDictSorted = sorted(appToolDict.items(), key=operator.itemgetter(0))
        oldAppToolDictSorted = sorted(oldAppToolDict.items(), key=operator.itemgetter(0))
        needsUpdate = (appToolDictSorted != oldAppToolDictSorted)

    if needsUpdate:
        appInfo["SMPrivilegedExecutables"] = appToolDict
        with open(appInfoPlistPath, 'wb') as fp:
            plistlib.dump(appInfo, fp)
        print ("%s: updated" % appInfoPlistPath, file = sys.stdout)

    toolAppListSorted = [ appReq ]
    for toolInfoPlistPath in toolInfoPlistPaths:
        toolInfo = toolInfoPlistPathToToolInfoMap[toolInfoPlistPath]

        needsUpdate = "SMAuthorizedClients" not in toolInfo
        if not needsUpdate:
            oldToolAppList = toolInfo["SMAuthorizedClients"]
            if not isinstance(oldToolAppList, list):
                raise CheckException("'SMAuthorizedClients' must be an array", toolInfoPlistPath)
            oldToolAppListSorted = sorted(oldToolAppList)
            needsUpdate = (toolAppListSorted != oldToolAppListSorted)

        if needsUpdate:
            toolInfo["SMAuthorizedClients"] = toolAppListSorted
            with open(toolInfoPlistPath, 'wb') as f:
                plistlib.dump(toolInfo, f)
            print("%s: updated" % toolInfoPlistPath, file = sys.stdout)

def main():
    options, appArgs = getopt.getopt(sys.argv[1:], "d")

    debug = False
    for opt, val in options:
        if opt == "-d":
            debug = True
        else:
            raise UsageException()

    if len(appArgs) == 0:
        raise UsageException()
    command = appArgs[0]
    if command == "check":
        if len(appArgs) != 2:
            raise UsageException()
        check(appArgs[1])
    elif command == "setreq":
        if len(appArgs) < 4:
            raise UsageException()
        setreq(appArgs[1], appArgs[2], appArgs[3:])
    else:
        raise UsageException()

if __name__ == "__main__":
    try:
        main()
    except CheckException as e:
        if e.path is None:
            print("%s: %s" % (os.path.basename(sys.argv[0]), e.message), file = sys.stderr)
        else:
            path = e.path
            if path.endswith("/"):
                path = path[:-1]
            print("%s: %s" % (path, e.message), file = sys.stderr)
        sys.exit(1)
    except UsageException as e:
        print("usage: %s check  /path/to/app" % os.path.basename(sys.argv[0]), file = sys.stderr)
        print("       %s setreq /path/to/app /path/to/app/Info.plist /path/to/tool/Info.plist..." % os.path.basename(sys.argv[0]), file = sys.stderr)
        sys.exit(1)
