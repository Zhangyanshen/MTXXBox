//
//  MBoxCommand.swift
//  MTXXBox
//
//  Created by zhangyanshen on 2022/4/26.
//

import Foundation
import SwiftShell
import SwiftyJSON

typealias StdOutHandler = (String) -> Void
typealias StdErrorHandler = (String) -> Void
typealias CompleteHandler = (Bool) -> Void

class MBoxCommand {
    static let sharedInstance = MBoxCommand()
    
    private let outRegexPattern = "\\[[0-9]+m"
    private let defaultPrefix = "feature"
    var workDir: String?
    
    enum StatusInfo: String {
        case all = ""
        case feature = "feature"
        case repos = "repos"
        case containers = "containers"
    }
    
    private var ctx: CustomContext {
        var cleanctx = CustomContext(main)
        cleanctx.env["LANG"] = "en_US.UTF-8"
        if workDir != nil {
            cleanctx.currentdirectory = workDir!
        }
        cleanctx.env["PATH"] = "\(main.env["HOME"]!)/.rvm/rubies/default/bin:\(main.env["HOME"]!)/.rvm/gems/default/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:"
        return cleanctx
    }
    
    init() {}
    
    // MARK: - Public methods
    
    func workspace(of path: String) -> (Workspace?, String?) {
        workDir = path
        
        if !FileManager.default.fileExists(atPath: path) {
            return (nil, "目录`\(path)`不存在")
        }
        
        // Feature列表
        let (featureList, featureListErr) = self.listFeature()
        if featureListErr != nil {
            return (nil, featureListErr)
        }
        let featureJson = JSON(parseJSON: featureList!)
        let features = Array(featureJson.dictionaryValue.keys)
        
        // Workspace status
        let (status, statusErr) = self.status()
        if statusErr != nil {
            return (nil, statusErr)
        }
        let statusJson = JSON(parseJSON: status!)
        
        let workspace = Workspace(statusJson, features: features)
        
        return (workspace, nil)
    }
    
    // 切换Container
    func changeContainer(_ container: String) -> ([Repo]?, String?) {
        // 执行 mbox container use xxx
        let (_, err1) = self.activeContainer(container)
        if err1 != nil {
            return (nil, err1)
        }
        let (repos, err2) = self.status(of: .repos)
        if err2 != nil {
            return (nil, err2)
        }
        let reposJson = JSON(parseJSON: repos!)
        let pods = reposJson["repos"].arrayValue.map { Repo($0) }
        // 执行 pod install
        let (_, podErr) = podInstall()
        if podErr != nil {
            return (nil, podErr!)
        }
        return (pods, nil)
    }
    
    func createWorkspace(of path: String) -> (String?, String?) {
        self.run(bash: "mbox init ios")
    }
    
    // MARK: - Status
    
    func status(of info: StatusInfo = .all) -> (String?, String?) {
        var command = "mbox status"
        if info != .all {
            command.append(contentsOf: " --only=\(info.rawValue)")
        }
        return self.run(bash: command)
    }
    
    // MARK: - Component
    
    func active(component: String) -> (String?, String?) {
        run(bash: "mbox activate \(component)")
    }
    
    func deactive(component: String) -> (String?, String?) {
        run(bash: "mbox deactivate \(component)")
    }
    
    // MARK: - Repo
    
    func addRepo(_ url: String, branch: String) -> (String?, String?) {
        self.run(bash: "mbox add \(url) \(branch)")
    }
    
    func deleteRepo(_ repo: String) -> (String?, String?) {
        run(bash: "mbox remove \(repo)")
    }
    
    // MARK: - Feature
    
    func listFeature() -> (String?, String?) {
        self.run(bash: "mbox feature list")
    }
    
    func startFeature(_ feature: String) -> (String?, String?) {
        var command = "mbox feature start \(feature)"
        if feature == "FreeMode" {
            command = "mbox feature free"
        }
        return self.run(bash: command)
    }
    
    func createFeature(_ feature: String, prefix: String? = nil) -> (String?, String?) {
        var command = "mbox feature start \(feature)"
        if prefix != nil {
            command += " --prefix=\(prefix!)"
        }
        return self.run(bash: command)
    }
    
    func exportFeature() -> (String?, String?) {
        self.run(bash: "mbox feature export", format: false)
    }
    
    func importFeature(_ feature: String,
                       keepChanges: Bool,
                       checkBranchExists: Bool,
                       recurseSubmodules: Bool) -> (String?, String?)
    {
        var command = "mbox feature import '\(feature)'"
        if keepChanges {
            command += " --keep-changes"
        }
        if checkBranchExists {
            command += " --check-branch-exists"
        }
        if recurseSubmodules {
            command += " --recurse-submodules"
        }
        return self.run(bash: command)
    }
    
    func deleteFeature(_ feature: String,
                       includeRepo: Bool,
                       force: Bool) -> (String?, String?)
    {
        var command = "mbox feature remove \(feature)"
        if includeRepo {
            command += " --include-repo"
        }
        if force {
            command += " --force"
        }
        return self.run(bash: command)
    }
    
    // MARK: - Container
    
    func listContainers() -> (String?, String?) {
        self.run(bash: "mbox status --only=containers")
    }
    
    func activeContainer(_ container: String) -> (String?, String?) {
        self.run(bash: "mbox container use \(container)", format: false)
    }
    
    // MARK: - Install
    
    func podInstall() -> (String?, String?) {
        self.run(bash: "mbox pod install")
    }
    
