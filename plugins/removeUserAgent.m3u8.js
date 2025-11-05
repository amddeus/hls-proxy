//	For logging to hls-proxy console use:
//	globals.error('Your text of message');
//

// Playlist is available in m3u8 variable as Buffer object

const lines = m3u8.toString().split('\n');

for (let i = 0; i < lines.length; i++) {
	const line = lines[i];

	if (line.startsWith('#EXTVLCOPT:')) {
		// We remove user agent
	}
	else {
		print(line + '\n');
	}
}
