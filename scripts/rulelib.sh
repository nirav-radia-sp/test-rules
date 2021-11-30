#!/bin/bash -e

prom_variants=( "dev" "internal" "prod" "saas-fed-dev" )

function ruletmp_copy () {
    # Make temporary directory to check if all rules are valid.
    ruletmp="$1"
    mkdir -p "$ruletmp"

    for v in "${prom_variants[@]}"; do
        mkdir -p "${ruletmp}"/"${v}"
        for region in $(find rules/$v -mindepth 1 -maxdepth 1 -type d -not -iname "all_regions" -exec basename {} ';')
        do
          mkdir -p "${ruletmp}"/"${v}/${region}"
          if [[ $v != saas-fed-dev ]]; then
            find ./rules/general/. \( -name "*.yml" -or -name "*.yaml" \) -exec cp {} "${ruletmp}/${v}/${region}" ';'
          fi
          find ./rules/"${v}"/all_regions/. \( -name "*.yml" -or -name "*.yaml" \) -exec cp {} "${ruletmp}/${v}/${region}" ';'
          find ./rules/"${v}"/${region}/. \( -name "*.yml" -or -name "*.yaml" \) -exec cp {} "${ruletmp}/${v}/${region}" ';'
        done
    done

    echo "$ruletmp"
}

function orphan_file_validation () {
    subdir="$1"
    valid="true"
    invalidFiles=()
    # Validate orphan rule files which are not at proper folder structure and will be ignored in deployment
    for file in $(find rules -mindepth 1 -maxdepth 1 -type f -exec basename {} ';')
    do
      invalidFiles+=("rules/$file")
      valid="false"
    done

    for v in "${prom_variants[@]}"; do
      if [[ -z "$subdir" || "$v" == "$subdir" ]]; then
        for file in $(find rules/$v -mindepth 1 -maxdepth 1 -type f -exec basename {} ';')
        do
          invalidFiles+=("rules/$v/$file")
          valid="false"
        done
      fi
    done


    if [[ "$valid" == "false" ]]; then
      echo "Below file(s) are at unexpected location. All rules should be inside 'general' OR '\$ENV/all_regions' OR '\$ENV/\$region' folder:"
      for file in "${invalidFiles[@]}"
      do
        printf "\n"
        echo "$file"
      done
    fi
}
