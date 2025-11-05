// VERSION 1.0
// require('../Tools/pluginsHelper');

// Playlist is available in m3u8 variable as Buffer object

//	For logging to hls-proxy console use:
//	error('Your text of message');
//

// "m3u8" is predefined variable containing Buffer object
// m3u8.toString() converts it to "utf-8" encoded string

const groupName = 'HLS-Proxy';
m3u8 = m3u8.toString().replace(/group-title=".*?"/gm, `group-title="${groupName}"`);
m3u8 = m3u8.replace(/^#EXTGRP:.*?$/gm, `#EXTGRP:${groupName}`);

print(m3u8);
