#!/usr/bin/env fish
set f apps.json
for n in (jq -r 'keys[]' $f)
    set repo (jq -r --arg n $n '.[$n].repo // $n' $f)
    set pn (jq -r --arg n $n '.[$n].pname // $n' $f)
    set v (jq -r --arg n $n '.[$n].version' $f)
    set d (nix store prefetch-file --json https://github.com/storytold/$repo/releases/download/v$v/$pn-$v-linux-x86_64.deb | jq -r .hash)
    set s (nix flake prefetch --json github:storytold/$repo/v$v | jq -r .hash)
    jq --arg n $n --arg d $d --arg s $s '.[$n].debHash=$d | .[$n].srcHash=$s' $f > $f.tmp; and mv $f.tmp $f
end
