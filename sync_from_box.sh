rclone copy --exclude-from='.gitignore' box:dbg-out/experiments ./sensitivity-analysis/experiments -v
rclone copy --exclude-from='.gitignore' box:dbg-out/optimization ./optimization/output -v
# rclone check --exclude-from='.gitignore' ./experiments box:dbg-out/