//
//  Server.swift
//  Merops
//
//  Created by sho sumioka on 2019/04/19.
//  Copyright © 2019 sho sumioka. All rights reserved.
//

import SocketIO

func start () {
    let manager = SocketManager(socketURL: URL(string: "http://localhost:32040")!, config: [.log(true), .compress])
    let socket = manager.defaultSocket

    socket.on(clientEvent: .connect) {data, ack in
        print("socket connected")
    }

    socket.on("currentAmount") {data, ack in
        guard let cur = data[0] as? Double else { return }
        
        socket.emitWithAck("canUpdate", cur).timingOut(after: 0) {data in
            socket.emit("update", ["amount": cur + 2.50])
        }
        
        ack.with("Got your currentAmount", "dude")
    }

    socket.connect()
}
