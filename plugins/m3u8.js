// print('#EXTM3U\n');

// Playlist is available in m3u8 variable as Buffer object

//	For logging to hls-proxy console use:
//	globals.error('Your text of message');
//

// Set PREFIX value to add prefix
const PREFIX = ''; // 'HLS: '
// SET as true to enable renaming
const RENAME_DUPLICATES = false;

// With this example we will add a prefix 'HLS-Proxy: ' to each stream name
const addPrefixToName = function (name, prefix) {
	return prefix + name;
}

const namesMap = {};
// Enumerates duplicated names. Example: BBC, BBC (2), BBC (3), BBC(...) etc
const renameDuplicates = function (name) {
	const index = namesMap[name] = (namesMap[name] || 0) + 1;
	if (index > 1) {
		return name + ' (' + index + ')';
	}
	return name;
}

// "m3u8" is predefined variable containing Buffer object
// m3u8.toString() converts it to "utf-8" encoded string
const lines = m3u8.toString().split('\n');

for (let i = 0; i < lines.length; i++) {
	const line = lines[i];

	if (line.startsWith('#EXTINF:')) {
		const commaPos = line.lastIndexOf(',');
		const streamName = line.substring(commaPos + 1);
		let newStreamName = streamName;
		PREFIX && (newStreamName = addPrefixToName(streamName, PREFIX));
		RENAME_DUPLICATES && (newStreamName = renameDuplicates(streamName));

		print(line.replace(',' + streamName, ',' + newStreamName) + '\n');
		continue;
	}

	print(line + '\n');
}