    func podInstallAsync(stdout: @escaping StdOutHandler,
                         stderror: @escaping StdErrorHandler,
                         complete: @escaping CompleteHandler)
    {
        self.runAsync(bash: "mbox pod install",
                      format: false,
                      stdoutHandler: stdout,
                      stderrorHandler: stderror,
                      complete: complete)
    }
    
    func bundleInstall() -> (String?, String?) {
        self.run(bash: "mbox bundle install")
    }
    
    func bundleInstallAsync(stdout: @escaping StdOutHandler,
                            stderror: @escaping StdErrorHandler,
                            complete: @escaping CompleteHandler)
    {
        self.runAsync(bash: "mbox bundle install",
                      format: false,
                      stdoutHandler: stdout,
                      stderrorHandler: stderror,
                      complete: complete)
    }
    
    // MARK: - Go
    
    func mboxGo() -> (String?, String?) {
        self.run(bash: "mbox go")
    }
    
    // MARK: - Git
    
    func gitFetch() -> (String?, String?) {
        self.run(bash: "mbox git fetch -v", format: false)
    }
    
    func gitFetchAsync(_ stdout: @escaping StdOutHandler,
                       stderror: @escaping StdErrorHandler,
                       complete: @escaping CompleteHandler)
    {
        self.runAsync(bash: "mbox git fetch origin -v",
                      format: false,
                      stdoutHandler: stdout,
                      stderrorHandler: stderror,
                      complete: complete)
    }
    
    func gitPull(of branch: String) -> (String?, String?) {
        self.run(bash: "git pull origin \(branch)", format: false)
    }
    
    func gitPullAsync(of branch: String,
                      stdout: @escaping StdOutHandler,
                      stderror: @escaping StdErrorHandler,
                      complete: @escaping CompleteHandler)
    {
        self.runAsync(bash: "git pull origin \(branch)",
                      format: false,
                      stdoutHandler: stdout,
                      stderrorHandler: stderror,
                      complete: complete)
    }
    
    func gitStash(for path: String) -> (String?, String?) {
        self.run(bash: "git add \(path)", format: false)
    }
    
    func gitStashAll() -> (String?, String?) {
        self.run(bash: "mbox git add --all", format: false)
    }
    
    func gitUnstash(for path: String) -> (String?, String?) {
        self.run(bash: "git restore --staged \(path)", format: false)
    }
    
    func gitUnstashAll() -> (String?, String?) {
        self.run(bash: "mbox git restore --staged", format: false)
    }
    
    func gitCommit(_ msg: String) -> (String?, String?) {
        self.run(bash: "mbox git commit -m '\(msg)'", format: false)
    }
    
    func gitCommitAsync(_ msg: String,
                        stdout: @escaping StdOutHandler,
                        stderror: @escaping StdErrorHandler,
                        complete: @escaping CompleteHandler)
    {
        self.runAsync(bash: "mbox git commit -m '\(msg)'",
                      format: false,
                      stdoutHandler: stdout,
                      stderrorHandler: stderror,
                      complete: complete)
    }
    
    func gitPush(of branch: String) -> (String?, String?) {
        self.run(bash: "git push -u origin \(branch)", format: false)
    }
    
    func gitPushAsync(of branch: String,
                      stdout: @escaping StdOutHandler,
                      stderror: @escaping StdErrorHandler,
                      complete: @escaping CompleteHandler)
    {
        self.runAsync(bash: "git push -u origin \(branch)",
                      format: false,
                      stdoutHandler: stdout,
                      stderrorHandler: stderror,
                      complete: complete)
    }
    
    // MARK: - 环境检查
    
    func checkGit() -> (String?, String?) {
        self.run(bash: "which git", format: false)
    }
    
    func checkMBox() -> (String?, String?) {
        self.run(bash: "which mbox", format: false)
    }
    
    // MARK: -
    
    func openInFinder() -> (String?, String?) {
        guard let workDir = self.workDir else { return (nil, "工作目录为空") }
        return self.run(bash: "open \(workDir)", format: false)
    }
    
    func openInTerminal() -> (String?, String?) {
        guard let workDir = self.workDir else { return (nil, "工作目录为空") }
        let script = """
        tell application \"Terminal\"
            activate
            do script \"cd \(workDir)\"
        end tell
        """
        return self.run(bash: "osascript -e '\(script)'", format: false)
    }
    
    // MARK: - Private methods
    
    private func run(bash: String, format: Bool = true) -> (String?, String?) {
        var command = bash
        if format {
            command.append(" --api=json")
        }
        let output = ctx.run(bash: command)
        if output.succeeded {
            return (output.stdout, nil)
        }
        debugPrint(output.stderror)
        let outputError = output.stderror.regexReplace(with: outRegexPattern)
        return (nil, outputError)
    }
    
    private func runAsync(bash: String,
                          format: Bool = true,
                          stdoutHandler: @escaping (String) -> Void = {_ in },
                          stderrorHandler: @escaping (String) -> Void = {_ in },
                          complete: @escaping (Bool) -> Void = {_ in })
    {
        var formatBash = bash
        if format {
            formatBash.append(" --api=json")
        }
        let result = ctx.runAsync(bash: formatBash).onCompletion { command in
            complete(command.exitcode() == 0)
        }
        result.stdout.onStringOutput { stdoutHandler($0.regexReplace(with: self.outRegexPattern)) }
        result.stderror.onStringOutput { stderrorHandler($0.regexReplace(with: self.outRegexPattern)) }
    }
}
