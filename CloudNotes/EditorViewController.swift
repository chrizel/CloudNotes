//
//  EditorViewController.swift
//  CloudNotes
//
//  Created by Peter Hedlund on 1/26/20.
//  Copyright © 2020 Peter Hedlund. All rights reserved.
//

import Cocoa
import Notepad

class EditorViewController: NSViewController {

    @IBOutlet var topView: NSView!
    @IBOutlet var noteView: NSTextView!

    @IBOutlet var shareButton: NSButton!
    @IBOutlet var favoriteButton: NSButton!
    
    let storage = Storage()
    
    var note: CDNote? {
        didSet {
            if note != oldValue, let note = note {
                noteView.string = ""
                //                HUD.show(.progress)
                NoteSessionManager.shared.get(note: note, completion: { [weak self] in
                    self?.updateTextView()
                    self?.noteView.string = note.content
                    self?.noteView.undoManager?.removeAllActions()
                    self?.noteView.scrollRangeToVisible(NSRange(location: 0, length: 0))
                    //                    self?.updateHeaderLabel()
                    //                    HUD.hide()
                })
            } else {
                updateTextView()
            }
        }
    }

    private var editingTimer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()
        topView.wantsLayer = true
        let border: CALayer = CALayer()
        border.autoresizingMask = .layerWidthSizable;
        border.frame = CGRect(x: 0,
                              y: 1,
                              width: topView.frame.width,
                              height: 1)
        border.backgroundColor = NSColor.gridColor.cgColor
        topView.layer?.addSublayer(border)
        noteView.delegate = self
        let theme = Theme("one-light")
        ///theme.backgroundColor = NSColor.controlBackgroundColor
        storage.theme = theme
        noteView.backgroundColor = theme.backgroundColor
        noteView.insertionPointColor = theme.tintColor
        noteView.layoutManager?.replaceTextStorage(storage)
        noteView.textContainerInset = NSSize(width: 10, height: 10)
        updateTextView()
    }
    
    @IBAction func onShare(_ sender: Any) {
    }
    
    @IBAction func onFavorite(_ sender: Any) {
        if let note = note {
            let currentState = note.favorite
            note.favorite = !currentState
            if note.favorite {
                favoriteButton.image = NSImage(named: "starred_mac")
            } else {
                favoriteButton.image = NSImage(named: "unstarred_mac")
            }
            NoteSessionManager.shared.update(note: note) {
                NotificationCenter.default.post(name: .editorUpdatedNote, object: note)
            }
        }
    }
    
    private func updateTextView() {
        if let note = note {
            noteView.string = note.content;
            noteView.isEditable = true
            noteView.isSelectable = true
            favoriteButton.isEnabled = true
            if note.favorite {
                favoriteButton.image = NSImage(named: "starred_mac")
            } else {
                favoriteButton.image = NSImage(named: "unstarred_mac")
            }
            shareButton.isEnabled = false //TODO set to true once implemented
        } else {
            noteView.isEditable = false
            noteView.isSelectable = false
            noteView.string = NSLocalizedString("Select or create a note.", comment: "Placeholder text when no note is selected")
            favoriteButton.isEnabled = false
            shareButton.isEnabled = false
        }
    }

}

extension EditorViewController: NSTextViewDelegate {
    
    fileprivate func updateNoteContent() {
        if let note = self.note, self.noteView.string != note.content {
            note.content = self.noteView.string
            NoteSessionManager.shared.update(note: note) {
                NotificationCenter.default.post(name: .editorUpdatedNote, object: note)
            }
        }
    }

    func textDidChange(_ notification: Notification) {
//        self.activityButton.isEnabled = textView.text.count > 0
//        self.addButton.isEnabled = textView.text.count > 0
//        self.previewButton.isEnabled = textView.text.count > 0
//        self.deleteButton.isEnabled = true
        if editingTimer != nil {
            editingTimer?.invalidate()
            editingTimer = nil
        }
        editingTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: false, block: { [weak self] _ in
            self?.updateNoteContent()
        })
    }
    
}
