//
//  DocumentManager.swift
//  Snap for Hummingbird
//
//  Created by birdbrain on 7/13/15.
//  Copyright (c) 2015 Birdbrain Technologies LLC. All rights reserved.
//

import Foundation


let documentsPath: URL! = URL(string: NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0])

let fileManager = FileManager.default
let mainBundle = CFBundleGetMainBundle()


public func getPath() -> URL {
    let path: URL = CFBundleCopyBundleURL(mainBundle) as URL
    return path
}

public func getSoundNames () -> [String]{
    do {
        let paths = try fileManager.contentsOfDirectory(atPath: getPath().path)
        let files = paths.filter{ (getPath().appendingPathComponent($0)).pathExtension == "wav" }
        return files
    } catch {
        return []
    }
}

public func saveStringToFile(_ string: NSString, fileName: String) -> Bool{
    let fullFileName = fileName + ".bbx"
    let isDir: UnsafeMutablePointer<ObjCBool>? = nil
    if(!fileManager.fileExists(atPath: getSavePath().path, isDirectory: isDir)) {
        do {
        try fileManager.createDirectory(atPath: getSavePath().path, withIntermediateDirectories: false, attributes: nil)
        }
        catch {
            NSLog("Failed to create save directory")
            return false
        }
    }
    
    let path = getSavePath().appendingPathComponent(fullFileName).path
    do {
        //fileManager.createFileAtPath(path, contents: nil, attributes: nil)
        try string.write(toFile: path, atomically: true, encoding: String.Encoding.utf8.rawValue)
        print("Wrote " + (string as String) + " to file")
        NSLog("Filename of saved file: " + fullFileName)
        NSLog("return true")
        return true
    }
    catch {
        NSLog("return false: \(error)")
        return false
    }
}

public func autosave(_ string: NSString) {
    saveStringToFile(string, fileName: "autosaveFile")
}

public func getAutosave() -> NSString {
    return getSavedFileByName("autosaveFile")
}

public func getSavedFileNames() -> [String]{
    do {
        let paths = try fileManager.contentsOfDirectory(atPath: getSavePath().path)
        var paths2 = paths.map({ (string) -> String in
            return string.replacingOccurrences(of: ".bbx", with: "")
        })
        if let index = paths2.index(of: "autosaveFile") {
            paths2.remove(at: index)
        }
        NSLog(getAllFiles().joined(separator: ", "))
        return paths2
    } catch {
        NSLog(getAllFiles().joined(separator: ", "))
        return []
    }
}

public func getAllFiles() -> [String] {
    do {
        let paths = try fileManager.contentsOfDirectory(atPath: getSavePath().path)
        return paths
    } catch {
        return []
    }

}

public func getSavePath() -> URL{
    return getDocPath().appendingPathComponent("SavedFiles")
}

public func getSavedFileURL(_ filename: String) ->URL {
    let fullFileName = filename + ".bbx"
    let path = getSavePath().appendingPathComponent(fullFileName)
    return path
}

public func getSavedFileByName(_ fileName: String) -> NSString {
    do {
        let fullFileName = fileName + ".bbx"
        let path = getSavePath().appendingPathComponent(fullFileName).path
        let file: NSString = try NSString(contentsOfFile: path, encoding: String.Encoding.utf8.rawValue)
        return file
    } catch {
        return "File not found"
    }
}

public func deleteFile(_ fileName: String) -> Bool {
    let fullFileName = fileName + ".bbx"
    let path = getSavePath().appendingPathComponent(fullFileName).path
    do {
        try fileManager.removeItem(atPath: path)
        return true
    } catch {
        return false
    }
}

public func deleteFileAtPath(_ path: String) {
    do {
        try fileManager.removeItem(atPath: path)
    } catch {
    
    }
}

public func renameFile(_ startFileName: String, newFileName: String) -> Bool {
    let startFullFileName = startFileName + ".bbx"
    let startPath = getSavePath().appendingPathComponent(startFullFileName).path
    let newFullFileName = newFileName + ".bbx"
    let newPath = getSavePath().appendingPathComponent(newFullFileName).path
    do {
        try fileManager.moveItem(atPath: startPath, toPath: newPath)
        return true
    } catch {
        return false
    }
}

public func getDocPath() -> URL{
    return documentsPath
}

public func getSettingsPath() -> URL {
    return getDocPath().appendingPathComponent("Settings.plist")
}

private func getSettings() -> NSMutableDictionary {
    var settings: NSMutableDictionary
    if (!fileManager.fileExists(atPath: getSettingsPath().path)) {
        settings = NSMutableDictionary()
        settings.write(toFile: getSettingsPath().path, atomically: true)
    }
    settings = NSMutableDictionary(contentsOfFile: getSettingsPath().path)!
    return settings
}

private func saveSettings(_ settings: NSMutableDictionary) {
    settings.write(toFile: getSettingsPath().path, atomically: true)
}

public func addSetting(_ key: String, value: String) {
    let settings = getSettings()
    settings.setValue(value, forKey: key)
    saveSettings(settings)
}

public func getSetting(_ key: String) -> String? {
    if let value = getSettings().value(forKey: key) {
        return value as? String
    }
    return nil
}

public func removeSetting(_ key: String) {
    let settings = getSettings()
    settings.removeObject(forKey: key)
    saveSettings(settings)
}
