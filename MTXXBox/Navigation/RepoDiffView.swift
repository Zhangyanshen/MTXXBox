//
//  RepoDiffView.swift
//  MTXXBox
//
//  Created by zhangyanshen on 2022/5/10.
//

import SwiftUI
import ObjectiveGit
import WebKit

// Diff类型
public enum DiffType {
    case indexToWorkDir  // Index -> Working Directory
    case headToIndex  // HEAD -> Index
}

struct RepoDiffView: View {
    var gitRepo: GTRepository
    var filePath: String
    var statusDelta: GTStatusDelta
    var diffType: DiffType = .indexToWorkDir
    
    @State private var diffContent: String = ""
    
    var body: some View {
        VStack {
            LocalWebView(htmlContent: diffContent,
                         htmlDir: Bundle.main.url(forResource: "html", withExtension: nil))
        }
        .onAppear {
            gitDiff()
        }
    }
    
    private var diffHtmlTemplate: String? {
        guard let htmlURL = Bundle.main.url(forResource: "diff", withExtension: "html", subdirectory: "html") else { return nil }
        return try? String(contentsOf: htmlURL)
    }
    
    // HEAD与Index的diff
    private var headToIndexDiff: GTDiff? {
        let objPointer = UnsafeMutablePointer<OpaquePointer?>.allocate(capacity: 0)
        git_revparse_single(objPointer, gitRepo.git_repository(), "HEAD^{tree}")
        
        guard let obj = objPointer.pointee else { return nil }
        
        let treePointer = UnsafeMutablePointer<OpaquePointer?>.allocate(capacity: 0)
        git_tree_lookup(treePointer, gitRepo.git_repository(), git_object_id(obj))
        
        guard let tree = treePointer.pointee else { return nil }
        
        let diffPointer = UnsafeMutablePointer<OpaquePointer?>.allocate(capacity: 0)
        git_diff_tree_to_index(diffPointer, gitRepo.git_repository(), tree, nil, nil)
        
        guard let diff = diffPointer.pointee else { return nil }
        
        return GTDiff.init(gitDiff: diff, repository: gitRepo)
    }
    
    // Index与Working Directory的diff
    private var indexToWorkDirDiff: GTDiff? {
        try? GTDiff(indexToWorkingDirectoryIn: gitRepo, options: nil)
    }
    
    private var diff: GTDiff? {
        var diff = indexToWorkDirDiff
        if diffType == .headToIndex {
            diff = headToIndexDiff
        }
        return diff
    }
    
    // MARK: - Private methods
    
    private func gitDiff() {
        guard let diff = self.diff else { return }
        guard let diffHtmlTemplate = diffHtmlTemplate else { return }
        let oid = statusDelta.newFile?.oid ?? statusDelta.oldFile?.oid ?? GTOID(sha: "")
        print("DiffDeltaCount:\(diff.deltaCount)")
        diff.enumerateDeltas { diffDelta, stop in
            let diffDeltaOid = diffDelta.newFile?.oid ?? diffDelta.oldFile?.oid ?? GTOID(sha: "")
            if oid != diffDeltaOid {
                return
            }
            
//            let diffDeltaPath = diffDelta.oldFile?.path ?? diffDelta.newFile?.path ?? ""
//            if filePath != diffDeltaPath {
//                return
//            }
            print("开始DiffDelta")
            print("type:\(diffDelta.type)")
            do {
                let diffPatch = try diffDelta.generatePatch()
                print("HunkCount:\(diffPatch.hunkCount)")
                var textLines = [String]()
                var hunkIndex = 0
                diffPatch.enumerateHunks { diffHunk, stop in
                    print("开始DiffHunk")
                    hunkIndex += 1
                    textLines.append(hunkHeader(at: hunkIndex))
                    textLines.append("<div class='hunk'>")
                    try? diffHunk.enumerateLinesInHunk { diffLine, stop in
                        print("开始DiffLine")
                        print("oldLine: \(diffLine.oldLineNumber)")
                        print("newLine: \(diffLine.newLineNumber)")
                        let line = hunkLine(diffLine.content,
                                            oldLineNum: diffLine.oldLineNumber,
                                            newLineNum: diffLine.newLineNumber)
                        textLines.append(line)
                        print("结束DiffLine")
                    }
                    textLines.append("</div>")
                    print("结束DiffHunk")
                }
                let diffStr = textLines.joined(separator: "\n")
                let diffContent = diffHtmlTemplate.replacingOccurrences(of: "%@", with: diffStr)
                self.diffContent = diffContent
            } catch {
                print("生成DiffPatch失败：\(error)")
            }
            print("结束DiffDelta\n")
        }
    }
    
    private func hunkHeader(at index: Int) -> String {
        return """
        <div class='hunkhead'>
            <span class='place'></span>
            <span class='place'></span>
            <span class='text'>块\(index)</span>
        </div>
        """
    }
    
    private func hunkLine(_ line: String,
                          oldLineNum: Int,
                          newLineNum: Int) -> String
    {
        var className = "pln"
        var oldLineText = ""
        var newLineText = ""
        let escaped = line.xmlEscaped
        // 新增行
        if oldLineNum == -1 {
            className = "add"
        } else {
            oldLineText = "\(oldLineNum)"
        }
        // 删除行
        if newLineNum == -1 {
            className = "del"
        } else {
            newLineText = "\(newLineNum)"
        }
        return """
        <div class='\(className)'>
            <span class='old' line='\(oldLineText)'></span>
            <span class='new' line='\(newLineText)'></span>
            <span class='text'>\(escaped)</span>
        </div>
        """
    }
}

//struct RepoDiffView_Previews: PreviewProvider {
//    static var previews: some View {
//        RepoDiffView()
//    }
//}
