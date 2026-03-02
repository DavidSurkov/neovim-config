" Basic log-level highlighting.
syntax match LogError /\v(ERROR|FATAL|CRITICAL)/
syntax match LogWarn /\v(WARN|WARNING)/
syntax match LogInfo /\v(INFO)/
syntax match LogDebug /\v(DEBUG|TRACE)/

highlight default link LogError MiniStatuslineModeReplace
highlight default link LogWarn MiniStatuslineModeCommand
highlight default link LogInfo MiniStatuslineModeInsert
highlight default link LogDebug MiniStatuslineModeNormal
