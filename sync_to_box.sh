rclone copy --exclude-from='.gitignore' ./experiments box:dbg-out/ -v
# rclone check --exclude-from='.gitignore' ./experiments box:dbg-out/