rclone copy --exclude-from='.gitignore' ./sensitivity-analysis/experiments box:dbg-out/experiments -v
rclone copy --exclude-from='.gitignore' ./optimization/output box:dbg-out/optimization -v
rclone copy --exclude-from='.gitignore' ./montecarlo/output box:dbg-out/montecarlo -v
# rclone check --exclude-from='.gitignore' ./experiments box:dbg-out/