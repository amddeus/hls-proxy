//	For logging to hls-proxy console use:
//	globals.error('Your text of message');
//

print('#EXTM3U\n');

// Tags should be accessed by their names according original xml file (See vintera-tv.xml for structure)
// XML Attributes is accesible by $ property (Example: channel.$)
// Go over channel list
playlist.trackList.track.forEach(function (channel) {
	const url = channel.location || '';
	if (url) {
		const logo = channel.image ? ` tvg-logo="${channel.image}"` : '';

		print(`#EXTINF:0${logo},${channel.title}\n${url}\n`);
	}
})
