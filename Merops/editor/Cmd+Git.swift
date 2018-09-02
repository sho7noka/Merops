//
//  GITobject.swift
//
//  Created by sumioka-air on 2017/03/26.
//  Copyright © 2017年 sho sumioka. All rights reserved.
//


#if os(OSX)
import Cocoa
#elseif os(iOS)
import UIKit
#endif
import ObjectiveGit

/// - Tag: libgit
func gitInit(dir: String) {
    do {
        try GTRepository.initializeEmpty(
                atFileURL: URL(fileURLWithPath: dir), options: nil
        )
    } catch {
        print(error)
    }
}

func gitClone(url: String, dir: String) {
    do {
        try GTRepository.clone(from: URL(string: url)!,
                toWorkingDirectory: URL(fileURLWithPath: dir),
                options: nil, transferProgressBlock: nil
        )
    } catch {
        print(error)
    }
}

func gitCommit(url: String, msg: String = "update") {
    do {
        let repo = try GTRepository.init(
                url: URL(fileURLWithPath: url).deletingLastPathComponent(), flags: 0, ceilingDirs: []
        )
        let index = try repo.index()

        // MARK: add all
        let manager = FileManager.default
        let list = try manager.contentsOfDirectory(atPath: URL(fileURLWithPath: url).deletingLastPathComponent().path)
        try list.forEach {
            if ($0.starts(with: ".") == false) {
                try index.addFile($0)
            }
        }
        let tree = try index.writeTree(to: repo)
        
        try repo.createCommit(with: tree,
                              message: msg,
                              parents: nil, updatingReferenceNamed: "HEAD")
    } catch {
        print(error)
    }
}

func gitRevert(url: String) {
    do {
        let repo = try GTRepository.init(
                url: URL(fileURLWithPath: url).deletingLastPathComponent(), flags: 0, ceilingDirs: []
        )
        let commits = try repo.localCommitsRelative(toRemoteBranch: repo.currentBranch())
        commits.forEach {
            git_revert(repo.git_repository(), $0.git_commit(), nil) //repo.reset(to: , resetType: .hard)
        }
    } catch {
        print(error)
    }
}

func gitStatus(dir: String) {
    do {
        let manager = FileManager.default
        let list = try manager.contentsOfDirectory(atPath: dir)
        try list.forEach {
            if ($0.hasPrefix(".git") == false) {
                let status = try GTRepository(url: URL(fileURLWithPath: dir))
                        .status(forFile: $0, success: nil, error: nil)
                print(status)
            }
        }
    } catch {
        print(error)
    }
}

func gitDiff(url: String) {
    do {
        let repo = try GTRepository(url: URL(fileURLWithPath: url))
        let diff = try GTDiff(workingDirectoryToHEADIn: repo, options: nil)
        diff.enumerateDeltas({ delta, _ in
            print(delta.oldFile?.path as Any, delta.newFile?.path as Any)
        })
    } catch {
        print(error)
    }
}

func gitMerge(url: String) {
    do {
        let repo = try GTRepository(url: URL(fileURLWithPath: url))
        try repo.mergeBranch(intoCurrentBranch: repo.currentBranch())
    } catch {
        print(error)
    }
}

func gitBranch(url: String) {
    do {
        let repo = try GTRepository(url: URL(fileURLWithPath: url))
        try repo.branches().forEach {
            try print(repo.currentBranch(), $0.repository.configuration(), $0.repository.headReference(),
                    $0.description, $0.name!, $0.shortName!, $0.repository)
        }
    } catch {
        print(error)
    }
}

//        let parents = [targetCommit, fromCommit].flatMap{
//            GTCommit(obj: $0.commit, in: repo)
//        }
//        index.read_tree(repo.head.target.tree)
//        index.removeFile(<#T##file: String##Swift.String#>)
//try repo.currentBranch().targetCommit().commitDate!

