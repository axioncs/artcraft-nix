#!/usr/bin/env fish
set -g f apps.json
set -g auth
test -n "$GITHUB_TOKEN"; and set auth -H "Authorization: Bearer $GITHUB_TOKEN"

function setk
    jq --arg n $argv[1] --arg k $argv[2] --arg v $argv[3] '.[$n][$k]=$v' $f > $f.tmp; and mv $f.tmp $f
end

for n in (jq -r 'keys[]' $f)
    set repo (jq -r --arg n $n '.[$n].repo // $n' $f)
    set pn (jq -r --arg n $n '.[$n].pname // $n' $f)
    set old (jq -r --arg n $n '.[$n].version' $f)
    set cargo (jq -r --arg n $n '.[$n].cargoHash' $f)

    set new (curl -fsSL $auth https://api.github.com/repos/storytold/$repo/releases/latest | jq -r '.tag_name // empty | ltrimstr("v")')
    if test -z "$new"
        echo "skip $n: no release found" >&2
        continue
    end
    if test "$new" = "$old"; and test -n "$cargo"
        continue
    end

    echo "update $n: $old -> $new"
    set deb (nix store prefetch-file --json https://github.com/storytold/$repo/releases/download/v$new/$pn-$new-linux-x86_64.deb | jq -r .hash)
    set src (nix flake prefetch --json github:storytold/$repo/v$new | jq -r .hash)
    if test -z "$deb"; or test -z "$src"
        echo "skip $n: prefetch failed" >&2
        continue
    end

    setk $n version $new
    setk $n debHash $deb
    setk $n srcHash $src
    setk $n cargoHash ""

    set out (nix build .#$n-src --no-link 2>&1 | string collect)
    set got (string match -r 'got:\s+(sha256-\S+)' -- $out)[2]
    if test -n "$got"
        setk $n cargoHash $got
    else
        echo "no cargoHash for $n:" >&2
        echo $out | tail -5 >&2
    end
end
