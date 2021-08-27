swift package update || exit 1
swift build || exit 2

sudo ./.build/x86_64-unknown-linux-gnu/debug/TunTesterCli --internet-interface en0
