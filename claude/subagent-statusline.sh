#!/usr/bin/env bash
# Claude Code subagent status line — renders one row per subagent in the agent panel.
#
# The default row body is `name · description · token count`, which never shows
# which model a subagent is actually running on. Since ~/.claude/rules/model-routing.md
# routes each agent to a different model (explorer/mechanic → haiku, reviewer →
# session model, strategist → fable), the model is the one thing worth seeing at a
# glance: it is how you confirm the routing rule actually fired.
#
# Row layout:
#   [name] · [Model (effort)] · [description] · [tokens (ctx%)]
#
# stdin  : one JSON object with `columns` and a `tasks` array (id, name, type,
#          status, description, label, startTime, model, effort,
#          contextWindowSize, tokenCount, tokenSamples, cwd).
# stdout : one JSON line per row — {"id": "<task id>", "content": "<row body>"}.
#          Rows we skip keep their default rendering.
#
# `model` / `contextWindowSize` require Claude Code v2.1.205+, `effort` v2.1.214+;
# both are simply omitted from the row when absent, so older versions degrade to
# the name/description/token layout instead of breaking.

input=$(cat)

# jq does the whole render: it owns the JSON escaping of the ANSI sequences, which
# is the part a bash string-builder gets wrong.
printf '%s' "$input" | jq -c '

# --- Display width -----------------------------------------------------------
# East Asian wide ranges count as 2 cells. The agent panel is width-constrained,
# and descriptions here are Japanese often enough that a naive length() overflows.
def cpw:
  if . >= 4352 and (
       (. <= 4447)                          # 1100-115F Hangul Jamo
    or (. >= 11904 and . <= 12350)          # 2E80-303E CJK radicals, punctuation
    or (. >= 12353 and . <= 13311)          # 3041-33FF kana, CJK compat
    or (. >= 13312 and . <= 40959)          # 3400-9FFF CJK ideographs
    or (. >= 40960 and . <= 42127)          # A000-A4CF Yi
    or (. >= 44032 and . <= 55203)          # AC00-D7A3 Hangul syllables
    or (. >= 63744 and . <= 64255)          # F900-FAFF CJK compat ideographs
    or (. >= 65072 and . <= 65135)          # FE30-FE6F vertical forms
    or (. >= 65280 and . <= 65376)          # FF00-FF60 fullwidth forms
    or (. >= 65504 and . <= 65510)          # FFE0-FFE6 fullwidth signs
    or (. >= 127744 and . <= 129535)        # 1F300-1F9FF emoji
    or (. >= 131072 and . <= 262141)        # 20000-3FFFD CJK ext B+
  ) then 2 else 1 end;

def dwidth:
  if . == null or . == "" then 0 else ([explode[] | cpw] | add) end;

# Truncate to $max cells, reserving one cell for the ellipsis.
def trunc($max):
  . as $s
  | if ($s | dwidth) <= $max then $s
    elif $max <= 1 then "…"
    else ($s | explode) as $cp
      | reduce range(0; $cp | length) as $i ({ acc: [], w: 0, done: false };
          if .done then .
          else (.w + ($cp[$i] | cpw)) as $nw
            | if $nw > ($max - 1) then .done = true
              else { acc: (.acc + [$cp[$i]]), w: $nw, done: false }
              end
          end)
      | (.acc | implode) + "…"
    end;

# --- Model id -> short label -------------------------------------------------
# Handles plain ids (claude-opus-5), dated ids (claude-haiku-4-5-20251001), the
# 1M-context suffix (claude-opus-5[1m]) and Bedrock/Vertex prefixes
# (us.anthropic.claude-sonnet-4-5-20250929-v1:0).
def short_model:
  if . == null or . == "" then null
  else . as $raw
    | ($raw | ascii_downcase) as $l
    | ($l | test("\\[1m\\]")) as $long
    | ( ($l | capture("(?<f>opus|sonnet|haiku|fable)-(?<v>[0-9]+(?:-[0-9]+)?)"))
        // ($l | capture("(?<v>[0-9]+(?:-[0-9]+)?)-(?<f>opus|sonnet|haiku|fable)"))
        // null ) as $m
    | (if $m == null then
         # Unknown id: strip the boilerplate and show whatever is left.
         ($raw | sub("^(us|eu|apac)\\.";"") | sub("^anthropic\\.";"")
               | sub("^claude-";"") | sub("-v[0-9]+:[0-9]+$";""))
       else (($m.f[0:1] | ascii_upcase) + $m.f[1:]) + " " + ($m.v | gsub("-";"."))
       end)
      + (if $long then " 1M" else "" end)
  end;

def fmt_tokens:
  if . == null or . <= 0 then null
  elif . >= 1000000 then ((. / 100000 | floor) / 10 | tostring) + "M"
  elif . >= 1000 then ((. / 100 | floor) / 10 | tostring) + "k"
  else tostring end;

# --- Palette (shared with statusline-command.sh) -----------------------------
"\u001b[0m"                 as $R  |
"\u001b[1m"                 as $B  |
"\u001b[38;2;90;95;110m"    as $C_SEP |
"\u001b[38;2;137;180;250m"  as $C_MODEL |
"\u001b[38;2;150;155;170m"  as $C_DESC |
"\u001b[38;2;163;190;140m"  as $C_TOK |
($C_SEP + " · " + $R)       as $SEP |

((.columns // 80) | if type == "number" and . > 20 then . else 80 end) as $cols |

(.tasks // [])[]
| . as $t
| ($t.name // $t.type // "agent") as $name
| ($t.model | short_model) as $model
| (if $t.effort == null then null else ($t.effort | tostring) end) as $effort
| (if $model == null then null
   elif $effort == null then $model
   else $model + " (" + $effort + ")" end) as $model_txt
| ($t.tokenCount | fmt_tokens) as $tok
| (if ($t.tokenCount // 0) > 0 and ($t.contextWindowSize // 0) > 0
   then ($t.tokenCount / $t.contextWindowSize * 100 | round) as $p
     | (if $p < 1 then null else ($p | tostring) + "%" end)
   else null end) as $pct
| (if $tok == null then null
   elif $pct == null then $tok
   else $tok + " " + $pct end) as $tok_txt

# Width of a [name, model, tokens] triple once nulls are dropped and " · " joins
# the survivors.
| def row_w: map(select(. != null)) | (map(dwidth) | add) + ((length - 1) * 3);

# On a narrow panel, shed detail in reverse order of usefulness rather than
# letting the row overflow: token count first, then the effort suffix, then the
# name itself. The model label is what this status line exists to show, so it is
# the last thing to go.
  [ [$name, $model_txt, $tok_txt]
  , [$name, $model_txt, null]
  , [$name, $model, null]
  , [($name | trunc($cols)), null, null]
  ] as $variants
| (first($variants[] | select(row_w <= $cols)) // $variants[3]) as $fit
| $fit[0] as $name | $fit[1] as $model_txt | $fit[2] as $tok_txt

# Those three are fixed width; the description absorbs whatever is left.
| ($cols - ($fit | row_w) - 3) as $desc_room
| (if ($t.description // "") == "" or $desc_room < 8 then null
   else ($t.description | trunc($desc_room)) end) as $desc

| [ ($B + $name + $R)
  , (if $model_txt == null then empty else $C_MODEL + $model_txt + $R end)
  , (if $desc == null then empty else $C_DESC + $desc + $R end)
  , (if $tok_txt == null then empty else $C_TOK + $tok_txt + $R end)
  ]
| { id: $t.id, content: join($SEP) }
' 2>/dev/null || exit 0
