//	For logging to hls-proxy console use:
//	globals.error('Your text of message');
//

print('#EXTM3U\n');

// XML Attributes is accesible by $ property (Example: channel.$)
// Groups dictionary
let groupsMap = {};
if (items.category) {
	items.category = Array.isArray(items.category) ? items.category : [items.category];
	groupsMap = items.category.reduce((acc, val) => {
		acc[val.category_id] = val.category_title;
		return acc;
	}, {});
}

// Go over channel list
if (!Array.isArray(items.channel)) {
	items.channel = [items.channel];
}
items.channel.forEach(function (channel) {
	const url = channel.stream_url || channel.playlist_url || '';
	if (url) {
		const logo = channel.image ? ` tvg-logo="${channel.image}"` : '';
		let groupIds = (channel.category_id || '').split(',').map(id => groupsMap[id]) || [];
		groupIds.length = Math.min(groupIds.length, 1);
		groupIds = (groupIds.length > 0) ? ` group-title="${groupIds.join(';')}"` : '';

		print(`#EXTINF:0${logo}${groupIds},${channel.title}\n${url}\n`);
	}
})
