#!/usr/bin/env bash
input=$(cat)

model=$(echo "$input" | jq -r '.model.display_name // "unknown"')
cwd=$(echo "$input" | jq -r '.cwd // .workspace.current_dir // "unknown"')
session_id=$(echo "$input" | jq -r '.session_id // "unknown"')

used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
left_pct=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')

total_input=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
total_output=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')

# Build context display
ctx_used=""
ctx_left=""
if [ -n "$used_pct" ]; then
  ctx_used=$(printf "ctx_used:%.0f%%" "$used_pct")
fi
if [ -n "$left_pct" ]; then
  ctx_left=$(printf "ctx_left:%.0f%%" "$left_pct")
fi

# Build a rough cost estimate (input ~$3/M, output ~$15/M for Sonnet)
cost=""
if [ "$total_input" -gt 0 ] 2>/dev/null || [ "$total_output" -gt 0 ] 2>/dev/null; then
  cost=$(awk -v i="$total_input" -v o="$total_output" 'BEGIN { printf "cost:$%.4f", (i/1000000*3) + (o/1000000*15) }')
fi

printf "%s | %s | %s | %s | %s | session:%s" \
  "$model" \
  "$cwd" \
  "${ctx_used:-ctx_used:n/a}" \
  "${ctx_left:-ctx_left:n/a}" \
  "${cost:-cost:n/a}" \
  "$session_id"
