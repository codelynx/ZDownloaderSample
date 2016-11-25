//
//	ZManagedObjectStorage.swift
//	ZKit
//
//	The MIT License (MIT)
//
//	Copyright (c) 2016 Electricwoods LLC, Kaz Yoshikawa.
//
//	Permission is hereby granted, free of charge, to any person obtaining a copy 
//	of this software and associated documentation files (the "Software"), to deal 
//	in the Software without restriction, including without limitation the rights 
//	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell 
//	copies of the Software, and to permit persons to whom the Software is 
//	furnished to do so, subject to the following conditions:
//
//	The above copyright notice and this permission notice shall be included in 
//	all copies or substantial portions of the Software.
//
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
//	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
//	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
//	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, 
//	WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//	THE SOFTWARE.


import Foundation
import CoreData


public class ZManagedObjectStorage {

	public private(set) var fileURL: URL
	public private(set) var modelName: String

	public init?(fileURL: URL, modelName: String) {
		self.fileURL = fileURL
		self.modelName = modelName
		if self.managedObjectContext == nil {
			return nil
		}
	}
	
	public lazy var managedObjectModel: NSManagedObjectModel? = {
		var managedObjectModel: NSManagedObjectModel? = nil
		let modelURL = Bundle.main.url(forResource: self.modelName, withExtension: "momd")
		if  modelURL != nil {
			managedObjectModel = NSManagedObjectModel(contentsOf: modelURL!)
		}
		if managedObjectModel == nil { print("ZManagedObjectStorage: model not found: name=\(self.modelName)") }
		return managedObjectModel
	}()

	public lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
		var coordinator: NSPersistentStoreCoordinator? = nil
		var error: NSError? = nil

		var managedObjectModel = self.managedObjectModel
		if (managedObjectModel != nil) {

			do {
				coordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel!)
				let options = [NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption: true];
				let store = try coordinator?.addPersistentStore(ofType: NSSQLiteStoreType,
							configurationName:nil, at:self.fileURL, options:options)
				if store == nil {
					#if DEBUG
					do {
						print("ZManagedObjectStorage: Failed migrating Core Data Model. Old storage will be deleted in debug build.")
						print("  file: \(self.fileURL.path)")
						try FileManager.default.removeItem(at: self.fileURL)
						// recreate store file once again
						try coordinator?.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: self.fileURL, options: options)
					}
					catch { print(error) }
					#endif
				}
			}
			catch { print("ZManagedObjectStorage: \(error)\r  file: \(self.fileURL.path)") }
		}
		if coordinator == nil {
			print("ZManagedObjectStorage: Failed to configure persistent store coodinator:\r  file: \(self.fileURL.path)")
		}
		return coordinator
	}()

	public lazy var managedObjectContext: NSManagedObjectContext? = {
		var context: NSManagedObjectContext? = nil
		let coordinator = self.persistentStoreCoordinator
		if coordinator != nil {
			context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
			context?.persistentStoreCoordinator = self.persistentStoreCoordinator
		}
		return context
	}()

}
