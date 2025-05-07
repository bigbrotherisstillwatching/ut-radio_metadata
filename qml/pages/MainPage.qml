import Lomiri.Components 1.3
import Lomiri.Components.ListItems 1.3
import QtQuick 2.7
import QtQuick.Layouts 1.3
import QtMultimedia 5.12
import Qt.labs.settings 1.0
import Process 1.0
import QtQuick.Controls 2.7 as Qqc
import Lomiri.Components.Styles 1.3

import "../net"
import "../util"
import "../notify"
import "../colors"

Rectangle {
   id: mainPage
   anchors.fill: parent
   property var padding: units.gu(3)
   property bool netReady: false
   property bool resumeAfterSuspend: false
   property bool resumeAfterNetworkError: false
   property bool isReconnecting: false
   property var lastStation

   color: Colors.backgroundColor

   Component.onCompleted: {
      init()
      process2.start("/bin/bash",["-c", "/opt/click.ubuntu.com/radio.s710/1.4.8/script/migrate_to_new_version.sh"])
   }

   ListModel {
      id: favouriteModel
   }

   Settings {
      id: settings
      property string lastStation: "{}"
   }

   Timer {
      id: reconnectTimer
      interval: 15000
      repeat: false
      running: false

      onTriggered: onReconnectTimer()
   }

   Connections {
      target: Qt.application

      onAboutToQuit: {
         audioPlayer.stop()
      }

      onStateChanged: {
         switch (Qt.application.state) {
         case Qt.ApplicationActive:
         case Qt.ApplicationInactive:
         case Qt.ApplicationSuspended:
            break;
         case Qt.ApplicationHidden:
            if (!audioPlayer.isPlaying() && resumeAfterSuspend)
               audioPlayer.play()

            break;
         }
      }
   }

   Process {
      id: process
      onFinished: {
         txt.text = readAll();
      }
   }

   Process {
      id: process2
   }

   MediaPlayer {
      id: audioPlayer
      audioRole: MediaPlayer.MusicRole
      source: lastStation && lastStation.url || ""

      onPlaybackStateChanged: mainPage.onPlaybackStateChanged()
      onStatusChanged: mainPage.onStatusChanged(status)
      onError: {
         Notify.error(i18n.tr("Error"), audioPlayer.errorString)
      }
   }

   Column {
      id: playerControls
      anchors.top: parent.top
      anchors.topMargin: mainPage.padding
      anchors.horizontalCenter: parent.horizontalCenter
      width: parent.width * 0.9
      spacing: mainPage.padding

      Column {
         id: playerTitles
         anchors.horizontalCenter: parent.horizontalCenter      
         width: parent.width
         spacing: units.gu(1)

         ScrollableText {
            id: stationText
            font.bold: true
            color: Colors.mainText
            width: playerTitles.width

            displayText: lastStation && lastStation.name || i18n.tr("No station")
         }
         ScrollableText {
            id: stationTitleText
            width: playerTitles.width

            displayText: mainPage.textForStatus()
         }
      }

      Rectangle {
         id: mymeta
         anchors.top: playerTitles.bottom
         anchors.left: parent.left
         anchors.right: parent.right

         TextArea {
            id: txt
            anchors.top: mymeta.top
            anchors.topMargin: 20
            horizontalAlignment: TextEdit.AlignHCenter
            width: playerTitles.width
            wrapMode: TextEdit.Wrap
            font.pointSize: 25
            color: Colors.mainText
            maximumLineCount: 3
            style: ActionBarStyle {
               backgroundColor: "transparent"
            }
         }
      }

      Rectangle {
         width: mainPage.width * 0.6
         height: mainPage.width * 0.6
         anchors.horizontalCenter: parent.horizontalCenter
         color: "transparent"

         Icon {
            anchors.topMargin: 200
            anchors.bottomMargin: -50
            anchors.fill: parent
            name: "stock_music"
            visible: !lastStation || !lastStation.image
         }

         Image {
            anchors.topMargin: 200
            anchors.bottomMargin: -50
            anchors.fill: parent
            visible: lastStation && lastStation.image || false
            source: lastStation && lastStation.image || ""
            asynchronous: true
         }
      }

      Row {
         anchors.horizontalCenter: parent.horizontalCenter
         spacing: mainPage.padding

         Button {
            width: units.gu(4)
            height: units.gu(4)
            anchors.verticalCenter: parent.verticalCenter

            color: Colors.surfaceColor
            iconName: "toolkit_input-search"
            enabled: mainPage.netReady

            onClicked: {
               var p = pageStack.push(Qt.resolvedUrl("./SearchPage.qml"))
               p.stationChanged.connect(setLastStation)
            }
         }

         Button {
            width: units.gu(6)
            height: units.gu(6)
            anchors.verticalCenter: parent.verticalCenter
            color: Colors.surfaceColor
            iconName: "media-playback-start"
            enabled: !!lastStation

            onClicked: mainPage.playStream()
         }

         Button {
            id: favIcon
            width: units.gu(4)
            height: units.gu(4)
            anchors.verticalCenter: parent.verticalCenter
            color: Colors.surfaceColor
            iconName: lastStation.favourite ? "starred" : "non-starred"
            enabled: !!lastStation

            onClicked: {
               lastStation.favourite = !lastStation.favourite
               favIcon.iconName = lastStation.favourite ? "starred" : "non-starred"

               if (!lastStation.favourite)
                  Functions.removeFavourite(lastStation.stationID)
               else
                  Functions.saveFavourite(lastStation)
            }
         }

         Button {
            width: units.gu(6)
            height: units.gu(6)
            anchors.verticalCenter: parent.verticalCenter
            color: Colors.surfaceColor
            iconName: "media-playback-stop"
            enabled: !!lastStation

            onClicked: mainPage.stopStream()
         }

         Button {
            width: units.gu(4)
            height: units.gu(4)
            anchors.verticalCenter: parent.verticalCenter
            color: Colors.surfaceColor
            iconName: "stock_link"

            onClicked: {
               var p = pageStack.push(Qt.resolvedUrl("./UrlPage.qml"))
               p.stationChanged.connect(mainPage.setLastStation)
            }
         }
      }

      Row {
         anchors.horizontalCenter: parent.horizontalCenter
         spacing: mainPage.padding

         Rectangle {
            height: units.gu(2)
            width: metaButton.width
            color: "transparent"
         }

         Button {
            id: helpButton
            text: i18n.tr("Help")
            color: Colors.surfaceColor
            onClicked: {
               var p = pageStack.push(Qt.resolvedUrl("./HelpPage.qml"))
            }
         }

         Icon {
            id: settingsIcon
            height: units.gu(2.5)
            width: units.gu(2.5)
            anchors.verticalCenter: parent.verticalCenter

            name: "properties"

            MouseArea {
               anchors.fill: parent
               onClicked: {
                  var p = pageStack.push(Qt.resolvedUrl("./SettingsPage.qml"))
               }
            }
         }

         Button {
            id: metaButton
            text: i18n.tr("What's playing?")
            color: Colors.surfaceColor
            onClicked: process.start("/bin/bash",["-c", "dbus-send --print-reply --dest=org.mpris.MediaPlayer2.MediaHub /org/mpris/MediaPlayer2 org.freedesktop.DBus.Properties.Get string:'org.mpris.MediaPlayer2.Player' string:'Metadata' | sed -n '/xesam:title/{ n; p }' | grep -oP '(?<=\").*(?=\")'"]);
         }

         Rectangle {
            height: units.gu(2)
            width: helpButton.width
            color: "transparent"
         }
      }
   }

   ListView {
      id: favList
      anchors.top: playerControls.bottom
      anchors.topMargin: padding/2
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      clip: true

      model: favouriteModel

      delegate: ListItem {
         height: layout.height + (divider.visible ? divider.height : 0)
         color: Colors.surfaceColor
         divider.colorFrom: Colors.borderColor
         divider.colorTo: Colors.borderColor
         highlightColor: Colors.highlightColor

         onClicked: mainPage.setLastStation(JSON.parse(JSON.stringify(favouriteModel.get(index))))

         leadingActions: ListItemActions {
            delegate: Rectangle {
               id: actRec
               width: height
               color: pressed ? Colors.highlightColor : Colors.surfaceColor
               Label {
                  anchors.centerIn: actRec
                  color: Colors.mainText
                  text: action.text
                  width: parent.width
                  horizontalAlignment: Text.AlignHCenter
                  textSize: Label.XSmall
                  wrapMode: Text.WordWrap
               }
            }
            actions: [
               Action {
                  text: i18n.tr("Delete")
                  onTriggered: {
                     if (favouriteModel.get(index).stationID === lastStation.stationID) {
                        lastStation.favourite = !lastStation.favourite
                        favIcon.iconName = lastStation.favourite ? "starred" : "non-starred"
                     } else if (favouriteModel.get(index).stationID != lastStation.stationID) {
                        favIcon.iconName = lastStation.favourite ? "starred" : "non-starred"
                     }
                     Functions.removeFavourite(stationID)
                  }
               }
            ]
         }
         trailingActions: ListItemActions {
            delegate: Rectangle {
               id: actRec2
               width: height
               color: pressed ? Colors.highlightColor : Colors.surfaceColor
               Label {
                  anchors.centerIn: actRec2
                  color: Colors.mainText
                  text: action.text
                  width: parent.width
                  horizontalAlignment: Text.AlignHCenter
                  textSize: Label.XSmall
                  wrapMode: Text.WordWrap
               }
            }
            actions: [
               Action {
                  text: i18n.tr("Show name")
                  onTriggered: {
                     txt.text = favouriteModel.get(index).name
                  }
               },
               Action {
                  text: i18n.tr("Save name")
                  onTriggered: {
                     Functions.changeName(favouriteModel.get(index).stationID, txt.text)
                  }
               },
               Action {
                  text: i18n.tr("Show stream URL")
                  onTriggered: {
                     txt.text = favouriteModel.get(index).url
                  }
               },
               Action {
                  text: i18n.tr("Save stream URL")
                  onTriggered: {
                     Functions.changeUrl(favouriteModel.get(index).url, txt.text)
                  }
               },
               Action {
                  text: i18n.tr("Show image URL")
                  onTriggered: {
                     txt.text = favouriteModel.get(index).image
                  }
               },
               Action {
                  text: i18n.tr("Save image URL")
                  onTriggered: {
                     Functions.changeImage(favouriteModel.get(index).stationID, txt.text)
                  }
               }
            ]
         }
         SlotsLayout {
            id: layout
            mainSlot: Label {
               text: name
               color: Colors.mainText
            }
            Image {
               source: image
               SlotsLayout.position: SlotsLayout.Leading;
               width: units.gu(4)
               height: units.gu(4)
               asynchronous: true
            }
         }

         onPressAndHold: ListView.view.ViewItems.dragMode =
            !ListView.view.ViewItems.dragMode
      }
      ViewItems.onDragUpdated: {
         if (event.status == ListItemDrag.Moving) {
            event.accept = false;
         } else if (event.status == ListItemDrag.Dropped) {
            model.move(event.from, event.to, 1);
            var datamodel = []
            for (var i = 0; i < favouriteModel.count; ++i) datamodel.push(favouriteModel.get(i))
            settings.setValue("favouriteStations", JSON.stringify(datamodel))
            Functions.changeOrder()
         }
      }
      moveDisplaced: Transition {
         LomiriNumberAnimation {
            property: "y"
         }
      }

      header: Rectangle {
         id: headerItem
         width: favList.width
         height: 50
         z: 2
         color: Colors.surfaceColor

         Text {
            anchors.centerIn: parent
            text: i18n.tr("Favourites") + " (" + favouriteModel.count + ")"
            color: Colors.mainText
            font.bold: true
         }
      }
   }

   // *******************************************************************
   // Init
   // *******************************************************************

   function init() {
      Network.init(function(err) {
         netReady = !err

         if (err)
            Notify.error(i18n.tr("Radio Browser"), i18n.tr("Failed to lookup hostname for radio-browser.info. Searching for web streams might be unavailable. Check internet connection and restart app.") + "\n" + err)
      })

      Functions.favouriteModel = favouriteModel
      Functions.init()

      var s
      try {
         s = JSON.parse(settings.value("lastStation"))
         lastStation = s
         lastStation.favourite = Functions.hasFavourite(s.stationID)
         favIcon.iconName = s.favourite ? "starred" : "non-starred"
      } catch (e) {}
   }

   // *******************************************************************
   // Player Controls
   // *******************************************************************

   function playStream() {
      stopReconnecting()
      audioPlayer.play()
      mainPage.resumeAfterSuspend = true
      mainPage.resumeAfterNetworkError = true

      if (!lastStation.manual)
         Network.countClick(lastStation)
   }

   function stopStream() {
      stopReconnecting()
      mainPage.resumeAfterSuspend = false
      mainPage.resumeAfterNetworkError = false
      audioPlayer.stop()
   }

   function setLastStation(station) {
      audioPlayer.stop()
      mainPage.lastStation = station
      favIcon.iconName = lastStation.favourite ? "starred" : "non-starred"
      settings.setValue("lastStation", JSON.stringify(mainPage.lastStation))
      audioPlayer.play()
      mainPage.resumeAfterSuspend = true
      mainPage.resumeAfterNetworkError = true

      Notify.info(i18n.tr("Playing"), station.name || i18n.tr("Web stream"))
   }

   // *******************************************************************
   // Connection recovery
   // *******************************************************************

   function reconnectLater() {
      console.log("Connection broken, trying to reconnect in " + (reconnectTimer.interval/1000) + "s ...")
      reconnectTimer.start()
      resumeAfterNetworkError = false

      Notify.warning(i18n.tr("Reconnecting"), i18n.tr("Connection broken, trying to reconnect ..."))
   }

   function stopReconnecting() {
      isReconnecting = false
      reconnectTimer.stop()
   }

   function onReconnectTimer() {
      console.log("Trying to reconnect ...")

      isReconnecting = true
      var ls = mainPage.lastStation
      mainPage.lastStation = null
      audioPlayer.stop()
      mainPage.lastStation = ls
      audioPlayer.play()
   }

   // *******************************************************************
   // SLOTS
   // *******************************************************************

   function onPlaybackStateChanged() {
      stationTitleText.displayText = textForPlaybackStatus()
      stationTitleText.color = Colors.detailText

      if (audioPlayer.playbackState === MediaPlayer.PlayingState
            && audioPlayer.status > 0 && audioPlayer.status < 4) {
         stopReconnecting()
      }

      if (audioPlayer.playbackRate === MediaPlayer.PausedState && isReconnecting) {
         audioPlayer.play()
      }
   }

   function onStatusChanged(status) {
      stationTitleText.displayText = textForStatus()
      stationTitleText.color = Colors.detailText

      if (resumeAfterNetworkError &&
            (status === MediaPlayer.EndOfMedia
             || status === MediaPlayer.InvalidMedia
             || status === MediaPlayer.UnknownStatus)) {
         reconnectLater();
      }
      else if (status === MediaPlayer.EndOfMedia)
         audioPlayer.play()
   }

   // *******************************************************************
   // Util
   // *******************************************************************

   function textForPlaybackStatus() {
      switch (audioPlayer.playbackState) {
      case MediaPlayer.PlayingState: return i18n.tr("Playing")
      case MediaPlayer.StoppedState: return i18n.tr("Stopped")
      case MediaPlayer.PausedState:  return i18n.tr("Paused")
      }
   }

   function textForStatus() {
      switch (audioPlayer.status) {
      case MediaPlayer.NoMedia:       return i18n.tr("NoMedia")
      case MediaPlayer.Loading:       return i18n.tr("Loading")
      case MediaPlayer.Loaded:        return textForPlaybackStatus()
      case MediaPlayer.Buffering:     return i18n.tr("Buffering")
      case MediaPlayer.Stalled:       return i18n.tr("Stalled")
      case MediaPlayer.Buffered:      return i18n.tr("Buffered")
      case MediaPlayer.EndOfMedia:    return i18n.tr("End of media")
      case MediaPlayer.InvalidMedia:  return i18n.tr("Invalid media")
      case MediaPlayer.UnknownStatus: return i18n.tr("Unknown status")
      }

      return ""
   }

   function isPlaying() {
      return audioPlayer.playbackState == MediaPlayer.PlayingState
   }
}
