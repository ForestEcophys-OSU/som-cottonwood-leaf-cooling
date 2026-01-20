rclone copy --exclude-from='.gitignore' ./sensitivity-analysis/experiments box:dbg-out/experiments -v
rclone copy --exclude-from='.gitignore' ./optimization/output box:dbg-out/optimization -v
rclone copy --exclude-from='.gitignore' ./montecarlo/output box:dbg-out/montecarlo -v
rclone copy --exclude-from='.gitignore' ./leaf-energy-balance/sa/experiments box:dbg-out/sa_leaf-energy -v
# rclone check --exclude-from='.gitignore' ./experiments box:dbg-out/