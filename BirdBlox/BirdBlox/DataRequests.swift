//
//  DataRequests.swift
//  BirdBlox
//
//  Created by birdbrain on 4/27/17.
//  Copyright © 2017 Birdbrain Technologies LLC. All rights reserved.
//

import Foundation
import Swifter

class DataManager: NSObject {
    
    let view_controller: BBTWebViewController
    
    init(view_controller: BBTWebViewController){
        self.view_controller = view_controller
        super.init()
    }
    
    func loadRequests(server: BBTBackendServer){
        server["/data/files"] = filesRequest(request:)
		server["/data/getAvailableName"] = self.availableNameRequest
        
        server["/data/save"] = saveRequest(request:)
        server["/data/load"] = loadRequest(request:)
        server["/data/rename"] = renameRequest(request:)
        server["/data/delete"] = deleteRequest(request:)
        server["/data/export"] = exportRequest(request:)
		server["/data/duplicate"] = self.duplicateRequest
    }
	
	func availableNameRequest(request: HttpRequest) -> HttpResponse {
		let queries = BBTSequentialQueryArrayToDict(request.queryParams)
		
		guard let name = queries["filename"],
			let typeStr = queries["type"] else {
			return .badRequest(.text("Missing Parameters"))
		}
		
		guard let type = self.fileType(fromParameter: typeStr) else {
			return .badRequest(.text("Invalid type argument"))
		}
		
		//To find the reason why a name might be different
		let sanName = DataModel.sanitizedName(of: name)
		let alreadySanitized = (sanName == name)
		let alreadyAvailable = DataModel.shared.filenameAvailalbe(name: name, type: type)
		let availableName = DataModel.shared.availableName(from: name, type: type)!
		
		let json: [String : Any] = ["availableName" : availableName,
		                            "alreadySanitized" : alreadySanitized,
									"alreadyAvailable" : alreadyAvailable]
		return .ok(.json(json as AnyObject))
	}
    
    func filesRequest(request: HttpRequest) -> HttpResponse {
        let filenameList = DataModel.shared.savedBBXFiles
//		print(filenameList)
		let nameList = filenameList.map({$0.replacingOccurrences(of: ".bbx", with: "")})
//		let bodyString = nameList.joined(separator: "\n")
		let nameDict = ["files": nameList]
		
        return .ok(.json(nameDict as AnyObject))
    }
    
    func saveRequest(request: HttpRequest) -> HttpResponse {
		let queries = BBTSequentialQueryArrayToDict(request.queryParams)
		
        guard let rawName = queries["filename"],
			let fileString = NSString(bytes:request.body, length: request.body.count,
			                          encoding: String.Encoding.utf8.rawValue) else {
			return .badRequest(.text("Malformed Request"))
		}
		
		var name = DataModel.sanitizedName(of: rawName)
		
		if queries["options"] == "new" {
			name = DataModel.shared.availableName(from: name)!
		}
		else {
			if queries["options"] == "soft" && !DataModel.shared.bbxNameAvailable(name) {
				return .raw(409, "Conflict", nil, nil)
			}
			guard rawName == name else {
				return .badRequest(.text("Illegal Characters in filename"))
			}
		}
		
		guard DataModel.shared.save(bbxString: fileString as String, withName: name) else {
			return .internalServerError
		}
		
		return .raw(201, "Created", ["Location" : "/data/load?filename=\(name)"]) {
					(writer) throws -> Void in
							try writer.write([UInt8](name.utf8))
				}
    }
	
    func loadRequest(request: HttpRequest) -> HttpResponse {
		let queries = BBTSequentialQueryArrayToDict(request.queryParams)
		
		if let filename = queries["filename"] {
			if let fileContent = DataModel.shared.getBBXContent(byName: filename) {
				return .ok(.text(fileContent as (String)))
			}
			else {
				return .notFound
			}
		}
		
		return .badRequest(.text("Malformed Request"))
    }
	
    func renameRequest(request: HttpRequest) -> HttpResponse {
		let queries = BBTSequentialQueryArrayToDict(request.queryParams)
		
		guard let oldFilename = queries["oldFilename"],
			let newFilename = queries["newFilename"],
			let typeStr = queries["type"] else {
			return .badRequest(.text("Missing Parameters"))
		}
		
		guard DataModel.nameIsSanitary(oldFilename) && DataModel.nameIsSanitary(newFilename) else {
			return .badRequest(.text("Unsanitary parameter arguments"))
		}
		
		guard let type = self.fileType(fromParameter: typeStr) else {
			return .badRequest(.text("Invalid type argument"))
		}
		
		if queries["options"] == "soft" && !DataModel.shared.filenameAvailalbe(name: newFilename,
		                                                                       type: type) {
			return .raw(409, "Conflict", nil, nil)
		}
		
		guard DataModel.shared.renameFile(from: oldFilename, to: newFilename, type: type) else {
			return .internalServerError
		}
		
		return .ok(.text("File Renamed"))
	}
	
	func duplicateRequest(request: HttpRequest) -> HttpResponse {
		let queries = BBTSequentialQueryArrayToDict(request.queryParams)
		
		guard let oldFilename = queries["filename"],
			let newFilename = queries["newFilename"] else {
				return .badRequest(.text("Missing Parameters"))
		}
		guard DataModel.nameIsSanitary(oldFilename) && DataModel.nameIsSanitary(newFilename) else {
			return .badRequest(.text("Unsanitary parameter arguments"))
		}
		
		let type: DataModel.BBXFileType = .BirdBloxProgram
		
		guard DataModel.shared.copyFile(from: oldFilename, to: newFilename, type: type) else {
			return .internalServerError
		}
		
		return .ok(.text("copied"))
	}
	
    func deleteRequest(request: HttpRequest) -> HttpResponse {
		let queries = BBTSequentialQueryArrayToDict(request.queryParams)
		
		guard let filename = queries["filename"],
			  let typeStr = queries["type"] else {
			return .badRequest(.text("Missing Parameters"))
		}
		
		guard let type = self.fileType(fromParameter: typeStr) else {
			return .badRequest(.text("Invalid type argument"))
		}
		
		if DataModel.shared.deleteFile(byName: filename, type: type) {
			return .ok(.text("File Deleted"))
		} else {
			return .internalServerError
		}
		
		
    }
	
    func exportRequest(request: HttpRequest) -> HttpResponse {
		let queries = BBTSequentialQueryArrayToDict(request.queryParams)
		
		if let filename = queries["filename"] {
			let exportedPath = DataModel.shared.getBBXFileLoc(byName: filename)
			if  FileManager.default.fileExists(atPath: exportedPath.path) {
				let url = URL(fileURLWithPath: exportedPath.path)
				let view = UIActivityViewController(activityItems: [url], applicationActivities: nil)
				
				view.popoverPresentationController?.sourceView = self.view_controller.view
				view.excludedActivityTypes = nil
				DispatchQueue.main.async{
					self.view_controller.present(view, animated: true, completion: nil)
				}
				
				print(filename)
				print(exportedPath.path)
				
				return .ok(.text("Exported"))
			}
			else {
				return .internalServerError
			}
        }
		
		return .badRequest(.text("Malformed Request"))
    }
    
	//MARK: Supporting functions
	func fileType(fromParameter: String) -> DataModel.BBXFileType? {
		switch fromParameter {
		case "recording":
			return DataModel.BBXFileType.SoundRecording
		case "file":
			return DataModel.BBXFileType.BirdBloxProgram
		default:
			return nil
		}
	}
}
