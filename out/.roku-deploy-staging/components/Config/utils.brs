' ********** Copyright 2015 Roku Corp.  All Rights Reserved. **********

' Returns top parent scene. Can be used for displaying dialogs over the scene etc. 
function GetParentScene() as Object
    m.parentScene = m.top.GetParent()
    while m.parentScene <> invalid
        grandParent = m.parentScene.GetParent()
        if grandParent = invalid then
            exit while
        end if
        m.parentScene = grandParent
    end while
    return m.parentScene
end function

'function getDeviceESN()
'	return CreateObject("roDeviceInfo").GetDeviceUniqueId()
'end function

function getDeviceESN()
	uid = CreateObject("roDeviceInfo").GetChannelClientId()
	return uid
end function


function getRegistry()
	return CreateObject("roRegistrySection","JoyGo")
end function


function GetItem2(content as String) as Object
print "utils.brs - [GetItem] content >>>" 
print content

	channelxml = createObject("roXMLElement")
  	if not channelxml.Parse(content) then
		return invalid
	end if

	if channelxml = invalid then
		return invalid
	end if

	channelRoot = channelxml.getChildElements()
	channelItemElements = channelRoot.getChildElements()

	if channelItemElements = invalid then
		return invalid
	end if

        channelItem = {}


        for each channelItemElement in channelItemElements

print "utils.brs - [GetItem] channelItemElement.getName() " channelItemElement.getName()
print "utils.brs - [GetItem] channelItemElement.gettext() " channelItemElement.gettext()


          if channelItemElement.getName() = "title" then

                channelItem.title = channelItemElement.gettext()

          else if channelItemElement.getName() = "media:content" then

            	channelItem.stream = {url : channelItemElement.url}
            	channelItem.url = channelItemElement.getAttributes().url
            	channelItem.streamformat = "hls"

          else if channelItemElement.getName() = "media:thumbnail" then

                channelItem.hdposterurl          = channelItemElement.getAttributes().url
                channelItem.hdbackgroundimageurl = channelItemElement.getAttributes().url
                channelItem.uri                  = channelItemElement.getAttributes().url

          else if channelItemElement.getName() = "media:description" then

                channelItem.pubDate     = channelItemElement.gettext()
                channelItem.description = "Click play to watch"
	 else

           	channelItem[channelItemElement.getName()] = channelItemElement.gettext()

          end if


        end for



      return channelItem
end function



function GetItem(item as Object) as Object

    channelItemElements = item.getChildElements()
    if channelItemElements = invalid then
	return invalid
    end if

    channelItem = {}
    for each channelItemElement in channelItemElements

print "utils.brs - [GetItem] ItemElement.getName() " channelItemElement.getName()
print "utils.brs - [GetItem] ItemElement.gettext() " channelItemElement.gettext()

	if channelItemElement.getName() = "title" then
                channelItem.title = channelItemElement.gettext()

	else if channelItemElement.getName() = "media:content" then
            	channelItem.stream = {url : channelItemElement.url}
            	channelItem.url = channelItemElement.getAttributes().url
            	channelItem.streamformat = "hls"

	else if channelItemElement.getName() = "media:thumbnail" then
                channelItem.hdposterurl          = channelItemElement.getAttributes().url
                channelItem.hdbackgroundimageurl = channelItemElement.getAttributes().url
                'channelItem.uri                  = channelItemElement.getAttributes().url

	else if channelItemElement.getName() = "media:description" then
                channelItem.pubDate     = channelItemElement.gettext()
                channelItem.description = "Click play to watch"
	else if channelItemElement.getName() = "media:keywords" then
	else if channelItemElement.getName() = "media:title" then
	else
           	channelItem[channelItemElement.getName()] = channelItemElement.gettext()
	end if
    end for
    return channelItem
end function



function GetLiveInfo(content as String) as Object
    print "utils.brs - [GetItem] content >>>" 
    print content

    channelxml = createObject("roXMLElement")
    if not channelxml.Parse(content) then
	return invalid
    end if

    if channelxml = invalid then
	return invalid
    end if

    channelRoot = channelxml.getChildElements()
    channelElementsArray = channelRoot.getChildElements()
    if channelElementsArray = invalid then
	return invalid
    end if

    for each channelElement in channelElementsArray
    	if channelElement.getName() = "item"
		return GetItem(channelElement)
	end if
    end for

    return invalid
end function

Sub GetEncryptedDataFromServer(dataFile as String) As String

    'print "GetEncryptedDataFromServer():: Called"

    keyHex = CreateObject("roByteArray")
    keyHex.fromAsciiString("_SecureTulixKey_")

    rkeyHex = CreateObject("roByteArray")
    rkeyHex.fromAsciiString("12345678")

    'print "GetEncryptedDataFromServer():: Key as hex encoded string is"; keyHex.ToHexString();" rkey is "; rkeyHex.ToHexString()

    bFile = CreateObject("roByteArray")
    bFile.ReadFile(dataFile)
    print "GetEncryptedDataFromServer():: File size is"; bFile.Count(); " also contents "; bFile.toHexString()
    print "GetEncryptedDataFromServer():: As ASCII contents "; bFile.toAsciiString()

    enc = CreateObject("roEVPCipher")
    ret = enc.Setup(false, "bf-cbc", keyHex.ToHexString(), rkeyHex.ToHexString(), 0)
    result = enc.Process(bFile)

    'print "type: ";type(result) "type(bFile): "; type(bFile)

    'print "GetEncryptedDataFromServer(): result "; result
    if result <> invalid then
        'print "GetEncryptedDataFromServer():: Successfully Decrypted >>>"; result.toAsciiString(); "<<<"
	return result.ToAsciiString()
    else
        'print "GetEncryptedDataFromServer():: Invalid Decrypt"
	return ""
    end if

End Sub

Sub GetEncryptedStringDataFromServer(data as String) As String

    'print "GetEncryptedStringDataFromServer():: Called with data "; data

    keyHex = CreateObject("roByteArray")
    keyHex.fromAsciiString("_SecureTulixKey_")

    rkeyHex = CreateObject("roByteArray")
    rkeyHex.fromAsciiString("12345678")

    'print "GetEncryptedStringDataFromServer():: Key as hex encoded string is"; keyHex.ToHexString();" rkey is "; rkeyHex.ToHexString()

    bFile = CreateObject("roByteArray")
    bFile.fromHexString(data)

    enc = CreateObject("roEVPCipher")
    ret = enc.Setup(false, "bf-cbc", keyHex.ToHexString(), rkeyHex.ToHexString(), 0)
    result = enc.Process(bFile)

    'print "type: ";type(result) "type(data) :" type(dataStream) ; "type(bFile): "; type(bFile)

    if result <> invalid then
        'print "GetEncryptedStringDataFromServer():: Successfully Decrypted >>>"; result.toAsciiString(); "<<<"
		return result.ToAsciiString()
    else
        'print "GetEncryptedStringDataFromServer():: Invalid Decrypt"
		return ""
    end if

End Sub

