//	For logging to hls-proxy console use:
//	globals.error('Your text of message');
//

print('#EXTM3U\n');

// XML Attributes is accesible by $ property (Example: channel.$)
// Groups dictionary
const groupsMap = categories.reduce((acc, val) => {
	acc[val.category_id] = val.category_title;
	return acc;
}, {})

// Go over channel list
channels.forEach(function (channel) {
	const url = channel.stream_url || channel.playlist_url || '';
	if (url) {
		const logo = channel.logo ? ` tvg-logo="${channel.logo}"` : '';
		let groupIds = (channel.category_id || '').split(',').map(id => groupsMap[id]) || [];
		groupIds = (groupIds.length > 0) ? ` group-title="${groupIds.join(';')}"` : '';

		print(`#EXTINF:0${logo}${groupIds},${channel.title}\n${url}\n`);
	}
})
