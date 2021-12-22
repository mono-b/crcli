# crcli

An interactive script to watch (only free) crunchyroll content from the cli.
The script generates a folder with files in `$HOME/.local/share/`. These files
contain lists of shows and episodes that the user generates interactively.

## Features

- Watch full show or resume
- Watch a single episode
- Start show from an episode
- Play a range of episodes
- Search for shows
- About section with ranking
- Trending shows
- Random show recommendations

## Download and usage

```
git clone https://github.com/mono-b/crcli.git
chmod +x crcli.sh
./crcli.sh
```

## Dependencies

- mpv
- lynx
- sed
- awk

## Notes

- I made this script while learning shell a year ago. Is poorly written but works.
Feel free to do whatever you want with it.
- Try both methods if one or another doesn't give you the expected result (i.e show dub/sub)
- MPV's x11 window renamed to `crcli`
