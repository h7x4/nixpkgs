#! @shell@

fixupHooks=()

if [[ -n "@signingUtils@" ]]; then
    source "@signingUtils@"
fi

declare -A excludes
excludes['@storeDir@/eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee']=1
while getopts e: o; do
    case "$o" in
        e) if [[ "$OPTARG" =~ ('@storeDir@/'[a-z0-9]{32})-.* ]]; then
               excludes["${BASH_REMATCH[1]}"]=1
           else
               echo "-e argument must be a Nix store path"
               exit 1
           fi
        ;;
    esac
done
shift $((OPTIND-1))

for i in "$@"; do
    if test ! -L "$i" -a -f "$i"; then
        while IFS= read -r line; do
            lineout="$line"
            while [[ "$line" =~ ('@storeDir@/'[a-z0-9]{32})- ]]; do
                line="${line//"${BASH_REMATCH[1]}"/''}"
                if [[ ! "${excludes["${BASH_REMATCH[1]}"]+1}" ]]; then
                    lineout="${lineout//"${BASH_REMATCH[1]}"/'/nix/store/eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee'}"
                fi
            done
            printf "%s\n" "$lineout"
        done <"$i" >"$i.tmp"
        cp --attributes-only --preserve "$i" "$i.tmp"
        mv "$i.tmp" "$i"
        if [[ -n "@signingUtils@" ]]; then
            signIfRequired "$i"
        fi
    fi
done
