sub main()
	screen = createObject("roSGScreen")
	msgPort = CreateObject("roMessagePort")

	input = CreateObject("roInput")
	input.SetMessagePort(msgPort)


	' m.global.AddField("channelStore", "node", false)
	' m.global.channelStore = CreateObject("roSGNode", "ChannelStore")
	' vscode_rdb_on_device_component_entry
	m.global = screen.getGlobalNode()
	' m.global.AddField("exitApp", "bool", false)

	m.port = CreateObject("roMessagePort")
	screen.setMessagePort(m.port)
	scene = screen.createScene("home_scene")
	scene.signalBeacon("AppDialogInitiate")
	
	scene.signalBeacon("AppDialogComplete")
	scene.signalBeacon("AppLaunchComplete")
	screen.Show()
	scene.observeField("exitApp", m.port)


	while(true)
		msg = wait(0, m.port)
		msgType = type(msg)
		if msgType = "roSGScreenEvent"
			if msg.isScreenClosed() then return
		end if
		if msgType = "roInputEvent"
			info = msg.getInfo()
			getDeepLink(info)
		end if
		if msgType = "roSGNodeEvent" then
			field = msg.getField()
			if field = "exitApp" then
				return
			end if
		end if
	end while
end sub

Sub ExitUserInterface()
print "are we egetting here"
    End
End Sub



sub handleDeepLink(args)
end sub


function getDeepLink(args) as object
	deeplink = invalid

	if args.contentid <> invalid and args.mediaType <> invalid
		deeplink = {
			id: args.contentId
			type: args.mediaType
		}
	end if

	return deeplink
end function



