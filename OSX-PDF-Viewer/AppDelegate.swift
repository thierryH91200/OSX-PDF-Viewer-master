    //
    //  AppDelegate.swift
    //  OSX-PDF-Viewer
    //
    //  Created by Patrick Skinner 💯 and Cassidy Mowat 🔥 on 9/27/16.
    //  Copyright © 2016 Patrick Skinner. All rights reserved.
    //

import Cocoa
import Quartz

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    @IBOutlet weak var startWindow: NSWindow!
    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var ourPDF: PDFView!
    @IBOutlet weak var thumbs: PDFThumbnailView!
    @IBOutlet weak var pageNum: NSTextField!
    @IBOutlet weak var pdfSelector: NSPopUpButton!
    @IBOutlet weak var textField: NSTextField!
    @IBOutlet weak var bookmarkSelector: NSPopUpButton!
    @IBOutlet weak var saveBookmark: NSButton!
    @IBOutlet weak var bookmarkTitle: NSTextField!
    
    @IBOutlet weak var startOpenDocument: NSButton!
    @IBOutlet weak var startPopUp: NSPopUpButton!
    
    var pdf: PDFDocument!
    
    var searchValue: Int = 0
    
    var selection: [PDFSelection] = [PDFSelection]()
    var urls: [URL] = [URL]()
    
    var notes = [String: String]()
    var bookmarks = [String: [String]]()
    var recentDocuments = [String]()
    
    
        //////////////////////////////////
        //          StartWindow         //
        //////////////////////////////////
    @IBAction func openRecent(_ sender: Any) {
        let list: NSPopUpButton = sender as! NSPopUpButton
        
        if (list.titleOfSelectedItem != "Recent Documents"){
            openByIndex(index: list.indexOfSelectedItem + 1, recentflag: true)
            
            self.window.setIsVisible(true)
            self.startWindow.setIsVisible(false)
            
            self.ourPDF.document = (self.pdf)
            self.ourPDF.autoScales = true
            
            var thumbSize: NSSize = NSSize()
            thumbSize.width = 120
            thumbSize.height = 200
            self.thumbs.thumbnailSize = thumbSize
            self.thumbs.pdfView = self.ourPDF
            
            
            self.bookmarkSelector.removeAllItems()
            self.bookmarkSelector.addItem(withTitle: "Select Bookmark")
            
            for (key, array) in self.bookmarks {
                if(array[1] == pdf.documentURL!.absoluteString){
                    self.bookmarkSelector.addItem(withTitle: key)
                }
            }
            
            self.ourPDF.layoutDocumentView()
            self.pdfSelector.selectItem(at: 0)
            self.notePageUpdated()
        }
    }
    
        //Create a openPanel to select one or more PDFs to display
    @IBAction func Open(_ sender: Any) {
        
        let defaults = UserDefaults.standard
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = true
        openPanel.canChooseDirectories = false
        openPanel.canCreateDirectories = false
        openPanel.canChooseFiles = true
        openPanel.allowedFileTypes = ["pdf"]
        openPanel.begin { (result) -> Void in
            if result.rawValue == NSFileHandlingPanelOKButton {
                for url in openPanel.urls{
                    self.urls.append(url)
                    if (self.recentDocuments.count < 6){
                        self.recentDocuments.append(url.absoluteString)
                        
                        defaults.set(self.recentDocuments, forKey: "recentDictionaryKey")
                    } else {
                        for item in self.recentDocuments{
                            if self.recentDocuments.firstIndex(of: item)! > 0 {
                                self.recentDocuments[self.recentDocuments.firstIndex(of: item)! - 1] = item
                            }
                        }
                        self.recentDocuments.insert(url.absoluteString, at: self.recentDocuments.count)
                        defaults.set(self.recentDocuments, forKey: "recentDictionaryKey")
                    }
                    
                }
                
                self.pdf = PDFDocument(url: self.urls[self.urls.endIndex-1])
                self.ourPDF.document = self.pdf
                self.ourPDF.autoScales = true
                
                var thumbSize: NSSize = NSSize()
                thumbSize.width = 120
                thumbSize.height = 200
                self.thumbs.thumbnailSize = thumbSize
                self.thumbs.pdfView = self.ourPDF
                
                let dict: Dictionary = self.pdf.documentAttributes!
                
                if (dict[PDFDocumentAttribute.titleAttribute] != nil ) {
                    self.window.title = dict[PDFDocumentAttribute.titleAttribute] as! String
                } else if(self.urls[self.urls.endIndex-1].lastPathComponent != nil){
                    self.window.title = self.urls[self.urls.endIndex-1].lastPathComponent
                }
                
                for document in self.urls{
                    self.pdfSelector.addItem(withTitle: document.lastPathComponent)
                }
                self.pdfSelector.selectItem(at: self.urls.endIndex-1)
                
                self.bookmarkSelector.removeAllItems()
                self.bookmarkSelector.addItem(withTitle: "Select Bookmark")
                
                for (_, array) in self.bookmarks {
                    if(array[1] == self.pdf.documentURL?.absoluteString){
                        self.bookmarkSelector.addItem(withTitle: array[2])
                    }
                }
                
                self.ourPDF.layoutDocumentView()
                
                self.notePageUpdated()
                
                self.window.setIsVisible(true)
                self.startWindow.setIsVisible(false)
                
            }
        }
    }
    
        //Create all the needed observers and load all persistent data.
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        window.contentMinSize = NSSize(width: 700, height: 700)
        
        NotificationCenter.default.addObserver(self, selector: #selector(updatePageNum), name: NSNotification.Name.PDFViewPageChanged, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(noteUpdated), name: NSText.didChangeNotification, object: nil)
        
        let defaults = UserDefaults.standard
        if let noteDictionary = defaults.dictionary(forKey: "noteDictionaryKey"){
            notes = noteDictionary as! [String: String]
        }
        
        if let bookmarkDictionary = defaults.dictionary(forKey: "bookmarkDictionaryKey"){
            bookmarks = bookmarkDictionary as! [String: [String]]
        }
        
        if let recentDictionary = defaults.array(forKey: "recentDictionaryKey"){
            recentDocuments = recentDictionary as! [String]
        }
        
        self.startPopUp.removeAllItems()
        self.bookmarkSelector.removeAllItems()
        self.pdfSelector.removeAllItems()
        
        self.bookmarkSelector.addItem(withTitle: "Select Bookmark")
        self.startPopUp.addItem(withTitle: "Recent Documents")
        
        for item in self.recentDocuments{
            self.startPopUp.addItem(withTitle: (URL(fileURLWithPath: item).deletingPathExtension().lastPathComponent))
        }
        
            // DEBUG LINE CLEAR RECENT
        
            //defaults.setObject([String](), forKey: "recentDictionaryKey")
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
    }
    
    
        //////////////////////////////////
        //        Zoom Functions        //
        //////////////////////////////////
    
    @IBAction func zoomIn(_ sender: Any) {
        ourPDF.autoScales = false
        ourPDF.zoomIn(sender)
    }
    
    @IBAction func zoomOut(_ sender: Any) {
        ourPDF.autoScales = false
        ourPDF.zoomOut(sender)
    }
    
    @IBAction func scale(_ sender: Any) {
        ourPDF.autoScales = true
    }
    
        //////////////////////////////////
        //        Page Navigation       //
        //////////////////////////////////
    
    @IBAction func previousPage(_ sender: Any) {
        if (ourPDF.canGoToPreviousPage) {
            ourPDF.goToPreviousPage(sender)
        }
    }
    
    @IBAction func nextPage(_ sender: Any) {
        if ourPDF.canGoToNextPage {
            ourPDF.goToNextPage(sender)
        }
    }
    
    @IBAction func jumpToPage(_ sender: Any){
        if(Int(pageNum.stringValue) != nil && ourPDF != nil){
            ourPDF.go(to: pdf.page(at: Int(pageNum.stringValue)!-1)!)
        }
    }
    
    @objc func updatePageNum(){
        pageNum.stringValue = (ourPDF.currentPage?.label)!
        notePageUpdated()
    }
    
        //////////////////////////////////
        //      Searching Functions     //
        //////////////////////////////////
    
    @IBAction func search(_ sender: Any){
        let search = sender as? NSTextField
        if(ourPDF != nil && pdf != nil){
            let searchString = search?.stringValue
            if searchString?.isEmpty == false {
                selection = pdf.findString(searchString!, withOptions: NSString.CompareOptions.caseInsensitive)
                
                if (!selection.isEmpty) {
                    ourPDF.go(to: selection[searchValue] )
                    
                    for item in selection {
                        item.color = NSColor(red: 0, green: 0, blue: 0.6, alpha: 0.6)
                    }
                    selection[searchValue].color = NSColor(red: 0.6, green: 0, blue: 0, alpha: 0.6)
                    ourPDF.highlightedSelections = selection
                }
            } else {
                selection.removeAll()
                ourPDF.highlightedSelections = nil
            }
        }
    }
    
    @IBAction func searchBack(_ sender: Any){
        if(searchValue != 0){
            if (!selection.isEmpty){
                selection[searchValue].color = NSColor(red: 0, green: 0, blue: 0.6, alpha: 0.6)
                
                searchValue -= 1
                
                goToSelection()
            }
        } else {
            if (!selection.isEmpty){
                selection[searchValue].color = NSColor(red: 0, green: 0, blue: 0.6, alpha: 0.6)
                
                searchValue = selection.count - 1
                
                goToSelection()
            }
        }
    }
    
    @IBAction func searchforward(_ sender: Any){
        if(searchValue == (selection.count - 1)){
            if (!selection.isEmpty){
                selection[searchValue].color = NSColor(red: 0, green: 0, blue: 0.6, alpha: 0.6)
                
                searchValue = 0
                goToSelection()
            }
        } else {
            if (!selection.isEmpty){
                selection[searchValue].color = NSColor(red: 0, green: 0, blue: 0.6, alpha: 0.6)
                
                searchValue += 1
                
                goToSelection()
            }
        }
    }
    
    func goToSelection(){
        ourPDF.go(to: selection[searchValue] )
        
        selection[searchValue].color = NSColor(red: 0.6, green: 0, blue: 0, alpha: 0.6)
        ourPDF.highlightedSelections = selection
    }
    
        //////////////////////////////////
        // Document Selection Functions //
        //////////////////////////////////
    
    @IBAction func selectPDF(_ sender: Any) {
        
        let list = sender as! NSPopUpButton
        
        openByIndex(index: list.indexOfSelectedItem, recentflag: false)
        
        self.bookmarkSelector.removeAllItems()
        self.bookmarkSelector.addItem(withTitle: "Select Bookmark")
        
        for (key, array) in self.bookmarks {
            if(array[1] == pdf.documentURL!.absoluteString){
                self.bookmarkSelector.addItem(withTitle: key)
            }
        }
        
    }
    
    @IBAction func goBackDocument(_ sender: Any){
        if(ourPDF != nil && urls.count > 1){
            var index = urls.firstIndex(of: pdf.documentURL!)
            
            if(index == 0){
                index = urls.count - 1
            } else {
                index = index! - 1
            }
            
            openByIndex(index: index!, recentflag: false)
        }
    }
    
    @IBAction func goForwardDocument(_ sender: Any){
        if(ourPDF != nil && urls.count > 1){
            var index = urls.firstIndex(of: pdf.documentURL!)
            
            if(index == urls.count - 1){
                index = 0
            } else {
                index = index! + 1
            }
            
            openByIndex(index: index!, recentflag: false)
            
        }
    }
    
    func openByIndex(index: Int, recentflag: Bool){
        if(recentflag){
            urls.append( URL(string: recentDocuments[index-2])!)
            self.pdf = PDFDocument(url: URL(string: recentDocuments[index-2])!)
            
            self.ourPDF.document = self.pdf
            
            let dict: Dictionary = self.pdf.documentAttributes!
            if(dict[PDFDocumentAttribute.titleAttribute] != nil) {
                self.window.title = dict[PDFDocumentAttribute.titleAttribute] as! String
            } else if(NSURL(fileURLWithPath: recentDocuments[index-2]).lastPathComponent != nil){
                self.window.title = NSURL(fileURLWithPath: recentDocuments[index-2]).lastPathComponent!
            }
            
//            self.pdfSelector.addItemWithTitle(         self.pdf.documentURL?.lastPathComponent!)
            self.pdfSelector.addItem         (withTitle: self.pdf.documentURL!.lastPathComponent)

            self.pdfSelector.selectItem(at: 0)
        } else {
            self.pdf = PDFDocument(url: urls[index])
            
            self.ourPDF.document = self.pdf
            
            let dict: Dictionary = self.pdf.documentAttributes!
            if (dict[PDFDocumentAttribute.titleAttribute] != nil) {
                self.window.title = dict[PDFDocumentAttribute.titleAttribute] as! String
            } else
            if self.urls[index].lastPathComponent != nil {
                self.window.title = self.urls[index].lastPathComponent
            }
            
            pdfSelector.selectItem(at: index)
        }
        
        updatePageNum()
        notePageUpdated()
        
        self.bookmarkSelector.removeAllItems()
        self.bookmarkSelector.addItem(withTitle: "Select Bookmark")
        
        for (key, array) in self.bookmarks {
            if array[1] == pdf.documentURL?.absoluteString {
                self.bookmarkSelector.addItem(withTitle: key)
            }
        }
    }
    
    
    
        //////////////////////////////////
        //     Note Taking Functions    //
        //////////////////////////////////
    
    @objc func noteUpdated(){
        if(pdf != nil){
            let noteKey = (ourPDF.currentPage?.label)! + (pdf!.documentURL?.deletingPathExtension().lastPathComponent)!
            notes[noteKey] = textField.stringValue
        }
        
        let defaults = UserDefaults.standard
        defaults.set(notes, forKey: "noteDictionaryKey")
    }
    
    func notePageUpdated(){
        let noteKey = (ourPDF.currentPage?.label)! + (pdf!.documentURL?.deletingPathExtension().lastPathComponent)!
        if(notes[noteKey] == nil){
            textField.stringValue = ""
        } else {
            textField.stringValue = notes[noteKey]!
        }
    }
    
        //////////////////////////////////
        //      Bookmark Functions      //
        //////////////////////////////////
    
    @IBAction func bookmarkSave(_ sender: Any) {
        if(pdf != nil){
            let docUrl = (pdf!.documentURL?.absoluteString)
            if (bookmarkTitle.stringValue != "") {
                
//                bookmarks[bookmarkTitle.stringValue] = [ourPDF.currentPage.label, docUrl, bookmarkTitle.stringValue]
//                bookmarkSelector.addItem(withTitle: bookmarkTitle.stringValue)
//                bookmarkTitle.stringValue = ""
                let defaults = UserDefaults.standard
                defaults.set(bookmarks, forKey: "bookmarkDictionaryKey")
            }
        }
    }
    
    
    @IBAction func bookmarkSelect(sender: AnyObject) {
        let list: NSPopUpButton = sender as! NSPopUpButton
        
        if (list.titleOfSelectedItem != "Select Bookmark"){
            let bookmarkname = list.titleOfSelectedItem
            let pageString = bookmarks[bookmarkname!]
            
            let pageNum = Int(pageString![0])
            
            
            ourPDF.go(to: pdf.page(at: pageNum! - 1)!)
        }
        
    }
    
    
    
}

