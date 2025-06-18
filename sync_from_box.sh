rclone copy --exclude-from='.gitignore' box:dbg-out/ ./experiments -v
# rclone check --exclude-from='.gitignore' ./experiments box:dbg-out/