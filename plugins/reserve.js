// VERSION 1.4
// require('../Tools/pluginsHelper');

// Playlist is available in m3u8 variable as Buffer object

//	For logging to hls-proxy console use:
//	error('Your text of message');
//

// if true - strips all encountered suffixes in the name
// when false - a name with a maximal priority will be assigned
const STRIP_SUFFIXES = true;

// Suffixes detect the name endings and set priorities by its order
const SUFFIXES = [
	' 4K',
	' UHD',
	' FHD',
	' HD 50 orig',
	' HD 50',
	' HD orig',
	' HD',
	' orig',
].map(s => s.toLowerCase());

const REPLACE_IN_HASH = [
	[/°/g, ""],
	[/Телеканал 360/i, '360'],
	[/Первый канал/i, 'Первый'],
	[/Россия 1/i, 'Россия'],
];

//
const FILTER = [
	// ' HD 50 orig',
].map(s => s.toLowerCase());

const namesMap = {};
const newList = [];

// "m3u8" is predefined variable containing Buffer object
// m3u8.toString() converts it to "utf-8" encoded string

// Remove empty spaces and lines
m3u8 = m3u8.toString().split('\n').map(l => l.trim()).filter(l => l).join('\n');

const channels = m3u8.split('\n#EXTINF:');

const makeHash = function (name) {
	name = name.toLowerCase();

	REPLACE_IN_HASH.map(r => {
		name = name.replace(...r);
	})

	return name.toLowerCase();
}

for (let i = 0; i < channels.length; i++) {
	const channelLines = channels[i];

	if (channelLines.startsWith('#EXTM3U')) continue;

	const lines = channelLines.split('\n');
	const extinf = lines[0];

	let info = extinf.split(/"\s*,/);
	if (info.length < 2) {
		info = extinf.split(',');
	}
	const origName = info.pop().trim();
	let name = origName;
	let hash = makeHash(name);

	if (FILTER.find(s => hash.endsWith(s))) {
		continue;
	}

	let priority = Math.min(...SUFFIXES.map((s, index) => {
		if (hash.endsWith(s)) {
			name = name.substring(0, name.length - s.length).trim();
			hash = makeHash(name);
			return index;
		}
		return SUFFIXES.length;
	}));

	let channelArray = namesMap[hash] || (newList.push([]), namesMap[hash] = newList[newList.length - 1]);
	lines[0] = '#EXTINF:' + info.join(',') + ',';
	channelArray.push({
		origName: STRIP_SUFFIXES ? name : origName,
		lines: lines,
		priority: priority,
	})
}

print('#EXTM3U\n');
newList.map(o => {
	o.sort((ch1, ch2) => ch1.priority - ch2.priority)
	const name = o[0].origName;
	o.map(ch => {
		ch.lines[0] += name;
		print(ch.lines.join('\n') + '\n');
	});
})

