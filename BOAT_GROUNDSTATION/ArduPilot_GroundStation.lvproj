<?xml version='1.0' encoding='UTF-8'?>
<Project Type="Project" LVVersion="9008000">
	<Item Name="My Computer" Type="My Computer">
		<Property Name="server.app.propertiesEnabled" Type="Bool">true</Property>
		<Property Name="server.control.propertiesEnabled" Type="Bool">true</Property>
		<Property Name="server.tcp.enabled" Type="Bool">false</Property>
		<Property Name="server.tcp.port" Type="Int">0</Property>
		<Property Name="server.tcp.serviceName" Type="Str">My Computer/VI Server</Property>
		<Property Name="server.tcp.serviceName.default" Type="Str">My Computer/VI Server</Property>
		<Property Name="server.vi.callsEnabled" Type="Bool">true</Property>
		<Property Name="server.vi.propertiesEnabled" Type="Bool">true</Property>
		<Property Name="specify.custom.address" Type="Bool">false</Property>
		<Item Name="Rotate" Type="Folder">
			<Item Name="Calculate New Size.vi" Type="VI" URL="../Rotate.llb/Calculate New Size.vi"/>
			<Item Name="Calculate Offset.vi" Type="VI" URL="../Rotate.llb/Calculate Offset.vi"/>
			<Item Name="Picture Control to 2D Pixmap.vi" Type="VI" URL="../Rotate.llb/Picture Control to 2D Pixmap.vi"/>
			<Item Name="rotate 1bit.vi" Type="VI" URL="../Rotate.llb/rotate 1bit.vi"/>
			<Item Name="rotate 24bit.vi" Type="VI" URL="../Rotate.llb/rotate 24bit.vi"/>
			<Item Name="rotate 8bit.vi" Type="VI" URL="../Rotate.llb/rotate 8bit.vi"/>
			<Item Name="Rotate Pixmap.vi" Type="VI" URL="../Rotate.llb/Rotate Pixmap.vi"/>
		</Item>
		<Item Name="Control 3.ctl" Type="VI" URL="../Control 3.ctl"/>
		<Item Name="flight.kml" Type="Document" URL="../flight.kml"/>
		<Item Name="IsEXE.vi" Type="VI" URL="../IsEXE.vi"/>
		<Item Name="lookfordata.vi" Type="VI" URL="../lookfordata.vi"/>
		<Item Name="NetworkLink.kml" Type="Document" URL="../NetworkLink.kml"/>
		<Item Name="pitch.bmp" Type="Document" URL="../pitch.bmp"/>
		<Item Name="roll.bmp" Type="Document" URL="../roll.bmp"/>
		<Item Name="Rotate Picture Control.vi" Type="VI" URL="../Rotate Picture Control.vi"/>
		<Item Name="virtual.vi" Type="VI" URL="../virtual.vi"/>
		<Item Name="windrose.ctl" Type="VI" URL="../windrose.ctl"/>
		<Item Name="groundtest.vi" Type="VI" URL="../groundtest.vi"/>
		<Item Name="Dependencies" Type="Dependencies">
			<Item Name="vi.lib" Type="Folder">
				<Item Name="Unflatten Pixmap.vi" Type="VI" URL="/&lt;vilib&gt;/picture/pixmap.llb/Unflatten Pixmap.vi"/>
				<Item Name="imagedata.ctl" Type="VI" URL="/&lt;vilib&gt;/picture/picture.llb/imagedata.ctl"/>
				<Item Name="Draw Flattened Pixmap.vi" Type="VI" URL="/&lt;vilib&gt;/picture/picture.llb/Draw Flattened Pixmap.vi"/>
				<Item Name="FixBadRect.vi" Type="VI" URL="/&lt;vilib&gt;/picture/pictutil.llb/FixBadRect.vi"/>
				<Item Name="Unflatten Pixmap(6_1).vi" Type="VI" URL="/&lt;vilib&gt;/picture/pixmap.llb/Unflatten Pixmap(6_1).vi"/>
				<Item Name="Draw True-Color Pixmap(6_1).vi" Type="VI" URL="/&lt;vilib&gt;/picture/picture.llb/Draw True-Color Pixmap(6_1).vi"/>
				<Item Name="Draw True-Color Pixmap.vi" Type="VI" URL="/&lt;vilib&gt;/picture/picture.llb/Draw True-Color Pixmap.vi"/>
				<Item Name="Flatten Pixmap.vi" Type="VI" URL="/&lt;vilib&gt;/picture/pixmap.llb/Flatten Pixmap.vi"/>
				<Item Name="Picture to Pixmap.vi" Type="VI" URL="/&lt;vilib&gt;/picture/pictutil.llb/Picture to Pixmap.vi"/>
				<Item Name="Create Mask.vi" Type="VI" URL="/&lt;vilib&gt;/picture/pictutil.llb/Create Mask.vi"/>
				<Item Name="Bit-array To Byte-array.vi" Type="VI" URL="/&lt;vilib&gt;/picture/pictutil.llb/Bit-array To Byte-array.vi"/>
				<Item Name="Get Image Subset.vi" Type="VI" URL="/&lt;vilib&gt;/picture/pictutil.llb/Get Image Subset.vi"/>
				<Item Name="Coerce Bad Rect.vi" Type="VI" URL="/&lt;vilib&gt;/picture/pictutil.llb/Coerce Bad Rect.vi"/>
				<Item Name="Read BMP File.vi" Type="VI" URL="/&lt;vilib&gt;/picture/bmp.llb/Read BMP File.vi"/>
				<Item Name="Read BMP File Data.vi" Type="VI" URL="/&lt;vilib&gt;/picture/bmp.llb/Read BMP File Data.vi"/>
				<Item Name="Read BMP Header Info.vi" Type="VI" URL="/&lt;vilib&gt;/picture/bmp.llb/Read BMP Header Info.vi"/>
				<Item Name="Calc Long Word Padded Width.vi" Type="VI" URL="/&lt;vilib&gt;/picture/bmp.llb/Calc Long Word Padded Width.vi"/>
				<Item Name="Flip and Pad for Picture Control.vi" Type="VI" URL="/&lt;vilib&gt;/picture/bmp.llb/Flip and Pad for Picture Control.vi"/>
				<Item Name="VISA Configure Serial Port" Type="VI" URL="/&lt;vilib&gt;/Instr/_visa.llb/VISA Configure Serial Port"/>
				<Item Name="VISA Configure Serial Port (Instr).vi" Type="VI" URL="/&lt;vilib&gt;/Instr/_visa.llb/VISA Configure Serial Port (Instr).vi"/>
				<Item Name="VISA Configure Serial Port (Serial Instr).vi" Type="VI" URL="/&lt;vilib&gt;/Instr/_visa.llb/VISA Configure Serial Port (Serial Instr).vi"/>
				<Item Name="VISA Set IO Buffer Mask.ctl" Type="VI" URL="/&lt;vilib&gt;/Instr/_visa.llb/VISA Set IO Buffer Mask.ctl"/>
				<Item Name="Draw Text at Point.vi" Type="VI" URL="/&lt;vilib&gt;/picture/picture.llb/Draw Text at Point.vi"/>
				<Item Name="Get Text Rect.vi" Type="VI" URL="/&lt;vilib&gt;/picture/picture.llb/Get Text Rect.vi"/>
				<Item Name="Draw Text in Rect.vi" Type="VI" URL="/&lt;vilib&gt;/picture/picture.llb/Draw Text in Rect.vi"/>
				<Item Name="PCT Pad String.vi" Type="VI" URL="/&lt;vilib&gt;/picture/picture.llb/PCT Pad String.vi"/>
			</Item>
		</Item>
		<Item Name="Build Specifications" Type="Build">
			<Item Name="ArduPilot GroundStation" Type="EXE">
				<Property Name="App_applicationGUID" Type="Str">{EA82E5A5-8382-4E33-AB84-07ACC544400B}</Property>
				<Property Name="App_applicationName" Type="Str">ArduStation.exe</Property>
				<Property Name="App_autoIncrement" Type="Bool">true</Property>
				<Property Name="App_companyName" Type="Str">DIYdrones.com</Property>
				<Property Name="App_fileDescription" Type="Str">ArduPilot GroundStation</Property>
				<Property Name="App_fileVersion.build" Type="Int">1</Property>
				<Property Name="App_fileVersion.major" Type="Int">1</Property>
				<Property Name="App_INI_aliasGUID" Type="Str">{3166D8B4-C0F0-4B35-B7EA-F185A2DC19D8}</Property>
				<Property Name="App_INI_GUID" Type="Str">{2472E8F0-24C4-499D-A0E0-C6C0AD49BE53}</Property>
				<Property Name="App_internalName" Type="Str">ArduPilot GroundStation</Property>
				<Property Name="App_legalCopyright" Type="Str">Copyright © 2009 </Property>
				<Property Name="App_productName" Type="Str">ArduPilot GroundStation</Property>
				<Property Name="Bld_buildSpecName" Type="Str">ArduPilot GroundStation</Property>
				<Property Name="Bld_excludeLibraryItems" Type="Bool">true</Property>
				<Property Name="Bld_excludePolymorphicVIs" Type="Bool">true</Property>
				<Property Name="Bld_modifyLibraryFile" Type="Bool">true</Property>
				<Property Name="Destination[0].destName" Type="Str">ArduStation.exe</Property>
				<Property Name="Destination[0].path" Type="Path">../GroundStation_Beta2/Builds/ArduStation.exe</Property>
				<Property Name="Destination[0].type" Type="Str">App</Property>
				<Property Name="Destination[1].destName" Type="Str">Support Directory</Property>
				<Property Name="Destination[1].path" Type="Path">../GroundStation_Beta2/Builds/data</Property>
				<Property Name="DestinationCount" Type="Int">2</Property>
				<Property Name="Source[0].itemID" Type="Str">{3FE62BFE-AE3F-405E-94DE-6802E0ABDF59}</Property>
				<Property Name="Source[0].type" Type="Str">Container</Property>
				<Property Name="Source[1].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[1].itemID" Type="Ref"></Property>
				<Property Name="Source[1].sourceInclusion" Type="Str">TopLevel</Property>
				<Property Name="Source[1].type" Type="Str">VI</Property>
				<Property Name="Source[10].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[10].itemID" Type="Ref">/My Computer/virtual.vi</Property>
				<Property Name="Source[10].sourceInclusion" Type="Str">Include</Property>
				<Property Name="Source[10].type" Type="Str">VI</Property>
				<Property Name="Source[11].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[11].itemID" Type="Ref">/My Computer/windrose.ctl</Property>
				<Property Name="Source[11].sourceInclusion" Type="Str">Include</Property>
				<Property Name="Source[11].type" Type="Str">VI</Property>
				<Property Name="Source[12].Container.applyInclusion" Type="Bool">true</Property>
				<Property Name="Source[12].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[12].itemID" Type="Ref">/My Computer/Rotate</Property>
				<Property Name="Source[12].sourceInclusion" Type="Str">Include</Property>
				<Property Name="Source[12].type" Type="Str">Container</Property>
				<Property Name="Source[2].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[2].itemID" Type="Ref">/My Computer/Control 3.ctl</Property>
				<Property Name="Source[2].sourceInclusion" Type="Str">Include</Property>
				<Property Name="Source[2].type" Type="Str">VI</Property>
				<Property Name="Source[3].destinationIndex" Type="Int">1</Property>
				<Property Name="Source[3].itemID" Type="Ref">/My Computer/flight.kml</Property>
				<Property Name="Source[3].sourceInclusion" Type="Str">Include</Property>
				<Property Name="Source[4].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[4].itemID" Type="Ref">/My Computer/IsEXE.vi</Property>
				<Property Name="Source[4].sourceInclusion" Type="Str">Include</Property>
				<Property Name="Source[4].type" Type="Str">VI</Property>
				<Property Name="Source[5].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[5].itemID" Type="Ref">/My Computer/lookfordata.vi</Property>
				<Property Name="Source[5].sourceInclusion" Type="Str">Include</Property>
				<Property Name="Source[5].type" Type="Str">VI</Property>
				<Property Name="Source[6].destinationIndex" Type="Int">1</Property>
				<Property Name="Source[6].itemID" Type="Ref">/My Computer/NetworkLink.kml</Property>
				<Property Name="Source[6].sourceInclusion" Type="Str">Include</Property>
				<Property Name="Source[7].destinationIndex" Type="Int">1</Property>
				<Property Name="Source[7].itemID" Type="Ref">/My Computer/pitch.bmp</Property>
				<Property Name="Source[7].sourceInclusion" Type="Str">Include</Property>
				<Property Name="Source[8].destinationIndex" Type="Int">1</Property>
				<Property Name="Source[8].itemID" Type="Ref">/My Computer/roll.bmp</Property>
				<Property Name="Source[8].sourceInclusion" Type="Str">Include</Property>
				<Property Name="Source[9].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[9].itemID" Type="Ref">/My Computer/Rotate Picture Control.vi</Property>
				<Property Name="Source[9].sourceInclusion" Type="Str">Include</Property>
				<Property Name="Source[9].type" Type="Str">VI</Property>
				<Property Name="SourceCount" Type="Int">13</Property>
			</Item>
			<Item Name="ArduInstaller" Type="Installer">
				<Property Name="arpCompany" Type="Str">DIYdrones.com</Property>
				<Property Name="arpPhone" Type="Str">ardupilot@gmail.com</Property>
				<Property Name="arpURL" Type="Str">DIYdrones.com</Property>
				<Property Name="AutoIncrement" Type="Bool">true</Property>
				<Property Name="BldInfo.Count" Type="Int">0</Property>
				<Property Name="BuildLabel" Type="Str">ArduInstaller</Property>
				<Property Name="BuildLocation" Type="Path">../../Builds/ArduPilot_GroundStation/ArduInstaller</Property>
				<Property Name="DirInfo.Count" Type="Int">1</Property>
				<Property Name="DirInfo.DefaultDir" Type="Str">{E016117F-9C0C-4AFD-A317-8789A8921FF0}</Property>
				<Property Name="DirInfo[0].DirName" Type="Str">ArduPilot_GroundStation</Property>
				<Property Name="DirInfo[0].DirTag" Type="Str">{E016117F-9C0C-4AFD-A317-8789A8921FF0}</Property>
				<Property Name="DirInfo[0].ParentTag" Type="Str">{3912416A-D2E5-411B-AFEE-B63654D690C0}</Property>
				<Property Name="DistID" Type="Str">{167FB195-FA6C-44F5-B4F5-BA0575732760}</Property>
				<Property Name="InstSpecVersion" Type="Str">8608001</Property>
				<Property Name="LicenseFile" Type="Ref"></Property>
				<Property Name="LV80Higher" Type="Bool">true</Property>
				<Property Name="OSCheck" Type="Int">0</Property>
				<Property Name="OSCheck_Vista" Type="Bool">false</Property>
				<Property Name="ProductName" Type="Str">ArduPilot_GroundStation</Property>
				<Property Name="ProductVersion" Type="Str">1.0.1</Property>
				<Property Name="ReadmeFile" Type="Ref"></Property>
				<Property Name="UpgradeCode" Type="Str">{080D1CD2-2235-4F8A-93AB-5EF382A92DB8}</Property>
				<Property Name="WindowMessage" Type="Str">Thank you for choosing ArduPilot products!</Property>
				<Property Name="WindowTitle" Type="Str">HELLO!</Property>
			</Item>
		</Item>
	</Item>
</Project>
